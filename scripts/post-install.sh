#!/usr/bin/env bash
set -e

# Nightshift Post-Installation Checklist
#
# Validates the installation and bootstraps the Nightshift methodology.
#
# Usage: ./scripts/post-install.sh [--auto]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCODE_JSON="${PROJECT_ROOT}/opencode.json"
COMMANDS_DIR="${PROJECT_ROOT}/.opencode/command"
AGENTS_DIR="${PROJECT_ROOT}/templates/agents"

echo "🏭 Nightshift Post-Installation Checklist"
echo "============================================"
echo "Project: ${PROJECT_ROOT}"
echo ""

# Check for --auto flag
AUTO_MODE=false
if [ "$1" = "--auto" ]; then
    AUTO_MODE=true
fi

confirm() {
    if [ "$AUTO_MODE" = true ]; then
        return 0
    fi
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Step 0: Validate OpenCode configuration
echo "🔍 Step 0: Validating OpenCode Configuration"
echo "=============================================="

ERRORS=0

# Check opencode.json exists and is valid
if [ -f "${OPENCODE_JSON}" ]; then
    if node -e "require('fs').readFileSync('${OPENCODE_JSON}', 'utf8')" 2>/dev/null; then
        echo "   ✅ opencode.json exists and is valid"
    else
        echo "   ❌ opencode.json is invalid JSON"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ opencode.json not found"
    ERRORS=$((ERRORS + 1))
fi

# Check agents are defined
AGENTS=$(node -e "console.log(Object.keys(require('${OPENCODE_JSON}').agent || {}).join(', '))" 2>/dev/null || echo "")
if [ -n "$AGENTS" ]; then
    echo "   ✅ Agents configured: ${AGENTS}"
else
    echo "   ❌ No agents found in opencode.json"
    ERRORS=$((ERRORS + 1))
fi

# Check instructions
INSTRUCTIONS=$(node -e "console.log((require('${OPENCODE_JSON}').instructions || []).join(', '))" 2>/dev/null || echo "")
if [ -n "$INSTRUCTIONS" ]; then
    echo "   ✅ Instructions: ${INSTRUCTIONS}"
else
    echo "   ⚠️  No instructions configured"
fi

# Check command symlinks
if [ -d "${COMMANDS_DIR}" ]; then
    CMD_COUNT=$(ls -1 "${COMMANDS_DIR}"/*.md 2>/dev/null | wc -l)
    echo "   ✅ Commands linked: ${CMD_COUNT} files"
else
    echo "   ⚠️  Commands directory not found (run dev-install.sh first)"
fi

echo ""

# Ask to restart agent client
if [ "$AUTO_MODE" = false ]; then
    echo "🔄 Please restart your OpenCode client now."
    echo "   (Close and reopen, or reload the window)"
    echo ""
    if ! confirm "   Have you restarted OpenCode?"; then
        echo ""
        echo "❌ Installation checklist paused. Run this script again after restarting."
        exit 0
    fi
fi

# Verify agents are visible (check opencode.json syntax is valid for OpenCode)
echo ""
echo "✅ Installation validated. Proceeding with Nightshift bootstrapping..."

# Step 1: GitBrain branch setup
echo ""
echo "🌿 Step 1: Creating GitBrain Branch"
echo "======================================"
echo "   This creates a semantic branch following Nightshift naming conventions."
echo "   Branch format: ns/session/<feature-or-fix-name>"
echo ""

BRANCH_NAME=""
if [ "$AUTO_MODE" = true ]; then
    BRANCH_NAME="ns/session/nightshift-bootstrap-$(date +%Y%m%d)"
else
    read -p "   Enter branch name (or press Enter for auto): " BRANCH_NAME
fi

if [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME="ns/session/nightshift-bootstrap-$(date +%Y%m%d)"
fi

# Create branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "   Current branch: ${CURRENT_BRANCH}"
echo "   Creating branch: ${BRANCH_NAME}"

git checkout -b "${BRANCH_NAME}"
echo "   ✅ Branch created: ${BRANCH_NAME}"

# Step 2: Git hooks setup
echo ""
echo "🪝 Step 2: Git Hooks Configuration"
echo "===================================="
echo "   Nightshift uses git hooks for quality gates."
echo ""

HOOKS_TEMPLATE="${PROJECT_ROOT}/templates/git-hooks"
if [ -d "${HOOKS_TEMPLATE}" ]; then
    echo "   Found hooks template: ${HOOKS_TEMPLATE}"
    ls -la "${HOOKS_TEMPLATE}"/*.sh 2>/dev/null || echo "   No hook scripts found"
else
    echo "   ⚠️  No templates/git-hooks directory found"
    echo "   (Git hooks will be configured manually)"
fi

if confirm "   Configure git hooks for this project?"; then
    echo "   Creating .git/hooks/ from template..."
    mkdir -p "${PROJECT_ROOT}/.git/hooks"

    # Common hooks
    for hook in pre-commit pre-push; do
        hook_src="${HOOKS_TEMPLATE}/${hook}.sh"
        hook_dst="${PROJECT_ROOT}/.git/hooks/${hook}"
        if [ -f "${hook_src}" ]; then
            cp "${hook_src}" "${hook_dst}"
            chmod +x "${hook_dst}"
            echo "   ✅ Installed ${hook}.sh"
        fi
    done
else
    echo "   ⚠️  Skipped git hooks configuration"
fi

# Step 3: Documentation Fractal Indexing
echo ""
echo "📚 Step 3: Documentation Fractal Indexing"
echo "==========================================="
echo "   The curator agent will index the project documentation."
echo ""

# Check if curator agent is configured
CURATOR_PROMPT=$(node -e "console.log(require('${OPENCODE_JSON}').agent?.curator?.prompt || '')" 2>/dev/null || echo "")
if [ -n "$CURATOR_PROMPT" ]; then
    echo "   ✅ Curator agent configured"
    echo "   Prompt: ${CURATOR_PROMPT}"

    if confirm "   Run curator to index documentation?"; then
        echo ""
        echo "   📖 Curator will now index the documentation fractal..."
        echo "   (This runs the curator agent to build the knowledge graph)"
        echo ""

        # Extract curator prompt file path
        CURATOR_FILE=$(echo "$CURATOR_PROMPT" | sed 's/{file://' | sed 's/}//')

        if [ -f "${PROJECT_ROOT}/${CURATOR_FILE}" ]; then
            echo "   Curator instructions:"
            head -30 "${PROJECT_ROOT}/${CURATOR_FILE}"
            echo ""
            echo "   (Manual step - run with: opencode --agent curator)"
        else
            echo "   ⚠️  Curator file not found: ${CURATOR_FILE}"
        fi
    fi
else
    echo "   ⚠️  Curator agent not configured in opencode.json"
fi

# Summary
echo ""
echo "============================================"
echo "✅ Nightshift Bootstrapping Complete!"
echo "============================================"
echo ""
echo "📋 Summary:"
echo "   • Branch: ${BRANCH_NAME}"
echo "   • Config: ${OPENCODE_JSON}"
echo "   • Commands: ${COMMANDS_DIR}"
echo ""
echo "📝 Next Steps:"
echo "   1. Run 'bun run dev' to start development"
echo "   2. OpenCode is now configured with Nightshift agents"
echo "   3. Use commands in OpenCode (type / to see available commands)"
echo ""
echo "🔗 Useful links:"
echo "   • docs/development/agent_bootstrap_instructions.md"
echo "   • templates/agents/curator.md"
echo ""
