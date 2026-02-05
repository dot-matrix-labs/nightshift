# Agent Bootstrap Instructions

## Overview

This document guides an AI agent on how to "Bootstrap" an existing repository into the **Nightshift Methodology**.

## Instructions for the Agent

If a user asks you to "Bootstrap this repo using Nightshift", follow these steps:

### 1. Establish the Documentation Anchor

### 2. Establish Canonical Documentation

Create the following directory structure in `docs/` and move/create relevant markdown files:

```
docs/
├── product_vision/      # High-level goals (1-vision.md)
├── product_features/    # Functional specs (1-features.md)
├── technical/           # Architecture & Constraints (1-technical-challenges.md)
├── development/         # Guides & Process (1-quickstart.md)
└── tasks/               # Work tracking (1-todo.md, 2-done.md)
```

**Task**: Scan existing docs (README, wikis) and populate these files.

### 3. Install Templates

Create a `templates/` directory to store agent instructions.

- **`templates/nags/`**: Create nag templates for quality enforcement
- **`templates/commands/`**: Create `git-brain-commit.md` containing the protocol for "Reasoning Ledger" commits.

### 4. Install Quality Gate Hooks

Install git hooks that enforce nag completion before commits. This ensures agents cannot skip quality checks.

**Create `.nightshift/hooks/` directory:**

```bash
mkdir -p .nightshift/hooks
```

**Create `.nightshift/nag-status.json`:**

```json
{
    "sessionId": "manual",
    "nags": {},
    "lastUpdated": ""
}
```

**Copy pre-commit hook to `.git/hooks/pre-commit`:**

Copy `templates/hooks/pre-commit` from the Nightshift repository to `.git/hooks/pre-commit`.

**Make hooks executable:**

```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/commit-msg  # if using
```

**Register nags:**

Run quality checks and update `.nightshift/nag-status.json` with the results. See `templates/commands/update-nag-status.md` for the protocol.

### 5. Update Navigation

### 6. Git-Brain Protocol

Inform the user that future commits should follow the **Git-Brain** standard:

- Conventional Commit header.
- Hidden `GIT_BRAIN_METADATA` HTML comment footer containing the `retroactive_prompt` used to generate the change.

### 7. Forward Prompt Initialization

Create `.nightshift/forward-prompt.md` to enable agent continuity:

```markdown
# Forward Prompt

> This document describes the state of work for the next agent to continue.
> Last updated: [timestamp]

## Objective

[Current high-level goal]

## Current Status

[What has been accomplished]

## Next Steps

1. [Most important next action]
2. [Second priority]

## Blockers

- [Any issues preventing progress]

## Context Notes

[Important context for the next agent]
```

Instruct the agent to update this file regularly throughout their session.
