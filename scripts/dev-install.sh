#!/usr/bin/env bash
set -e

# Nightshift Development Installation Script
#
# Sets up Nightshift for local development by building the plugin and
# configuring opencode.json with agent personas.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCODE_JSON="${PROJECT_ROOT}/opencode.json"

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

# Step 2: Configure opencode.json
echo "📝 Configuring opencode.json..."

# Merge agent configs into opencode.json using node
node -e "
const fs = require('fs');
const config = fs.existsSync('${OPENCODE_JSON}') ? JSON.parse(fs.readFileSync('${OPENCODE_JSON}', 'utf8')) : {};
config['\$schema'] = 'https://opencode.ai/config.json';
config.agent = {
  engineer: { description: 'Autonomous Engineer', mode: 'primary', prompt: '{file:./templates/agents/engineer.md}', tools: { write: true, edit: true, bash: true } },
  planner: { description: 'Strategic Planner', mode: 'primary', prompt: '{file:./templates/agents/planner.md}', tools: { write: false, edit: false, bash: false } },
  curator: { description: 'Knowledge Curator', mode: 'subagent', prompt: '{file:./templates/agents/curator.md}', tools: { write: true, edit: true, bash: false } },
  'git-supervisor': { description: 'Git Supervisor', mode: 'subagent', prompt: '{file:./templates/agents/git-supervisor.md}', tools: { write: false, edit: false, bash: true } },
  'pm-supervisor': { description: 'PM Supervisor', mode: 'subagent', prompt: '{file:./templates/agents/pm-supervisor.md}', tools: { write: true, edit: true, bash: false } },
  'finance-supervisor': { description: 'Finance Supervisor', mode: 'subagent', prompt: '{file:./templates/agents/finance-supervisor.md}', tools: { write: false, edit: false, bash: false } }
};
config.instructions = ['./templates/commands/docs-index.md'];
fs.writeFileSync('${OPENCODE_JSON}', JSON.stringify(config, null, 4));
console.log('✅ Configured agents: engineer, planner, curator, git-supervisor, pm-supervisor, finance-supervisor');
console.log('✅ Added docs-index.md to instructions');
"

echo ""
echo "✅ Development installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Run 'bun run dev' to start watch mode"
echo "   2. OpenCode will use the project opencode.json"
echo ""
echo "🔍 Verify: cat ${OPENCODE_JSON}"
echo ""
