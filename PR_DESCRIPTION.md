# Fix: Development Installation Script for OpenCode Integration

## Summary

This PR fixes and improves the `dev-install.sh` script to properly integrate Nightshift with OpenCode, ensuring slash commands and agents are available in the OpenCode environment.

## Key Changes

### 1. Fixed Commands Path

Changed the commands loop from `${PROJECT_ROOT}/commands` to `${PROJECT_ROOT}/templates/commands` to correctly link Nightshift's command templates.

### 2. Added Agent Linking

Added a new step to link agent files from `templates/agents/` to `~/.config/opencode/agents/`, making Nightshift agent personas (engineer, curator, planner, etc.) available as selectable agents in OpenCode.

### 3. OpenCode Configuration

Added logic to automatically configure `opencode.json` to include `templates/commands/docs-index.md` in the `instructions` array, ensuring the Nightshift methodology is loaded for all OpenCode sessions.

### 4. JSON Validation

Added validation of `opencode.json` before completing installation to catch malformed configuration files that could cause OpenCode to crash.

## Verification

Run the updated installation script:

```bash
./scripts/dev-install.sh
```

This will:

- Build the Nightshift plugin
- Link the plugin to OpenCode's config directory
- Link templates, commands, and agents
- Validate `opencode.json`
- Configure instructions to include Nightshift's documentation
