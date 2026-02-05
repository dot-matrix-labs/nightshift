#!/usr/bin/env bash
set -e

# Nightshift Development Installation Script
#
# This script sets up Nightshift for local development by:
# 1. Building the plugin with all dependencies bundled
# 2. Linking the built file to OpenCode's global config
# 3. Linking templates and commands
#
# After running this, you can use `bun run dev` to watch for changes

OPENCODE_CONFIG="${HOME}/.config/opencode"
PLUGIN_DIR="${OPENCODE_CONFIG}/plugin/nightshift"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🏭 Nightshift Development Installation"
echo "========================================"
echo ""
echo "Project root: ${PROJECT_ROOT}"
echo "OpenCode config: ${OPENCODE_CONFIG}"
echo ""

# Step 1: Build the plugin
echo "📦 Building plugin..."
cd "${PROJECT_ROOT}"
bun run build

if [ ! -f "${PROJECT_ROOT}/dist/index.js" ]; then
    echo "❌ Build failed - dist/index.js not found"
    exit 1
fi

echo "✅ Build complete ($(du -h "${PROJECT_ROOT}/dist/index.js" | cut -f1))"
echo ""

# Step 2: Create OpenCode config directories
echo "📁 Creating OpenCode config directories..."
mkdir -p "${OPENCODE_CONFIG}/plugin"
mkdir -p "${OPENCODE_CONFIG}/command"
mkdir -p "${OPENCODE_CONFIG}/agents"
mkdir -p "${PLUGIN_DIR}"

# Step 3: Link the main plugin file
echo "🔗 Linking plugin file..."
PLUGIN_LINK="${OPENCODE_CONFIG}/plugin/nightshift.js"

if [ -e "${PLUGIN_LINK}" ] || [ -L "${PLUGIN_LINK}" ]; then
    rm -rf "${PLUGIN_LINK}"
    echo "   Removed existing file/link"
fi

ln -s "${PROJECT_ROOT}/dist/index.js" "${PLUGIN_LINK}"
echo "   ${PLUGIN_LINK} -> ${PROJECT_ROOT}/dist/index.js"

# Step 4: Link templates directory
echo "🔗 Linking templates..."
TEMPLATES_LINK="${PLUGIN_DIR}/templates"

if [ -e "${TEMPLATES_LINK}" ] || [ -L "${TEMPLATES_LINK}" ]; then
    rm -rf "${TEMPLATES_LINK}"
    echo "   Removed existing directory/link"
fi

ln -s "${PROJECT_ROOT}/templates" "${TEMPLATES_LINK}"
echo "   ${TEMPLATES_LINK} -> ${PROJECT_ROOT}/templates"

# Step 5: Link command files
echo "🔗 Linking commands..."
for cmd in "${PROJECT_ROOT}/templates/commands"/*.md; do
    if [ -f "${cmd}" ]; then
        cmd_name=$(basename "${cmd}")
        cmd_link="${OPENCODE_CONFIG}/command/${cmd_name}"

        if [ -e "${cmd_link}" ] || [ -L "${cmd_link}" ]; then
            rm -rf "${cmd_link}"
        fi

        ln -s "${cmd}" "${cmd_link}"
        echo "   ${cmd_name} -> ${cmd}"
    fi
done

# Step 5b: Link agent files
echo "🔗 Linking agents..."
for agent in "${PROJECT_ROOT}/templates/agents"/*.md; do
    if [ -f "${agent}" ]; then
        agent_name=$(basename "${agent}")
        agent_link="${OPENCODE_CONFIG}/agents/${agent_name}"

        if [ -e "${agent_link}" ] || [ -L "${agent_link}" ]; then
            rm -rf "${agent_link}"
        fi

        ln -s "${agent}" "${agent_link}"
        echo "   ${agent_name} -> ${agent}"
    fi
done

# Step 6: Validate opencode.json
echo ""
echo "🔍 Validating opencode.json..."
OPENCODE_JSON="${OPENCODE_CONFIG}/opencode.json"
if [ -f "${OPENCODE_JSON}" ]; then
    if python3 -c "import json; json.load(open('${OPENCODE_JSON}'))" 2>/dev/null || \
       node -e "JSON.parse(require('fs').readFileSync('${OPENCODE_JSON}', 'utf8'))" 2>/dev/null; then
        echo "   ✅ opencode.json is valid"
    else
        echo "   ❌ opencode.json is malformed - installation may fail"
        echo "   Consider running: rm ${OPENCODE_JSON} && opencode --init"
        exit 1
    fi
else
    echo "   ⚠️  opencode.json not found - run 'opencode --init' to create it"
fi

# Step 7: Add Nightshift instructions to opencode.json
echo ""
echo "📝 Adding Nightshift instructions to opencode.json..."
DOC_INDEX="${PROJECT_ROOT}/templates/commands/docs-index.md"
if [ -f "${DOC_INDEX}" ]; then
    if command -v python3 &> /dev/null; then
        python3 << PYTHON_SCRIPT
import json
import sys

opencode_json = "${OPENCODE_CONFIG}/opencode.json"
try:
    with open(opencode_json, 'r') as f:
        config = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    config = {}

if 'instructions' not in config:
    config['instructions'] = []

nightshift_instructions = "${DOC_INDEX}"
if nightshift_instructions not in config['instructions']:
    config['instructions'].append(nightshift_instructions)
    with open(opencode_json, 'w') as f:
        json.dump(config, f, indent=4)
    print(f"   ✅ Added ${DOC_INDEX} to instructions")
else:
    print("   ✅ Nightshift instructions already configured")
PYTHON_SCRIPT
    else
        echo "   ⚠️  python3 not available - skip instructions config"
    fi
else
    echo "   ⚠️  docs-index.md not found - skipping instructions config"
fi

echo ""
echo "✅ Development installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Run 'bun run dev' to start watch mode (auto-rebuild on changes)"
echo "   2. Any changes to src/ will trigger a rebuild"
echo "   3. OpenCode will use the linked plugin automatically"
echo ""
echo "🔍 Verify installation:"
echo "   Plugin: ls -la ${OPENCODE_CONFIG}/plugin/nightshift.js"
echo "   Templates: ls -la ${PLUGIN_DIR}/templates"
echo "   Commands: ls -la ${OPENCODE_CONFIG}/command/"
echo "   Agents: ls -la ${OPENCODE_CONFIG}/agents/"
echo ""
