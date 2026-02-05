#!/bin/bash

# Nightshift Pre-Push Hook
#
# This hook runs before pushes to ensure code is ready for sharing.
# Customize for your project.

echo "🚀 Nightshift Pre-Push Hook"
echo "============================"

# Check if we're on a feature branch (ns/ prefix)
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
if [[ "$BRANCH" == ns/* ]]; then
    echo "   📦 Nightshift branch detected: ${BRANCH}"
    echo "   (Branches are automatically pushed - no special checks needed)"
fi

# Verify no secrets in recent commits
echo "   Scanning for potential secrets..."
if command -v gitleaks &> /dev/null; then
    gitleaks detect --source=. --verbose 2>/dev/null || true
else
    echo "   ⚠️  gitleaks not installed - skipping secret scan"
    echo "   (Install gitleaks for automated secret detection)"
fi

echo "   ✅ Pre-push checks complete"
exit 0
