![Nightshift Banner](./docs/assets/banner.svg)

## Quick Start

Give this prompt to your AI agent to bootstrap Nightshift:

```
Agent: I want to adopt the Nightshift methodology for this repository.

1. Read the Nightshift installation guide at:
   https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/docs/README.md

2. Run the installer for your agent:
   curl -fsSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/install-templates.sh | bash

   Or for specific vendors:
   - Claude Code: curl ... | bash -s -- claude
   - Cursor:     curl ... | bash -s -- cursor
   - Gemini CLI: curl ... | bash -s -- gemini
   - Codex CLI:  curl ... | bash -s -- codex

3. After installation:
   - Check .nightshift/ directory exists
   - Check vendor shim file is installed
   - Restart your agent and create branch ns/session/nightshift-bootstrap
```

**What you get:** `.nightshift/` templates, vendor shim, and git hooks for quality gates.

---

**Nightshift** is a methodology for enabling autonomous AI agents to build, maintain, and document large software projects. It shifts from human-readable code to machine-reproducible "Reasoning Ledgers."

## Why

We want agents to work overnight, and the factory must not catch fire.

Ever had an agent:

- Fake the tests?
- Say "it's perfect" but it doesn't compile?
- Get stuck in a loop?

We need autonomous software factories with quality gates and structured context.

## Core Concepts

- **Git-Brain**: Git is all you need. Commits are a "Reasoning Ledger." We store the _prompt_ and _intent_ in hidden metadata to allow perfect replayability.
- **Deep Context**: A "Documentation Fractal" anchored by [docs/README.md](./docs/README.md) allows agents to situate themselves without RAG, vector stores, or "magic."
- **Multi-Agent**: Use different reasoning providers for what they do best, at the best cost, for the right unit of work.
- **Semantic Worktrees**: Git branches are named like file paths (`ns/session/option-a`) to show lineage and intent.
- **Nags**: Mandatory "Gateways of Last Resort" checklists that agents must pass before marking tasks complete.

---

## Two Ways to Use

### 1. The Methodology (Recommended)

**For: Users with existing AI coding assistants (OpenCode, Claude Code, Cursor, Gemini CLI, Codex, etc.)**

You don't need to install any new software. You simply adopt the **Nightshift Protocol** to give your agents better memory, context, and quality control.

#### What This Does

1. Creates `.nightshift/` folder with canonical templates (protocols, commands, nags)
2. Installs a vendor-specific "shim" file that points your agent to `.nightshift/`
3. Installs git hooks to enforce quality gates (nags) before commits

See [Installation Guide](./docs/README.md) for full documentation.

#### What You Get

- **Quality Gates (Nags)**: Git hooks enforce build/test/lint checks before commits
- **Session Continuity**: Forward-prompt enables agents to resume work across sessions
- **Git-Brain Commits**: Structured commits with reasoning metadata
- **New Module Workflow**: Plan → Stub → Implement process for new features
- **Agent Personas**: Engineer and Planner roles for different tasks

---

### 2. The Service (Alpha - CLI Tool)

**⚠️ WARNING: The Nightshift CLI is currently alpha-quality software. Expect bugs and breaking changes.**

**For: Users who want fully autonomous, long-running orchestration.**

The Nightshift Service is a standalone CLI/TUI that manages multiple agents, handles API costs, and runs while you sleep.

**Features**

- 🖥️ **TUI Dashboard** - Real-time factory monitoring.
- 📦 **Project Isolation** - Git worktree sandboxing.
- 💰 **Finance Management** - Automatic provider switching and budget tracking.

**Installation**

```bash
# Install via curl (Linux & macOS)
curl -fsSL https://raw.githubusercontent.com/dot-matrix-labs/nightshift/main/install.sh | bash

# Run
nightshift
```

For manual installation or building from source, see [CLI Installation Guide](./docs/cli-installation.md).

---

## Documentation

### Getting Started

- [Installation Guide](./docs/README.md) - Install Nightshift templates for your AI agent
- [Knowledge Base](./docs/README.md) - The entry point for all documentation

### Methodology

- [Git Hooks & Nags](./docs/methodology/nags.md) - How quality gates keep your code clean
- [Canonical Files & Shims](./docs/methodology/architecture.md) - Why we separate templates from agent configs
- [New Module Workflow](./docs/methodology/new-module-development.md) - Plan → Stub → Implement process
- [Git-Brain Commits](./docs/methodology/git-brain.md) - Reasoning ledgers and commit metadata

### Product Vision

- [Vision](./docs/product-vision/1-vision.md)
- [Architecture](./docs/technical/architecture.md)

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for development setup and guidelines.

## License

[License details here]
