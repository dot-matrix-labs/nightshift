# Nightshift Documentation

The entry point for the Nightshift "Documentation Fractal".

## Installation

To adopt Nightshift in your project, give this prompt to your AI agent:

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

## Table of Contents

### 1. [Methodology](./methodology/README.md)

_Core principles and workflows of the Nightshift Protocol._

- [Architecture](./methodology/architecture.md): Canonical templates and shims.
- [Git Brain](./methodology/git-brain.md): Reasoning ledgers.
- [Nags](./methodology/nags.md): Quality gates.
- [New Module Development](./methodology/new-module-development.md): Plan -> Stub -> Implement.
- [Documentation Fractal](./methodology/documentation-fractal.md): Structuring knowledge.

### 2. [Product Vision](./product-vision/1-vision.md)

_The "Why" and long-term goals._

- [Vision](./product-vision/1-vision.md)
- [Original PRD (Deprecated)](./product-vision/original-prd-deprecated.md)

### 3. [Product Features](./product-features/1-features.md)

_What Nightshift does._

- [Features List](./product-features/1-features.md)
- [Feature Specs](./product-features/specs/knowledge-base-feature.md)

### 4. [Technical Docs](./technical/technical-spec.md)

_How it works under the hood._

- [Technical Spec](./technical/technical-spec.md)
- [Git Hooks](./technical/git-hooks.md)

### 5. [Development](./development/README.md)

_Contributing to Nightshift._

- [Agent Bootstrap Instructions](./development/agent-bootstrap-instructions.md)
- [Coding Guidelines](./development/2-coding-guidelines.md)
- [Testing](./development/3-testing.md)

### 6. [Research](./research/research-synthesis.md)

_Background investigations and hypotheses._

- [Research Synthesis](./research/research-synthesis.md)
- [Hypothesis: Multi-Agent](./research/hypothesis-multi-agent.md)
- [Hypothesis: Git Brain](./research/hypothesis-git-brain.md)

---

## Quick Links

- [CLI Installation](./cli-installation.md)
