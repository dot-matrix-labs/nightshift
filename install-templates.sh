#!/bin/bash
#
# Nightshift Installation Script
# 
# Installs the Nightshift methodology into the current project.
# Downloads templates via GitHub tarball - NO git clone required.
# Creates a clean .nightshift/ folder with NO .git directory.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lucky-tensor/nightshift/main/install-templates.sh | bash
#
# Or with vendor:
#   curl -fsSL https://raw.githubusercontent.com/lucky-tensor/nightshift/main/install-templates.sh | bash -s -- claude
#
# Vendors: opencode (default), claude, cursor, gemini, codex
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VENDOR="${1:-opencode}"
GITHUB_REPO="lucky-tensor/nightshift"
BRANCH="main"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Nightshift Template Installer                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository.${NC}"
    echo "Please run this script from within a git project."
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT"

echo -e "${YELLOW}Vendor:${NC} $VENDOR"
echo -e "${YELLOW}Project:${NC} $PROJECT_ROOT"
echo ""

# Create a working directory WITHIN the project (not /tmp - agents may not have access)
WORK_DIR="$PROJECT_ROOT/.nightshift-install-tmp"
mkdir -p "$WORK_DIR"

# Cleanup function - always remove temp dir
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# Download the tarball from GitHub (NO git clone!)
# This downloads a clean archive with no .git folder
echo -e "${BLUE}Downloading Nightshift templates (via tarball, no git clone)...${NC}"
TARBALL_URL="https://github.com/${GITHUB_REPO}/archive/refs/heads/${BRANCH}.tar.gz"

if command -v curl &> /dev/null; then
    curl -fsSL "$TARBALL_URL" | tar -xz -C "$WORK_DIR" --strip-components=1
elif command -v wget &> /dev/null; then
    wget -qO- "$TARBALL_URL" | tar -xz -C "$WORK_DIR" --strip-components=1
else
    echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${NC}"
    exit 1
fi

# Verify the download worked
if [ ! -f "$WORK_DIR/templates/AGENTS.md" ]; then
    echo -e "${RED}Error: Failed to download templates. Check your internet connection.${NC}"
    exit 1
fi

echo -e "${GREEN}Download complete.${NC}"

# Copy .nightshift directory (clean copy, absolutely no .git)
echo -e "${BLUE}Installing .nightshift/ templates...${NC}"
if [ -d ".nightshift" ]; then
    echo -e "${YELLOW}Warning: .nightshift/ already exists. Backing up to .nightshift.bak${NC}"
    rm -rf .nightshift.bak
    mv .nightshift .nightshift.bak
fi

# Create directory and copy all templates EXCEPT shims
mkdir -p .nightshift
cp -r "$WORK_DIR/templates/"* .nightshift/
rm -rf .nightshift/shims

# IMPORTANT: Ensure NO .git folder exists (tarball shouldn't have one, but be paranoid)
rm -rf .nightshift/.git 2>/dev/null || true

echo -e "${GREEN}Installed: .nightshift/ (clean, no .git)${NC}"

# Install Documentation Rules (make them visible)
echo -e "${BLUE}Installing documentation rules...${NC}"
mkdir -p docs
if [ -f "docs/documentation-rules.md" ]; then
    echo -e "${YELLOW}Warning: docs/documentation-rules.md exists. Backing up.${NC}"
    mv docs/documentation-rules.md docs/documentation-rules.md.bak
fi
cp .nightshift/docs/documentation-rules.md docs/documentation-rules.md
echo -e "${GREEN}Installed: docs/documentation-rules.md${NC}"

# Install vendor shim
echo -e "${BLUE}Installing $VENDOR shim...${NC}"
case "$VENDOR" in
    opencode)
        if [ -f "opencode.json" ]; then
            echo -e "${YELLOW}Warning: opencode.json exists. Backing up.${NC}"
            mv opencode.json opencode.json.bak
        fi
        cp "$WORK_DIR/templates/shims/opencode.json" opencode.json
        echo -e "${GREEN}Installed: opencode.json${NC}"
        ;;
    claude)
        mkdir -p .claude
        if [ -f ".claude/CLAUDE.md" ]; then
            echo -e "${YELLOW}Warning: .claude/CLAUDE.md exists. Backing up.${NC}"
            mv .claude/CLAUDE.md .claude/CLAUDE.md.bak
        fi
        cp "$WORK_DIR/templates/shims/claude/CLAUDE.md" .claude/CLAUDE.md
        echo -e "${GREEN}Installed: .claude/CLAUDE.md${NC}"
        if [ -f "$WORK_DIR/templates/shims/claude/settings.json" ]; then
            if [ -f ".claude/settings.json" ]; then
                echo -e "${YELLOW}Warning: .claude/settings.json exists. Backing up.${NC}"
                mv .claude/settings.json .claude/settings.json.bak
            fi
            cp "$WORK_DIR/templates/shims/claude/settings.json" .claude/settings.json
            echo -e "${GREEN}Installed: .claude/settings.json${NC}"
        fi
        ;;
    cursor)
        mkdir -p .cursor/rules
        if [ -f ".cursorrules" ]; then
            echo -e "${YELLOW}Warning: .cursorrules exists. Backing up.${NC}"
            mv .cursorrules .cursorrules.bak
        fi
        cp "$WORK_DIR/templates/shims/cursor/.cursorrules" .cursorrules
        echo -e "${GREEN}Installed: .cursorrules${NC}"
        if [ -f "$WORK_DIR/templates/shims/cursor/nightshift.mdc" ]; then
            cp "$WORK_DIR/templates/shims/cursor/nightshift.mdc" .cursor/rules/nightshift.mdc
            echo -e "${GREEN}Installed: .cursor/rules/nightshift.mdc${NC}"
        fi
        ;;
    gemini)
        if [ -f "GEMINI.md" ]; then
            echo -e "${YELLOW}Warning: GEMINI.md exists. Backing up.${NC}"
            mv GEMINI.md GEMINI.md.bak
        fi
        cp "$WORK_DIR/templates/shims/gemini/GEMINI.md" GEMINI.md
        echo -e "${GREEN}Installed: GEMINI.md${NC}"
        ;;
    codex)
        if [ -f "AGENTS.md" ]; then
            echo -e "${YELLOW}Warning: AGENTS.md exists. Backing up.${NC}"
            mv AGENTS.md AGENTS.md.bak
        fi
        cp "$WORK_DIR/templates/shims/codex/AGENTS.md" AGENTS.md
        echo -e "${GREEN}Installed: AGENTS.md${NC}"
        ;;
    *)
        echo -e "${RED}Unknown vendor: $VENDOR${NC}"
        echo "Valid options: opencode, claude, cursor, gemini, codex"
        exit 1
        ;;
esac

# Install git hooks
echo -e "${BLUE}Installing git hooks...${NC}"
cp .nightshift/hooks/pre-commit .git/hooks/pre-commit
cp .nightshift/hooks/commit-msg .git/hooks/commit-msg
cp .nightshift/hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg .git/hooks/pre-push
echo -e "${GREEN}Installed: .git/hooks/pre-commit${NC}"
echo -e "${GREEN}Installed: .git/hooks/commit-msg${NC}"
echo -e "${GREEN}Installed: .git/hooks/pre-push${NC}"

# Cleanup is handled by trap EXIT

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Nightshift Installation Complete!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Installed files:${NC}"
echo "  .nightshift/          - Templates, commands, nags, hooks (NO .git)"
case "$VENDOR" in
    opencode) echo "  opencode.json         - OpenCode configuration shim" ;;
    claude)   echo "  .claude/CLAUDE.md     - Claude Code configuration shim"
              echo "  .claude/settings.json - Claude Code settings" ;;
    cursor)   echo "  .cursorrules          - Cursor configuration shim"
              echo "  .cursor/rules/nightshift.mdc - Cursor rule file" ;;
    gemini)   echo "  GEMINI.md             - Gemini CLI configuration shim" ;;
    codex)    echo "  AGENTS.md             - Codex CLI configuration shim" ;;
esac
echo "  .git/hooks/pre-commit - Nag enforcement hook"
echo "  .git/hooks/commit-msg - Commit message validation hook"
echo "  .git/hooks/pre-push   - Documentation rules enforcement hook"
echo ""
echo -e "${BLUE}Next steps:${NC}"
case "$VENDOR" in
    opencode)
        echo "  1. Run: opencode"
        echo "  2. Type: /session-start"
        ;;
    claude)
        echo "  1. Run: claude"
        echo "  2. Say: Read .nightshift/AGENTS.md and initialize"
        ;;
    cursor)
        echo "  1. Open project in Cursor"
        echo "  2. Rules are loaded automatically"
        ;;
    gemini)
        echo "  1. Run: gemini"
        echo "  2. Say: Read .nightshift/AGENTS.md and initialize"
        ;;
    codex)
        echo "  1. Run: codex"
        echo "  2. AGENTS.md is loaded automatically"
        ;;
esac
echo ""
echo -e "${YELLOW}Bypass git hooks (human-supervised only):${NC}"
echo "  NIGHTSHIFT_BYPASS=1 git commit -m \"message\""
echo ""
