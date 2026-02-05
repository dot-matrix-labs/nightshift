#!/bin/bash

# Nightshift Pre-Commit Hook
#
# This hook runs before commits to ensure quality gates are met.
# Customize for your project.

echo "🔍 Nightshift Pre-Commit Hook"
echo "==============================="

# Check for untracked files that should be staged
echo "   Checking for missing documentation..."
docs_needed=$(find . -name "*.md" -newer .git/index 2>/dev/null | head -5)
if [ -n "$docs_needed" ]; then
    echo "   ⚠️  New documentation files detected:"
    echo "$docs_needed" | sed 's/^/      /'
fi

# Run linting if available
if [ -f "package.json" ] && grep -q '"lint"' package.json 2>/dev/null; then
    echo "   Running lint..."
    npm run lint 2>/dev/null || {
        echo "   ❌ Linting failed"
        exit 1
    }
fi

# Run tests if available
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    echo "   Running tests..."
    npm test 2>/dev/null || {
        echo "   ❌ Tests failed"
        exit 1
    }
fi

echo "   ✅ Pre-commit checks passed"
exit 0
