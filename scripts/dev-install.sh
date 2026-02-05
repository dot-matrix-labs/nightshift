#!/usr/bin/env bash
set -e

# Nightshift Development Installation Script
#
# This script sets up Nightshift for local development by:
# 1. Building the plugin with all dependencies bundled
# 2. Linking the built file to OpenCode's global config
# 3. Configuring agents and commands in project opencode.json
#
# After running this, you can use `bun run dev` to watch for changes

OPENCODE_CONFIG="${HOME}/.config/opencode"
PLUGIN_DIR="${OPENCODE_CONFIG}/plugin/nightshift"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_OPENCODE_JSON="${PROJECT_ROOT}/opencode.json"

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

# Step 2: Create OpenCode config directory
echo "📁 Creating OpenCode config directories..."
mkdir -p "${OPENCODE_CONFIG}/plugin"
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

# Step 5: Configure agents in project opencode.json
echo ""
echo "📝 Configuring agents in opencode.json..."

if command -v python3 &> /dev/null; then
    python3 << 'PYTHON_SCRIPT'
import json
import os

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
project_opencode_json = os.path.join(project_root, 'opencode.json')
templates_dir = os.path.join(project_root, 'templates')
agents_dir = os.path.join(templates_dir, 'agents')

# Load or create config
try:
    with open(project_opencode_json, 'r') as f:
        config = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    config = {}

if 'agent' not in config:
    config['agent'] = {}

# Read agent templates and add to config
agent_configs = {
    'engineer': {
        'description': 'Autonomous Engineer - Implements features and fixes bugs',
        'mode': 'primary',
        'prompt': '{file:./templates/agents/engineer.md}',
        'tools': {'write': True, 'edit': True, 'bash': True}
    },
    'planner': {
        'description': 'Strategic Planner - Plans and analyzes tasks',
        'mode': 'primary',
        'prompt': '{file:./templates/agents/planner.md}',
        'tools': {'write': False, 'edit': False, 'bash': False}
    },
    'curator': {
        'description': 'Knowledge Curator - Manages documentation and context',
        'mode': 'subagent',
        'prompt': '{file:./templates/agents/curator.md}',
        'tools': {'write': True, 'edit': True, 'bash': False}
    },
    'git-supervisor': {
        'description': 'Git Supervisor - Manages branches and commits',
        'mode': 'subagent',
        'prompt': '{file:./templates/agents/git-supervisor.md}',
        'tools': {'write': False, 'edit': False, 'bash': True}
    },
    'pm-supervisor': {
        'description': 'PM Supervisor - Project management and task tracking',
        'mode': 'subagent',
        'prompt': '{file:./templates/agents/pm-supervisor.md}',
        'tools': {'write': True, 'edit': True, 'bash': False}
    },
    'finance-supervisor': {
        'description': 'Finance Supervisor - Monitors costs and budgets',
        'mode': 'subagent',
        'prompt': '{file:./templates/agents/finance-supervisor.md}',
        'tools': {'write': False, 'edit': False, 'bash': False}
    }
}

for agent_name, agent_config in agent_configs.items():
    agent_file = os.path.join(agents_dir, f'{agent_name}.md')
    if os.path.exists(agent_file):
        config['agent'][agent_name] = agent_config
        print(f"   ✅ Configured {agent_name}")
    else:
        print(f"   ⚠️  Agent file not found: {agent_file}")

# Ensure schema
config['$schema'] = 'https://opencode.ai/config.json'

# Write config
with open(project_opencode_json, 'w') as f:
    json.dump(config, f, indent=4)

print(f"   ✅ Updated {project_opencode_json}")
PYTHON_SCRIPT
else
    echo "   ⚠️  python3 not available - skipping agent config"
fi

# Step 6: Add Nightshift instructions to project opencode.json
echo ""
echo "📝 Adding Nightshift instructions to opencode.json..."
DOC_INDEX="${PROJECT_ROOT}/templates/commands/docs-index.md"
if [ -f "${DOC_INDEX}" ]; then
    if command -v python3 &> /dev/null; then
        python3 << PYTHON_SCRIPT
import json

project_opencode_json = "${PROJECT_OPENCODE_JSON}"
try:
    with open(project_opencode_json, 'r') as f:
        config = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    config = {}

if 'instructions' not in config:
    config['instructions'] = []

nightshift_instructions = "${DOC_INDEX}"
if nightshift_instructions not in config['instructions']:
    config['instructions'].append(nightshift_instructions)
    with open(project_opencode_json, 'w') as f:
        json.dump(config, f, indent=4)
    print(f"   ✅ Added docs-index.md to instructions")
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
echo "   Config: cat ${PROJECT_OPENCODE_JSON} | head -50"
echo ""
