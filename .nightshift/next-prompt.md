# Next Prompt

Replace this file with a self-contained prompt describing the very next action
the agent should take. This file is the trigger for the Nightshift runtime:
committing a change to this file starts a new agent session — locally via
loop.sh, or automatically via your CI system.

Every agent commit must also update this file with the prompt for the next task,
creating a self-advancing loop.

## Format

Write in second person, addressed to the agent picking up the next task:

- What was just completed (context)
- What to do next (the actual task)
- Any constraints, gotchas, or files to read first

## Example

Read `src/auth/jwt.ts`. Add a `refreshToken` endpoint at `POST /auth/refresh`
that accepts a valid refresh token (stored in an HTTP-only cookie), validates it
against the `refresh_tokens` table, and returns a new access JWT. The access
token TTL is 15 minutes. See `src/auth/login.ts` for the existing pattern.
