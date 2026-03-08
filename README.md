![Nightshift Banner](./docs/assets/banner.svg)

**Nightshift** is a git-native runtime for autonomous AI agents. A commit to `next-prompt.md` on `main` is the invocation. GitHub Actions is the scheduler. Git hooks are the quality gates. Bash is the glue.

---

## The Model

```
next-prompt.md on main
        │
        ▼
  GitHub Actions
  (nightshift.yml)
        │
        ├─ creates branch: ns/session/<timestamp>
        ├─ runs agent with prompt on stdin
        ├─ agent commits work (hooks enforce quality)
        ├─ opens PR
        └─ on merge → cycle repeats
```

There is no daemon. There is no server. The runtime is GitHub Actions. The state is git. The invocation is a commit.

---

## Quick Start

Give this prompt to your agent:

```
Bootstrap Nightshift in this repository:

  curl -sSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/scripts/bootstrap.sh | bash

Then:
1. Add ANTHROPIC_API_KEY to your repository secrets.
2. Edit next-prompt.md with your first task.
3. Commit and push to main.
```

Or run the bootstrap directly:

```bash
curl -sSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/scripts/bootstrap.sh | bash
```

---

## What Gets Installed

```
.git/hooks/
  pre-commit          # next-prompt.md gate + lint auto-fix
  commit-msg          # GIT_BRAIN_METADATA enforcement
  post-commit         # PR-due advisory at 10 files
  pre-push            # lint/type block + PR size gate (20 files) + test annotation

.nightshift/scripts/
  validate-metadata.mjs   # commit-msg schema validator
  worktree-agent.sh       # run agent locally in a fresh worktree

.github/workflows/
  nightshift.yml          # the runtime

next-prompt.md            # the invocation point
```

---

## Git Hooks

Every hook is a standalone bash script with no dependencies beyond `git` and optionally `node`/`bun` for projects that use them.

| Hook | Stage | Behaviour |
|---|---|---|
| `pre-commit` | Before commit | **BLOCKS** if `next-prompt.md` not staged. Warns on > 10 files. Auto-fixes lint; appends unfixable issues to `next-prompt.md`. |
| `commit-msg` | After message written | **BLOCKS** if `GIT_BRAIN_METADATA` missing, malformed, or incomplete. |
| `post-commit` | After commit | **Warns** when branch has ≥ 10 files changed vs. main. Appends PR-due notice to `next-prompt.md`. |
| `pre-push` | Before push | **BLOCKS** on lint/type failures or PR > 20 files. Runs tests; appends failures to `next-prompt.md` but does not block push. |

### GIT_BRAIN_METADATA

Every agent commit embeds a structured reasoning block in the commit message. This turns git history into a **reasoning ledger** — future agents can reconstruct not just what changed, but why, and how to reproduce it.

```
feat(auth): implement jwt validation middleware

Adds middleware to verify JWT tokens on all protected routes.

<!--
GIT_BRAIN_METADATA:
{
  "retroactive_prompt": "Add JWT validation middleware in src/middleware/auth.ts. Read the token from Authorization: Bearer, verify with HS256 using JWT_SECRET env var, attach decoded payload to ctx.state.user, return 401 JSON for missing or expired tokens. Wire into router.ts before all /api routes.",
  "outcome": "Protected routes return 401 with {error: 'unauthorized'} for missing/expired tokens. Valid tokens set ctx.state.user.",
  "context": "Server uses Bun's native HTTP with a thin router in src/router.ts. Auth state flows via ctx.state. JWT_SECRET is in .env.",
  "agent": "claude-sonnet-4-6",
  "session": "sess_20260307_auth",
  "hints": [
    "Read from ctx.request.headers.get('authorization'), not req.headers",
    "Handle TokenExpiredError and JsonWebTokenError as distinct 401 cases"
  ]
}
-->
```

Required fields: `retroactive_prompt` (≥ 50 chars), `outcome`, `context`, `agent`, `session`.

---

## next-prompt.md

This file is the single source of truth for what the agent does next. It drives two things:

1. **GitHub Actions trigger** — pushing a change to this file on `main` starts a new agent session.
2. **Session continuity** — every agent commit overwrites this file with the prompt for the next commit, creating a self-advancing loop.

The pre-commit hook enforces that `next-prompt.md` is staged at every commit. A commit is the unit of progress; the agent session spans many commits.

Humans can override the next task at any time by editing `next-prompt.md` directly and pushing to main.

---

## Running Locally

To run an agent session in a local worktree without GitHub Actions:

```bash
bash .nightshift/scripts/worktree-agent.sh
# with options:
bash .nightshift/scripts/worktree-agent.sh --prompt next-prompt.md --branch ns/session/my-task --agent "claude --print"
```

---

## Repository Variables

Set these in your GitHub repository settings (Settings → Variables):

| Variable | Default | Description |
|---|---|---|
| `NIGHTSHIFT_AUTO_ADVANCE` | `false` | Poll for PR merge and log completion |
| `NIGHTSHIFT_AGENT_CMD` | `claude --print` | Override the agent command |

Required secret: `ANTHROPIC_API_KEY`.

---

## Branch Naming

Nightshift branches follow the pattern `ns/session/<timestamp>`. For human-initiated branches with multiple options, use `ns/session/<name>/option-a`, `ns/session/<name>/option-b` to show lineage and intent.

---

## License

MIT
