## Summary
- Streamline README to be a concise reference instead of comprehensive guide
- Simplify architecture by removing redundant documentation files
- Add loop.sh runner and update CI workflow
- Clean up git hooks and bootstrap scripts

## Changes

### README.md
- Complete rewrite to focus on core concepts and quick reference
- Added state machine diagram showing next-prompt.md workflow
- New sections: The Model, next-prompt.md, loop.sh, CI Runner, Git Hooks, GIT_BRAIN_METADATA
- Removed verbose methodology explanations and product vision docs

### Architecture Simplification
- Deleted 30+ documentation files that were redundant or outdated
- Kept only essential templates and scripts
- Removed .prettierrc.json and .gitmodules (no longer needed)

### New Files
- `scripts/loop.sh`: Local runner with serial/parallel modes, worktree isolation

### Updated Files
- `.github/workflows/nightshift.yml`: Simplified CI workflow
- `scripts/bootstrap.sh`: Streamlined bootstrap process
- `hooks/commit-msg`: Updated metadata validation

## Motivation
The original README was overwhelming for new users. This refactor makes Nightshift approachable while retaining all the depth in the templates and hooks. The state machine concept (next-prompt.md as the loop driver) is now front and center.
