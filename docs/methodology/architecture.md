# Canonical Files & Shims Architecture

## The Problem

You have multiple AI coding assistants (OpenCode, Claude Code, Cursor, Gemini CLI, Codex). Each has its own configuration format:

- OpenCode uses `opencode.json`
- Claude Code uses `.claude/claude.md`
- Cursor uses `.cursorrules`
- Gemini CLI uses `gemini.md`
- Codex uses `agents.md`

**How do you maintain Nightshift templates across all of them without duplication?**

## The Solution: Canonical + Shim

Nightshift uses a **two-layer architecture**:

1. **Canonical files** (`.nightshift/`) - Single source of truth
2. **Vendor shims** - Lightweight configs that point to canonical files

```
YOUR_PROJECT/
├── .nightshift/              # ← Canonical (source of truth)
│   ├── agents.md
│   ├── agents/
│   ├── commands/
│   ├── nags/
│   └── state/
│
├── opencode.json             # ← Shim for OpenCode
├── .claude/claude.md         # ← Shim for Claude Code
├── .cursorrules              # ← Shim for Cursor
├── gemini.md                 # ← Shim for Gemini CLI
└── agents.md                 # ← Shim for Codex
```

## Why Separate?

### 1. Single Source of Truth

**Problem**: Updating protocols in 5 different config files is error-prone.

**Solution**: Update `.nightshift/agents.md` once. All shims reference it.

### 2. Vendor Independence

**Problem**: You want to try Cursor, but your config is in `opencode.json`.

**Solution**: Add a Cursor shim. Your canonical `.nightshift/` files work with both.

### 3. No Duplication

**Problem**: 5 copies of the engineer persona = 5 places to update.

**Solution**: One copy in `.nightshift/agents/engineer.md`. Shims point to it.

### 4. Clean Git History

**Problem**: Vendor configs mixed with protocol changes.

**Solution**:

- `.nightshift/` changes = protocol updates
- `opencode.json` changes = vendor integration

## How Shims Work

### OpenCode Shim (`opencode.json`)

```json
{
    "instructions": [".nightshift/agents.md"],

    "agent": {
        "nightshift": {
            "description": "Autonomous Nightshift Engineer",
            "prompt": "{file:.nightshift/agents/engineer.md}"
        }
    },

    "command": {
        "git-brain-commit": {
            "template": "{file:.nightshift/commands/git-brain-commit.md}"
        }
    }
}
```

**Key**: `{file:...}` syntax points to canonical files.

### Claude Code Shim (`.claude/claude.md`)

```markdown
# Nightshift Protocol

**Immediately read `.nightshift/agents.md` for the complete protocol.**

## Key Resources

- Core Protocol: `.nightshift/agents.md`
- Engineer Persona: `.nightshift/agents/engineer.md`
- Git-Brain Commits: `.nightshift/commands/git-brain-commit.md`
```

**Key**: Markdown links point to canonical files.

### Cursor Shim (`.cursorrules`)

```markdown
You are operating under the Nightshift Protocol.
Read `.nightshift/agents.md` for full protocol instructions.
```

**Key**: Simple reference to canonical protocol.

## What Goes in Canonical vs Shim?

| Type                         | Location                            | Examples                                       |
| ---------------------------- | ----------------------------------- | ---------------------------------------------- |
| **Protocols**                | Canonical (`.nightshift/`)          | agents.md, engineer.md                         |
| **Commands/SOPs**            | Canonical (`.nightshift/commands/`) | git-brain-commit.md, new-module-development.md |
| **Nags**                     | Canonical (`.nightshift/nags/`)     | javascript-nag.md                              |
| **State**                    | Canonical (`.nightshift/state/`)    | nag-status.json, forward-prompt.md             |
| **Vendor Integration**       | Shim                                | opencode.json, claude.md                       |
| **Vendor-Specific Settings** | Shim                                | `.claude/settings.json` permissions            |

## Example: Adding a New Command

**Bad (duplication)**:

1. Add to `opencode.json` ❌
2. Add to `.claude/claude.md` ❌
3. Add to `gemini.md` ❌
4. Add to `agents.md` (Codex) ❌

**Good (canonical)**:

1. Create `.nightshift/commands/my-command.md` ✅
2. Update shims to reference it ✅

```json
// opencode.json
"my-command": {
  "template": "{file:.nightshift/commands/my-command.md}"
}
```

```markdown
<!-- claude.md -->

- **"My command"**: Follow `.nightshift/commands/my-command.md`
```

## Installation Process

The install script creates this architecture automatically:

```bash
curl -fsSL .../install-templates.sh | bash -s -- opencode
```

**What happens:**

1. Downloads Nightshift templates via tarball (not git clone)
2. Copies `.nightshift/` folder (clean, no .git)
3. Copies vendor shim (e.g., `opencode.json`)
4. Installs git hooks from `.nightshift/hooks/`

**Result**: Clean separation of concerns.

## Benefits

### For Users

✅ **Switch AI vendors easily** - Just install a new shim
✅ **Update protocols once** - All agents see the change
✅ **Clean project root** - Vendor configs are small reference files

### For Nightshift Maintainers

✅ **Single update point** - Fix a bug in one place
✅ **Add vendors easily** - Just create a new shim template
✅ **Version canonical separately** - Protocol evolution independent of vendor changes

### For AI Agents

✅ **Lazy loading** - Load `.nightshift/` files on demand
✅ **No git conflicts** - `.nightshift/` has NO `.git` folder
✅ **Clear instructions** - Shim tells them exactly where to look

## Anti-Pattern: Don't Do This

❌ **Copying protocol text into shims**:

```json
// BAD: Duplicating protocol in opencode.json
{
    "instructions": ["You are a Nightshift Engineer. You must: 1. Be autonomous 2. ..."]
}
```

✅ **Referencing canonical files**:

```json
// GOOD: Pointing to canonical protocol
{
    "instructions": [".nightshift/agents.md"]
}
```

## Migration Path

Already have configs in `opencode.json`? Migrate to canonical:

1. **Extract**: Move protocol text to `.nightshift/agents.md`
2. **Reference**: Update `opencode.json` to use `{file:...}`
3. **Add shims**: Install shims for other vendors
4. **Consolidate**: Remove duplicated content

## Philosophy

> "One source of truth, many interfaces."

The canonical files are the **method**. The shims are the **adapters**. This keeps Nightshift vendor-agnostic while working seamlessly with each tool.
