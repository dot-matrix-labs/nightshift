#!/bin/bash
#
# Test Nightshift Installation
# Run this from within a test project to verify the installation works
#

set -e

echo "🧪 Testing Nightshift Installation..."
echo ""

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository."
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT"

echo "📁 Project: $PROJECT_ROOT"

# Check .nightshift directory
echo ""
echo "🔍 Checking .nightshift directory..."
if [ ! -d ".nightshift" ]; then
    echo "❌ .nightshift directory not found"
    exit 1
fi

if [ -d ".nightshift/.git" ]; then
    echo "❌ .nightshift/.git exists - should be clean"
    exit 1
fi

echo "✅ .nightshift/ exists and is clean (no .git)"

# Check required files
REQUIRED_FILES=(
    ".nightshift/AGENTS.md"
    ".nightshift/agents/engineer.md"
    ".nightshift/agents/planner.md"
    ".nightshift/commands/git-brain-commit.md"
    ".nightshift/commands/update-nag-status.md"
    ".nightshift/commands/new-module-development.md"
    ".nightshift/nags/javascript-nag.md"
    ".nightshift/hooks/pre-commit"
    ".nightshift/hooks/commit-msg"
    ".nightshift/state/nag-status.json"
    ".nightshift/state/forward-prompt.md"
    "docs/documentation-rules.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        exit 1
    fi
done

echo "✅ All required .nightshift files present"

# Check git hooks
echo ""
echo "🔍 Checking git hooks..."
if [ ! -f ".git/hooks/pre-commit" ]; then
    echo "❌ .git/hooks/pre-commit not found"
    exit 1
fi

if [ ! -f ".git/hooks/commit-msg" ]; then
    echo "❌ .git/hooks/commit-msg not found"
    exit 1
fi

if [ ! -x ".git/hooks/pre-commit" ]; then
    echo "❌ .git/hooks/pre-commit not executable"
    exit 1
fi

if [ ! -x ".git/hooks/commit-msg" ]; then
    echo "❌ .git/hooks/commit-msg not executable"
    exit 1
fi

echo "✅ Git hooks installed and executable"

# Check which vendor shim exists
echo ""
echo "🔍 Checking vendor shim..."
VENDOR_FOUND=""

if [ -f "opencode.json" ]; then
    VENDOR_FOUND="OpenCode"
    echo "✅ opencode.json found"
elif [ -f ".claude/CLAUDE.md" ]; then
    VENDOR_FOUND="Claude Code"
    echo "✅ .claude/CLAUDE.md found"
elif [ -f ".cursorrules" ]; then
    VENDOR_FOUND="Cursor"
    echo "✅ .cursorrules found"
elif [ -f "GEMINI.md" ]; then
    VENDOR_FOUND="Gemini CLI"
    echo "✅ GEMINI.md found"
elif [ -f "AGENTS.md" ]; then
    VENDOR_FOUND="Codex CLI"
    echo "✅ AGENTS.md found"
else
    echo "❌ No vendor shim found"
    exit 1
fi

# Validate JSON for OpenCode
if [ "$VENDOR_FOUND" = "OpenCode" ]; then
    echo ""
    echo "🔍 Validating opencode.json JSON..."
    if command -v jq &> /dev/null; then
        if jq . opencode.json > /dev/null 2>&1; then
            echo "✅ opencode.json is valid JSON"
        else
            echo "❌ opencode.json is invalid JSON"
            echo "Contents:"
            cat opencode.json
            exit 1
        fi
    else
        echo "⚠️ jq not found - skipping JSON validation"
    fi
fi

# Test nag status file
echo ""
echo "🔍 Testing nag status..."
if [ -f ".nightshift/state/nag-status.json" ]; then
    if jq . .nightshift/state/nag-status.json > /dev/null 2>&1; then
        echo "✅ .nightshift/state/nag-status.json is valid JSON"
    else
        echo "❌ .nightshift/state/nag-status.json is invalid JSON"
        exit 1
    fi
else
    echo "❌ .nightshift/state/nag-status.json not found"
    exit 1
fi

# Test forward prompt file
if [ -f ".nightshift/state/forward-prompt.md" ]; then
    echo "✅ .nightshift/state/forward-prompt.md exists"
else
    echo "❌ .nightshift/state/forward-prompt.md not found"
    exit 1
fi

# Test git hook functionality (dry run)
echo ""
echo "🔍 Testing git hooks (dry run)..."

# Create a test file
echo "test" > test-commit.txt
git add test-commit.txt

# Test pre-commit hook (should allow since no nags set)
if git commit --dry-run -m "test: test commit" > /dev/null 2>&1; then
    echo "✅ Pre-commit hook allows commit (no nags blocking)"
else
    echo "❌ Pre-commit hook unexpectedly blocking commit"
    exit 1
fi

# Test commit-msg hook
if echo "test message" | .git/hooks/commit-msg /dev/stdin > /dev/null 2>&1; then
    echo "✅ Commit-msg hook accepts valid message"
else
    echo "❌ Commit-msg hook rejects valid message"
    exit 1
fi

# Test with short message (should fail)
if echo "x" | .git/hooks/commit-msg /dev/stdin > /dev/null 2>&1; then
    echo "❌ Commit-msg hook should reject short message"
    exit 1
else
    echo "✅ Commit-msg hook correctly rejects short message"
fi

# Clean up test file
git reset HEAD test-commit.txt > /dev/null 2>&1
rm test-commit.txt

echo ""
echo "🎉 All tests passed!"
echo ""
echo "📋 Summary:"
echo "  • Vendor: $VENDOR_FOUND"
echo "  • Templates: ✅ Installed"
echo "  • Git Hooks: ✅ Working"
echo "  • JSON Files: ✅ Valid"
echo "  • Nag System: ✅ Ready"
echo ""
echo "🚀 Ready to use Nightshift!"
