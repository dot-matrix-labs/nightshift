# Nightshift Idle Mode

When all planned tasks are complete, the agent should check for an `idle.md` file in the nightshift installation directory. This file defines what work to do when the main task queue is empty.

## Idle Mode Behavior

1. Agent reads `next-prompt.md`
2. If task is `DONE` or empty → check for `idle.md`
3. If `idle.md` exists → perform those tasks
4. After idle task → write next idle task or `DONE` to `next-prompt.md`

## Idle Task Format

Idle tasks follow the same format as regular tasks. They are marked with `[IDLE]` prefix in `next-prompt.md`:

```
[IDLE] Spell check and grammar review
```

## Example idle.md

```markdown
# Idle Mode Tasks

When there are no more planned tasks, the agent should:

## High Priority
- Security hardening: review code for security vulnerabilities
- Test coverage: expand test coverage where below 80%

## Medium Priority  
- Documentation: improve README, add code comments
- Code quality: fix linting warnings, improve naming

## Low Priority
- Spell check: review markdown files for typos
- Dependency updates: check for outdated packages
```

## Creating idle.md

Users should create `.nightshift/idle.md` in their repository with project-specific idle tasks.
