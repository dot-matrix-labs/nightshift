# CI-Driven Development Loop Demo Plan

## Objective
Create a prototype GitHub Actions workflow (`demo.yml`) that demonstrates an AI agent working on this repo through CI, establishing a continuous development loop.

## Overview

The workflow uses **Google Gemini** as the AI agent (free tier: 6,000 requests/day).

The demo will:
1. Trigger manually or on `.nightshift/next-prompt.md` changes
2. Read `.nightshift/next-prompt.md` for the task
3. Run Gemini as the agent
4. Create commits (including updating `.nightshift/next-prompt.md`)
5. Push branch and open PR
6. Human merges PR → triggers next iteration

## Implementation Steps

### 1. Create `demo.yml` workflow file

Location: `.github/workflows/demo.yml`

Structure similar to `templates/nightshift.yml` with:
- Manual trigger (`workflow_dispatch`) + optional `next-prompt.md` push trigger
- Same agent execution steps
- Same commit verification (stall detection)
- Same PR creation

### 2. Define trigger conditions

```yaml
on:
  workflow_dispatch:  # Manual trigger for demo
  push:
    branches: [main]
    paths:
      - next-prompt.md
```

### 3. Set up required secrets

- `GEMINI_API_KEY` - Gemini API key for authentication (free tier)

### 4. Configure agent

Uses Python script `agent.py` with Google Generative AI SDK

### 5. Test the loop

1. Write a simple task in `next-prompt.md`
2. Trigger the workflow manually
3. Verify Claude creates commits
4. Verify PR opens correctly
5. Merge PR to trigger next iteration

## Key Differences from `nightshift.yml`

| Aspect | `nightshift.yml` | `demo.yml` |
|--------|------------------|------------|
| Purpose | Production CI runner | Demo/prototype |
| Trigger | `next-prompt.md` on main | Manual + next-prompt.md |
| Naming | `ns/session/<timestamp>` | `demo/session/<timestamp>` |
| Scope | Full production use | Controlled demonstration |

## Expected Outcome

- Gemini agent works autonomously on tasks defined in `next-prompt.md`
- Each iteration produces a PR for review
- Merging PR advances the state machine
- Loop continues until `DONE` is written in `next-prompt.md`

---

# Nightshift Idle Mode Convention

## The Problem

When all planned tasks are complete, what should the agent do? Writing `DONE` stops the loop entirely, but there's often still valuable work to be done.

## The Solution: Idle Mode

Instead of writing `DONE`, the agent writes a special **idle task** to `next-prompt.md`. This keeps the loop running with lower-priority improvements.

## Idle Mode Triggers

- All planned tasks in a project plan are complete
- No explicit next task defined
- Agent has time/cycles available

## Recommended Idle Tasks by Project Type

| Project Type | Idle Mode Activities |
|-------------|---------------------|
| Software/Engineering | Security hardening, test coverage expansion, documentation improvements |
| Documentation | Grammar/spell review, clarity improvements, link validation |
| Infrastructure | Cost optimization, monitoring improvements, backup verification |
| Data/Scripts | Performance optimization, error handling improvements |

## Idle Mode Convention

### 1. Project declares completion criteria

When a project plan starts, define what "done" looks like AND what idle tasks are allowed.

### 2. Agent checks for open tasks

Before writing `DONE`, agent should check if idle mode is enabled for this project.

### 3. Agent writes idle task or DONE

```
# Option 1: No more work - stop completely
next-prompt.md → "DONE"

# Option 2: Idle mode enabled - continue with improvements  
next-prompt.md → "[IDLE] Spell check and grammar review"
```

### 4. Idle tasks marked with [IDLE] prefix

This helps humans understand the context when reviewing the PR.

---

# Demo Implementation

## Demo Idle Mode: Spell Check & Grammar Review

This demo implements idle mode using the nightshift `idle.md` convention.

### idle.md Location

Create `.nightshift/idle.md` in your repository:

```markdown
# Idle Mode Tasks

When there are no more planned tasks:

1. Spell check and grammar review on markdown files
2. Check for broken links
3. Verify code compiles without warnings
```

### How it works

1. Agent reads `next-prompt.md`
2. If task is `DONE` or empty → reads `.nightshift/idle.md`
3. Performs idle tasks (spell check)
4. Creates `SPELLCHECK_REVIEW.md` with suggestions
5. Writes next idle task or `DONE` to continue/stop loop

### Implementation

The `gemini-agent.sh` script checks for idle mode when task is DONE:
- Reads idle tasks from `.nightshift/idle.md` (if exists)
- Runs spell check on .md files
- Creates review file with suggestions
- Writes `[IDLE]` to `next-prompt.md` to continue loop

---

# How Claude Pro Users Can Make This Work

## API Key Setup

Claude Pro subscription does **not** automatically include API access. You need to:

1. **Create an Anthropic Developer Account** at [console.anthropic.com](https://console.anthropic.com)
   - This is separate from your regular Claude Pro chat account

2. **Generate an API Key**
   - Go to "API Keys" section in the console
   - Create a new API key with a descriptive name
   - **Save it immediately** - it only displays once

3. **Add Credits**
   - The API operates on pay-as-you-go model
   - Anthropic provides initial free credits for new accounts

## Using the API Key in GitHub Actions

### Option 1: Claude Code GitHub Action (Recommended)

Anthropic provides an official action: `anthropics/claude-code-action@v1`

```yaml
- name: Run Claude Code
  uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    # prompt: "Your task here"
```

### Option 2: Direct CLI with API Key

Install and run Claude Code directly:

```yaml
- name: Install Claude Code
  run: npm install -g @anthropic-ai/claude-code
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

- name: Run agent
  run: |
    HEAD_BEFORE=$(git rev-parse HEAD)
    claude --print < next-prompt.md
    # Verify commit was made
```

## Setting Up GitHub Secrets

1. Navigate to your repo → **Settings** → **Secrets and variables** → **Actions**
2. Add new secret:
   - Name: `ANTHROPIC_API_KEY`
   - Value: Your Anthropic API key from console.anthropic.com

## Required Permissions

- `contents: write` - to create branches and commits
- `pull-requests: write` - to open PRs
- `id-token: write` - if using OpenID Connect (optional, for cloud-native auth)

## Cost Considerations

- Claude API pricing is per-token (input + output)
- Claude Code CLI usage in CI counts toward API usage
- Monitor usage at console.anthropic.com/usage
- Start with small tasks to estimate costs before running large loops

## Claude Pro Includes API Usage

**Yes! Claude Pro ($20/month) includes ~$150 worth of API-equivalent usage.**

- Pro subscription (~ $20/month) includes ~$150 worth of API usage
- Max subscription ($100+/month) includes 5x-20x that amount
- This usage applies to Claude Code CLI when you authenticate with your subscription (not an API key)

### The Headless CI Problem

**Unfortunately, there's no way to avoid using `ANTHROPIC_API_KEY` in headless CI:**

- `claude --print` requires `ANTHROPIC_API_KEY` to be set
- The subscription login flow requires a browser (OAuth)
- No token-based auth exists for CI without an API key

### Workarounds

**Option 1: Use API key (simplest)**
- Generate API key at console.anthropic.com
- The $20 Pro subscription includes ~$150 API credit
- Use this for CI - it's "free" until you hit the limit

**Option 2: Use the Claude Code GitHub Action**
- `anthropics/claude-code-action@v1` handles authentication
- Still requires `ANTHROPIC_API_KEY` secret

**Option 3: Self-hosted runner with local auth**
- Run GitHub Actions on a machine where you've already run `claude login`
- Claude stores credentials in `~/.claude/auth.json`
- Pass this file to the runner (not recommended for security)

### Summary

| Method | Works in CI? | Notes |
|--------|-------------|-------|
| `claude login` (subscription) | No | Requires browser |
| `ANTHROPIC_API_KEY` | Yes | Required for headless |
| Cloud (Bedrock/Vertex) | Yes | Different models, different pricing |

**Bottom line**: For CI, you need an API key. The Pro subscription's $150 API credit makes this effectively free for reasonable use.

---

# Alternative AI Vendors with Free Tiers

If you want to avoid Anthropic entirely, here are AI coding agents with free tiers that work in CI:

## Top Picks for Free CI

### 1. Google Gemini Code Assist (Recommended)

- **Free** for individuals, no credit card required
- **6,000 code requests/day** - very generous
- Includes **Gemini CLI** - works like Claude Code
- Use in CI: `gemini chat` or API key from aistudio.google.com

```yaml
- name: Setup Gemini CLI
  run: npm install -g @google/gemini-cli
  
- name: Run agent
  run: gemini chat "your prompt" < task.md
```

### 2. GitHub Copilot (in CLI)

- Free tier: **2,000 code completions/month**, 50 chat messages/month
- **Copilot Coding Agent** uses GitHub Actions minutes
- Works in VS Code and CLI

```yaml
- name: Run Copilot Agent
  run: gh copilot suggest "your task"
```

### 3. Amazon Q Developer

- **Free** tier available
- CLI: `q chat` or `q ask`
- Good for AWS-integrated projects

### 4. Cody (Sourcegraph)

- **Free tier**: unlimited completions, 200 chat messages/month
- Great for code understanding and navigation
- CLI available: `cody chat`

### 5. Cline (Open Source)

- **Open source** AI coding agent
- Works with multiple LLM providers (OpenAI, Anthropic, local models)
- Free to self-host

### 6. Continue (Open Source)

- **Open source** VS Code / JetBrains extension
- Works with any LLM including free ones

## Comparison for Nightshift Demo

| Agent | Free Tier | CLI Available | Works in CI |
|-------|-----------|---------------|-------------|
| Gemini Code Assist | 6,000/day | Yes | Yes |
| GitHub Copilot | 2,000/mo | Yes (beta) | Yes |
| Amazon Q | Free | Yes | Yes |
| Cody (Sourcegraph) | 200 chat/mo | Yes | Yes |
| Cline | Open source | Yes | Yes |

## Recommendation

For the demo, **Gemini Code Assist** is the best choice:
- Generous free tier (6,000 requests/day)
- Works in headless CI via API key
- CLI available (`gemini` or via Google AI Studio)
- No subscription required

### Getting a Gemini API Key

1. Go to **[aistudio.google.com](https://aistudio.google.com)**
2. Sign in with your Google account
3. Click **"Get API key"** in the left sidebar
4. Create a new Google Cloud project (or use default)
5. Click **"Create API key"**
6. Copy the key - it only shows once!

The free tier is available at no cost with your personal Google account - no credit card required.

### Setting Up GitHub Secret

1. Navigate to your repo → **Settings** → **Secrets and variables** → **Actions**
2. Add new secret:
   - Name: `GEMINI_API_KEY`
   - Value: Your Gemini API key from aistudio.google.com

### Demo Files

- `.github/workflows/demo.yml` - GitHub Actions workflow
- `.nightshift/scripts/gemini-agent.sh` - Bash script agent (reads from stdin, calls Gemini API)
