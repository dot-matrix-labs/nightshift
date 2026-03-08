#!/usr/bin/env bash
# worktree-agent.sh — Run an agent in a fresh git worktree.
#
# Usage:
#   bash worktree-agent.sh [--prompt <file>] [--branch <name>] [--agent <cmd>]
#
# Options:
#   --prompt  Path to prompt file (default: next-prompt.md in repo root)
#   --branch  Branch name for the worktree (default: ns/session/<timestamp>)
#   --agent   Agent command to run (default: claude --print)
#
# What this does:
#   1. Creates a git worktree on a new branch
#   2. Copies the prompt file into the worktree
#   3. Runs the agent with the prompt piped to stdin
#   4. The agent commits its work to the worktree branch
#   5. Pushes the branch and opens a PR
#   6. Cleans up the worktree

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
PROMPT_FILE="$REPO_ROOT/next-prompt.md"
BRANCH="ns/session/$(date +%Y%m%d-%H%M%S)"
AGENT_CMD="claude --print"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT_FILE="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --agent)  AGENT_CMD="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

WORKTREE_PATH="$REPO_ROOT/../.nightshift-worktrees/$BRANCH"
mkdir -p "$(dirname "$WORKTREE_PATH")"

echo ""
echo "Nightshift: spinning up agent"
echo "  branch:   $BRANCH"
echo "  prompt:   $PROMPT_FILE"
echo "  agent:    $AGENT_CMD"
echo "  worktree: $WORKTREE_PATH"
echo ""

# Create worktree
git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" -b "$BRANCH"

# Copy prompt into worktree root so the agent can reference it
cp "$PROMPT_FILE" "$WORKTREE_PATH/next-prompt.md"

# Run agent inside the worktree with the prompt on stdin
cd "$WORKTREE_PATH"
$AGENT_CMD < "$PROMPT_FILE"
AGENT_EXIT=$?

if [ $AGENT_EXIT -ne 0 ]; then
  echo "" >&2
  echo "Agent exited with code $AGENT_EXIT. Worktree preserved at:" >&2
  echo "  $WORKTREE_PATH" >&2
  echo "" >&2
  exit $AGENT_EXIT
fi

# Push and open PR
PROMPT_SUMMARY=$(head -3 "$PROMPT_FILE" | tail -1 | cut -c1-72)
git push -u origin "$BRANCH"
gh pr create \
  --title "$PROMPT_SUMMARY" \
  --body "Automated PR from Nightshift agent session.

**Branch:** \`$BRANCH\`
**Prompt file:** \`$(basename "$PROMPT_FILE")\`

---

$(cat "$PROMPT_FILE")" \
  --base main

echo ""
echo "PR opened. Cleaning up worktree..."

# Cleanup
git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH" --force
echo "Done."
