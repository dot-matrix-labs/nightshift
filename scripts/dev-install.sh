#!/usr/bin/env bash
set -e

# Nightshift Development Installation Script
#
# This script configures the Nightshift development environment for OpenCode.
# It builds the plugin and generates an opencode.json with agent personas.
#
# Usage: ./scripts/dev-install.sh
#
# This script is designed to be vendor-agnostic - CLI tools that integrate
# with Nightshift can invoke this script during their own installation flow.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCODE_JSON="${PROJECT_ROOT}/opencode.json"
TEMPLATE="${PROJECT_ROOT}/templates/opencode/opencode.json.hbs"
COMMANDS_DIR="${PROJECT_ROOT}/.opencode/command"

echo "🏭 Nightshift Development Installation"
echo "========================================"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Step 1: Build the plugin
echo "📦 Building plugin..."
cd "${PROJECT_ROOT}"
bun run build

if [ ! -f "${PROJECT_ROOT}/dist/index.js" ]; then
    echo "❌ Build failed - dist/index.js not found"
    exit 1
fi
echo "✅ Build complete"
echo ""

# Step 2: Generate opencode.json from template if invalid or missing
echo "📝 Configuring opencode.json..."

if [ -f "${OPENCODE_JSON}" ]; then
    # Check if valid JSON
    if node -e "require('fs').readFileSync('${OPENCODE_JSON}', 'utf8')" 2>/dev/null; then
        echo "   ✅ opencode.json is valid - preserving"
    else
        echo "   ⚠️  opencode.json is invalid - regenerating from template"
        cp "${TEMPLATE}" "${OPENCODE_JSON}"
        echo "   ✅ Regenerated opencode.json"
    fi
else
    echo "   📄 Generating opencode.json from template..."
    cp "${TEMPLATE}" "${OPENCODE_JSON}"
    echo "   ✅ Generated opencode.json"
fi

# Step 3: Link command files to .opencode/command/
echo "🔗 Linking commands..."
mkdir -p "${COMMANDS_DIR}"
for cmd in "${PROJECT_ROOT}/templates/commands"/*.md; do
    if [ -f "${cmd}" ]; then
        cmd_name=$(basename "${cmd}")
        cmd_link="${COMMANDS_DIR}/${cmd_name}"

        if [ -e "${cmd_link}" ] || [ -L "${cmd_link}" ]; then
            rm -rf "${cmd_link}"
        fi

        ln -s "${cmd}" "${cmd_link}"
        echo "   ${cmd_name} -> ${cmd}"
    fi
done

echo ""
echo "✅ Development installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Run 'bun run dev' to start watch mode"
echo "   2. OpenCode will use the project opencode.json"
echo ""
echo "🔍 Verify: cat ${OPENCODE_JSON}"
echo ""
