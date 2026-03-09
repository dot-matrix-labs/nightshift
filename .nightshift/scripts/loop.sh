#!/usr/bin/env bash
# loop.sh — The Nightshift local loop.
#
# Runs one or more agents against next-prompt.md using git worktrees for
# isolation. Each agent gets its own worktree and session branch, leaving
# your working directory untouched.
#
# Usage:
#   bash .nightshift/scripts/loop.sh [options]
#
# Options:
#   --max-iter N     Max iterations per agent before giving up (default: 10)
#   --agent <cmd>    Agent command (default: $NIGHTSHIFT_AGENT_CMD or "claude --print")
#   --branch <name>  Base branch name (default: ns/session/<timestamp>)
#   --parallel N     Run N agents simultaneously, each in its own worktree (default: 1)
#   --no-pr          Skip opening PRs when done
#
# Serial mode (--parallel 1, default):
#   One agent iterates on a single worktree until next-prompt.md signals DONE,
#   the agent stalls, or max-iter is reached.
#
# Parallel mode (--parallel N):
#   N agents run simultaneously in N isolated worktrees. Each gets the same
#   starting next-prompt.md and works independently to completion. Results in
#   N branches and N PRs — pick the best one.
#   Branch naming: <base>/agent-1, <base>/agent-2, ...
#
# Completion (per agent):
#   - next-prompt.md is empty or "DONE" after a commit
#   - agent makes no commit (state stalled)
#   - max-iter reached
#   - agent exits non-zero

set -uo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────

REPO_ROOT=$(git rev-parse --show-toplevel)
MAX_ITER=10
AGENT_CMD="${NIGHTSHIFT_AGENT_CMD:-claude --print}"
BASE_BRANCH="ns/session/$(date +%Y%m%d-%H%M%S)"
PARALLEL=1
OPEN_PR=1
WORKTREE_BASE="$REPO_ROOT/../.nightshift-worktrees"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-iter)  MAX_ITER="$2";    shift 2 ;;
    --agent)     AGENT_CMD="$2";   shift 2 ;;
    --branch)    BASE_BRANCH="$2"; shift 2 ;;
    --parallel)  PARALLEL="$2";    shift 2 ;;
    --no-pr)     OPEN_PR=0;        shift   ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

PROMPT_FILE="$REPO_ROOT/.nightshift/next-prompt.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: .nightshift/next-prompt.md not found at $REPO_ROOT" >&2
  exit 1
fi

if [ -z "$(cat "$PROMPT_FILE" | tr -d '[:space:]')" ]; then
  echo "Error: .nightshift/next-prompt.md is empty. Write a task first." >&2
  exit 1
fi

mkdir -p "$WORKTREE_BASE"

# ── Worktree helpers ──────────────────────────────────────────────────────────

make_worktree() {
  local branch="$1"
  local path="$WORKTREE_BASE/$(echo "$branch" | tr '/' '-')"
  git -C "$REPO_ROOT" worktree add "$path" -b "$branch" 2>/dev/null || {
    echo "Error: could not create worktree for branch '$branch'. Does it already exist?" >&2
    return 1
  }
  echo "$path"
}

remove_worktree() {
  local path="$1"
  git -C "$REPO_ROOT" worktree remove "$path" --force 2>/dev/null || true
}

open_pr() {
  local branch="$1"
  local prompt_file="$2"
  local iter="$3"

  if [ $OPEN_PR -eq 1 ] && command -v gh &>/dev/null; then
    local title
    title=$(grep -m1 "^[^#[:space:]]" "$prompt_file" 2>/dev/null | cut -c1-72 || echo "Nightshift: $branch")
    gh pr create \
      --title "$title" \
      --body "Nightshift agent session — $iter iteration(s) on \`$branch\`." \
      --base main \
      --head "$branch" 2>/dev/null \
      && echo "PR opened for $branch" \
      || echo "Could not open PR. Run: gh pr create --base main --head $branch"
  else
    echo "Branch ready: $branch"
    echo "Open a PR:    gh pr create --base main --head $branch"
  fi
}

# ── Single agent loop (runs inside a worktree) ────────────────────────────────

run_loop() {
  local branch="$1"
  local worktree="$2"
  local label="${3:-}"
  local prompt_file="$worktree/next-prompt.md"
  local iter=0
  local done=0

  [ -n "$label" ] && PREFIX="[$label] " || PREFIX=""

  echo "${PREFIX}Starting on branch: $branch"
  echo "${PREFIX}Worktree: $worktree"

  while [ $iter -lt $MAX_ITER ]; do
    iter=$((iter + 1))
    echo "${PREFIX}── Iteration $iter / $MAX_ITER"

    local prompt
    prompt=$(cat "$prompt_file" 2>/dev/null || echo "")

    if [ -z "$prompt" ] || [ "$prompt" = "DONE" ]; then
      echo "${PREFIX}Completion signal. Done after $iter iteration(s)."
      done=1
      break
    fi

    local head_before
    head_before=$(git -C "$worktree" rev-parse HEAD)

    # Run agent inside the worktree
    (cd "$worktree" && $AGENT_CMD < "$prompt_file") || {
      echo "${PREFIX}Agent exited non-zero on iteration $iter. Halting." >&2
      break
    }

    local head_after
    head_after=$(git -C "$worktree" rev-parse HEAD)

    if [ "$head_before" = "$head_after" ]; then
      echo "${PREFIX}WARNING: no commit made on iteration $iter. State did not advance. Halting." >&2
      break
    fi

    local new_prompt
    new_prompt=$(cat "$prompt_file" 2>/dev/null || echo "")
    if [ -z "$new_prompt" ] || [ "$new_prompt" = "DONE" ]; then
      echo "${PREFIX}Completion signal after iteration $iter. Done."
      done=1
      break
    fi

    echo "${PREFIX}State advanced. Continuing..."
  done

  if [ $iter -ge $MAX_ITER ] && [ $done -eq 0 ]; then
    echo "${PREFIX}Max iterations ($MAX_ITER) reached." >&2
  fi

  # Push if there are commits
  local commits
  commits=$(git -C "$worktree" log --oneline "main..$branch" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$commits" -gt 0 ]; then
    git -C "$worktree" push -u origin "$branch"
    open_pr "$branch" "$prompt_file" "$iter"
  else
    echo "${PREFIX}No commits. Nothing to push."
  fi
}

# ── Serial mode ───────────────────────────────────────────────────────────────

if [ "$PARALLEL" -eq 1 ]; then
  echo ""
  echo "Nightshift"
  echo "  branch:   $BASE_BRANCH"
  echo "  agent:    $AGENT_CMD"
  echo "  max iter: $MAX_ITER"
  echo ""

  WORKTREE=$(make_worktree "$BASE_BRANCH") || exit 1
  cp "$PROMPT_FILE" "$WORKTREE/next-prompt.md"

  run_loop "$BASE_BRANCH" "$WORKTREE"

  remove_worktree "$WORKTREE"
  echo ""
  echo "Done."

# ── Parallel mode ─────────────────────────────────────────────────────────────

else
  echo ""
  echo "Nightshift (parallel x$PARALLEL)"
  echo "  base branch: $BASE_BRANCH"
  echo "  agent:       $AGENT_CMD"
  echo "  max iter:    $MAX_ITER"
  echo ""

  PIDS=()
  BRANCHES=()
  WORKTREES=()

  for i in $(seq 1 "$PARALLEL"); do
    BRANCH="$BASE_BRANCH/agent-$i"
    WORKTREE=$(make_worktree "$BRANCH") || continue
    cp "$PROMPT_FILE" "$WORKTREE/next-prompt.md"

    BRANCHES+=("$BRANCH")
    WORKTREES+=("$WORKTREE")

    # Run each agent loop in a background subshell, output prefixed with agent index
    run_loop "$BRANCH" "$WORKTREE" "agent-$i" 2>&1 | sed "s/^/[agent-$i] /" &
    PIDS+=($!)
  done

  # Wait for all agents to finish
  for pid in "${PIDS[@]}"; do
    wait "$pid" || true
  done

  # Clean up all worktrees
  for worktree in "${WORKTREES[@]}"; do
    remove_worktree "$worktree"
  done

  echo ""
  echo "All $PARALLEL agents done."
  echo "Branches: ${BRANCHES[*]}"
fi
