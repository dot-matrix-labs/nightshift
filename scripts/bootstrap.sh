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
#   1. Installs git hooks (pre-commit, commit-msg, pre-push) — pure bash, no dependencies
#   2. Installs loop.sh for local agent sessions
#   3. Installs nightshift.yml CI workflow template
#   4. Creates next-prompt.md if it doesn't exist

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
mkdir -p .nightshift/hooks

for hook in pre-commit commit-msg pre-push; do
  fetch "hooks/$hook" ".nightshift/hooks/$hook"
  chmod +x ".nightshift/hooks/$hook"
done

# Configure git to use .nightshift/hooks instead of .git/hooks
git config core.hooksPath .nightshift/hooks

# ── Loop script ───────────────────────────────────────────────────────────────

echo "→ Installing loop.sh..."
mkdir -p .nightshift/scripts
fetch "scripts/loop.sh" ".nightshift/scripts/loop.sh"
chmod +x ".nightshift/scripts/loop.sh"

# ── CI workflow template ──────────────────────────────────────────────────────

echo "→ Installing CI workflow template..."
fetch "templates/nightshift.yml" ".nightshift/templates/nightshift.yml"

# ── GitHub Actions setup ──────────────────────────────────────────────────────

USE_GITHUB_ACTIONS=""
if [ -d ".git" ]; then
  echo ""
  echo "Do you want to set up GitHub Actions for automated CI iterations? [y/N]"
  read -r USE_GITHUB_ACTIONS
fi

if [ "$USE_GITHUB_ACTIONS" = "y" ] || [ "$USE_GITHUB_ACTIONS" = "Y" ]; then
  echo "→ Setting up GitHub Actions workflow..."
  mkdir -p .github/workflows
  fetch "templates/nightshift.yml" ".github/workflows/nightshift.yml"
  echo ""
  echo "  ✓ GitHub Actions workflow installed"
  echo "  IMPORTANT: Add ANTHROPIC_API_KEY to your repo secrets (Settings → Secrets → Actions)"
fi

# ── next-prompt.md ────────────────────────────────────────────────────────────

if [ ! -f ".nightshift/next-prompt.md" ]; then
  echo "→ Creating .nightshift/next-prompt.md..."
  cat > .nightshift/next-prompt.md <<'EOF'
# Next Prompt

Replace this file with a self-contained prompt describing the very next action
the agent should take. This file is the trigger for the Nightshift runtime:
committing a change to this file starts a new agent session — locally via
loop.sh, or automatically via your CI system.

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
  echo "  ✓ .nightshift/next-prompt.md"
fi

echo ""
echo "Nightshift installed successfully."
echo ""
echo "Next steps:"
echo "  1. Edit .nightshift/next-prompt.md with your first task"
echo "  2. Run locally:  bash .nightshift/scripts/loop.sh"
if [ "$USE_GITHUB_ACTIONS" = "y" ] || [ "$USE_GITHUB_ACTIONS" = "Y" ]; then
  echo "  3. Add ANTHROPIC_API_KEY to repo secrets (Settings → Secrets → Actions)"
else
  echo "  3. Wire up CI: copy .nightshift/templates/nightshift.yml to .github/workflows/"
  echo "                  and add ANTHROPIC_API_KEY to your repo secrets"
fi
echo ""
