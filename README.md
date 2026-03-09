![Nightshift Banner](./docs/assets/banner.svg)

**Nightshift** is a git-native agentic coding loop. `next-prompt.md` committed in git is the state machine. A loop — bash or CI — reads that state, runs the agent, and checks the result. **Only a git commit advances the state.** If the agent doesn't commit, the loop halts.

---

## The Model

```
next-prompt.md (in git)
        │
        ▼
   loop reads prompt
        │
        ▼
   agent runs
        │
        ├─ makes commits (including next-prompt.md)  ← state advances
        │         │
        │         ▼
        │   loop reads new next-prompt.md
        │         │
        │         └─ repeat until DONE or max iterations
        │
        └─ makes no commit  ← loop halts (state stalled)
```

Two interchangeable runners, same protocol:

| Runner | How to use |
|--------|-----------|
| `loop.sh` | Local bash loop. Iterates on a session branch until done. |
| `nightshift.yml` | CI workflow. One iteration per push to `next-prompt.md` on main; merge the PR to trigger the next. |

---

## Quick Start

```bash
# 1. Install into current repo
curl -sSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/scripts/bootstrap.sh | bash

# 2. Write your first task
echo "Add a /healthz endpoint to src/index.ts that returns 200 OK." > next-prompt.md

# 3. Run the loop
bash .nightshift/scripts/loop.sh
```

The loop runs the agent against `next-prompt.md`, waits for a commit, reads the updated `next-prompt.md`, and repeats. Tell your agent in the system prompt (or in `next-prompt.md` itself) that it must commit `next-prompt.md` with the next task on every commit, and write `DONE` when finished.

---

## next-prompt.md

The state machine node. Every agent commit must update this file with the prompt for the next iteration — that is how the loop advances. Humans can redirect the agent at any time by editing and committing this file.

**Completion**: when the agent writes `DONE` (or leaves the file empty) into `next-prompt.md` and commits it, the loop stops.

The `pre-commit` hook enforces that `next-prompt.md` is staged on every commit. A commit without it is blocked — the agent cannot advance state silently.

---

## loop.sh

The local runner. Each agent runs in an isolated **git worktree** — your working directory is never touched. Iterates up to `--max-iter` times (default: 10).

```bash
# Serial: one agent, iterates to completion
bash .nightshift/scripts/loop.sh

# Parallel: N agents simultaneously, each on its own worktree and branch
bash .nightshift/scripts/loop.sh --parallel 3

# Full options:
bash .nightshift/scripts/loop.sh \
  --max-iter 20 \
  --parallel 3 \
  --agent "claude --print" \
  --branch ns/session/my-feature \
  --no-pr
```

**Serial mode** (`--parallel 1`, default): one agent iterates on one worktree until done. One branch, one PR.

**Parallel mode** (`--parallel N`): N agents run simultaneously on N isolated worktrees. Each gets the same starting `next-prompt.md` and works independently. Results in N branches (`<base>/agent-1`, `<base>/agent-2`, ...) and N PRs — pick the best one.

The loop (per agent) halts if:
- `next-prompt.md` is empty or `DONE` after a commit
- The agent makes no commit (state stalled)
- The agent exits non-zero
- `--max-iter` is reached

---

## CI Runner

`nightshift.yml` is structurally one iteration of what `loop.sh` does locally:

```
read next-prompt.md → run agent → verify commit was made → push → open PR
```

The loop-back is the merge: when the PR lands on `main`, the updated `next-prompt.md` triggers the next CI run. The human decides when to merge — that's the review gate.

To set it up:
1. Copy `.nightshift/templates/nightshift.yml` to `.github/workflows/nightshift.yml`
2. Add `ANTHROPIC_API_KEY` to your repository secrets

Any CI system works. The contract is simple — watch `next-prompt.md` on main, run the agent, fail if no commit was made:

```bash
HEAD_BEFORE=$(git rev-parse HEAD)
git checkout -b "ns/session/$(date +%Y%m%d-%H%M%S)"
$AGENT_CMD < next-prompt.md
[ "$(git rev-parse HEAD)" = "$HEAD_BEFORE" ] && exit 1  # stall = failure
git push -u origin HEAD
```

| | `loop.sh` | `nightshift.yml` |
|---|---|---|
| Isolation | git worktree | fresh CI checkout |
| Iteration | while loop | PR merge → re-trigger |
| Stall detection | HEAD compare | HEAD compare |
| State advance | git commit | git commit |
| Review gate | human merges PR | human merges PR |

---

## Git Hooks

Installed into `.git/hooks/`. Pure bash, no external dependencies.

| Hook | Behaviour |
|------|-----------|
| `pre-commit` | **BLOCKS** if `next-prompt.md` not staged. Warns on > 10 files changed. Auto-fixes lint where possible; appends unfixable issues to `next-prompt.md`. |
| `commit-msg` | **Warns** if `GIT_BRAIN_METADATA` missing or malformed. Set `NIGHTSHIFT_STRICT_METADATA=1` to block. |
| `pre-push` | **BLOCKS** on lint/type failures or PR > 20 files. Runs tests; appends failures to `next-prompt.md`. |

---

## GIT_BRAIN_METADATA

An optional structured block in each commit message that turns git history into a reasoning ledger — future agents (and humans) can reconstruct not just what changed, but why and how to reproduce it.

```
feat(auth): implement jwt validation middleware

<!--
GIT_BRAIN_METADATA:
{
  "retroactive_prompt": "Add JWT validation middleware in src/middleware/auth.ts ...",
  "outcome": "Protected routes return 401 for missing/expired tokens.",
  "context": "Server uses Bun's native HTTP with a thin router in src/router.ts.",
  "agent": "claude-sonnet-4-6",
  "session": "sess_20260307_auth",
  "hints": ["Read from ctx.request.headers.get('authorization'), not req.headers"]
}
-->
```

Required fields: `retroactive_prompt` (≥ 50 chars), `outcome`, `context`, `agent`, `session`.

Warned on by default. To enforce as a hard block: `export NIGHTSHIFT_STRICT_METADATA=1`.

---

## Branch Naming

Session branches: `ns/session/<timestamp>`. Parallel explorations: `ns/session/<name>/option-a`, `ns/session/<name>/option-b`.

---

## License

MIT
