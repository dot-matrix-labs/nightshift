#!/usr/bin/env bash
# bootstrap.sh — Install Nightshift into a target repository.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/scripts/bootstrap.sh | bash
#
# Or clone nightshift and run locally:
#   bash /path/to/nightshift/scripts/bootstrap.sh
#
# What this does:
#   1. Installs git hooks (pre-commit, commit-msg, post-commit, pre-push)
#   2. Installs the metadata validator script
#   3. Installs the GitHub Actions nightshift workflow
#   4. Creates next-prompt.md if it doesn't exist
#   5. Installs the worktree-agent script

set -euo pipefail

NIGHTSHIFT_REPO="https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Allow running from a local clone
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_ROOT="$(dirname "$SCRIPT_DIR")"

fetch() {
  local path="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$LOCAL_ROOT/$path" ]; then
    cp "$LOCAL_ROOT/$path" "$dest"
  else
    curl -sSL "$NIGHTSHIFT_REPO/$path" -o "$dest"
  fi
  echo "  ✓ $dest"
}

cd "$REPO_ROOT"

echo ""
echo "Installing Nightshift into $(pwd)"
echo ""

# ── Git hooks ─────────────────────────────────────────────────────────────────

echo "→ Installing git hooks..."
mkdir -p .git/hooks

for hook in pre-commit commit-msg post-commit pre-push; do
  fetch "hooks/$hook" ".git/hooks/$hook"
  chmod +x ".git/hooks/$hook"
done

# ── Validator script ──────────────────────────────────────────────────────────

echo "→ Installing validator..."
mkdir -p .nightshift/scripts
fetch "scripts/validate-metadata.mjs" ".nightshift/scripts/validate-metadata.mjs"

# ── Worktree agent script ─────────────────────────────────────────────────────

echo "→ Installing worktree-agent..."
mkdir -p .nightshift/scripts
fetch "scripts/worktree-agent.sh" ".nightshift/scripts/worktree-agent.sh"
chmod +x ".nightshift/scripts/worktree-agent.sh"

# ── GitHub Actions workflow ───────────────────────────────────────────────────

echo "→ Installing GitHub Actions workflow..."
fetch ".github/workflows/nightshift.yml" ".github/workflows/nightshift.yml"

# ── next-prompt.md ────────────────────────────────────────────────────────────

if [ ! -f "next-prompt.md" ]; then
  echo "→ Creating next-prompt.md..."
  cat > next-prompt.md <<'EOF'
# Next Prompt

Replace this file with a self-contained prompt describing the very next action
the agent should take. This file is the trigger for the Nightshift runtime:
committing a change to this file on `main` will cause GitHub Actions to spin up
an agent, execute the prompt, commit the result on a new branch, and open a PR.

Every agent commit must also update this file with the prompt for the next task,
creating a self-advancing loop.

## Format

Write in second person, addressed to the agent picking up the next task:

- What was just completed (context)
- What to do next (the actual task)
- Any constraints, gotchas, or files to read first

## Example

Read `src/auth/jwt.ts`. Add a `refreshToken` endpoint at `POST /auth/refresh`
that accepts a valid refresh token (stored in an HTTP-only cookie), validates it
against the `refresh_tokens` table, and returns a new access JWT. The access
token TTL is 15 minutes. See `src/auth/login.ts` for the existing pattern.
EOF
  echo "  ✓ next-prompt.md"
fi

echo ""
echo "Nightshift installed successfully."
echo ""
echo "Next steps:"
echo "  1. Edit next-prompt.md with your first task"
echo "  2. Commit it to main — GitHub Actions will take it from there"
echo "  3. Or run locally: bash .nightshift/scripts/worktree-agent.sh"
echo ""
