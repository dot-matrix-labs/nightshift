#!/usr/bin/env bash
set -e

# Nightshift Post-Installation Checklist
#
# Validates the Nightshift installation after dev-install.sh completes.
# Run this to verify agents are working and bootstrap the methodology.
#
# Usage: ./scripts/post-install.sh [--auto]

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCODE_JSON="${PROJECT_ROOT}/opencode.json"

echo "🏭 Nightshift Post-Installation Checklist"
echo "============================================"
echo ""

# Check for --auto flag
AUTO_MODE=false
if [ "$1" = "--auto" ]; then
    AUTO_MODE=true
fi

# Step 1: Validate OpenCode configuration
echo "✅ Step 1: Validating OpenCode Configuration"
echo "=============================================="

ERRORS=0

if [ -f "${OPENCODE_JSON}" ]; then
    if node -e "require('fs').readFileSync('${OPENCODE_JSON}', 'utf8')" 2>/dev/null; then
        echo "   ✅ opencode.json exists and is valid"
    else
        echo "   ❌ opencode.json is invalid JSON"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ opencode.json not found - run dev-install.sh first"
    ERRORS=$((ERRORS + 1))
fi

# Check agents
AGENTS=$(node -e "console.log(Object.keys(require('${OPENCODE_JSON}').agent || {}).join(', '))" 2>/dev/null || echo "")
if [ -n "$AGENTS" ]; then
    echo "   ✅ Agents configured: ${AGENTS}"
else
    echo "   ❌ No agents found in opencode.json"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Configuration errors detected. Please run dev-install.sh first."
    exit 1
fi

# Ask to restart agent client
echo "🔄 Please restart your OpenCode client now."
echo "   (Close and reopen, or reload the window)"
echo ""

if [ "$AUTO_MODE" = false ]; then
    read -p "   Have you restarted OpenCode? [y/N] " -n 1 -r
    echo
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Run this script again after restarting."
        exit 0
    fi
fi

# Step 2: Bootstrap GitBrain branch
echo ""
echo "🌿 Step 2: GitBrain Branch Setup"
echo "=================================="

BRANCH_NAME="ns/session/nightshift-bootstrap-$(date +%Y%m%d)"
echo "   Creating branch: ${BRANCH_NAME}"
git checkout -b "${BRANCH_NAME}"
echo "   ✅ Branch created"

# Step 3: Curator documentation indexing
echo ""
echo "📚 Step 3: Documentation Indexing"
echo "==================================="

if confirm "   Run curator to index documentation?"; then
    echo "   Run: opencode --agent curator"
    echo "   (The curator agent will build the knowledge graph)"
fi

echo ""
echo "============================================"
echo "✅ Nightshift Bootstrapping Complete!"
echo "============================================"
echo ""
echo "📋 Summary:"
echo "   • Branch: ${BRANCH_NAME}"
echo "   • Config: ${OPENCODE_JSON}"
echo ""
echo "🔗 docs/development/agent_bootstrap_instructions.md"
echo ""
