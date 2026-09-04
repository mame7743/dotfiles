---
name: memory-bank
description: Persistent project memory. Use when starting or resuming work in a project, when the user says to save/update/record context or decisions, or when a significant architecture decision is made. Manages AGENTS.md and docs/memory/.
---

# Memory Bank

Persistent, cross-session memory for a project. Writing to memory creates or
modifies files — ask the user before creating files unless they already asked
you to record something.

## Structure

- `AGENTS.md` — project instructions + index of memory entries
- `docs/memory/` — timestamped records
  - `README.md` — index / table of contents
  - `YYYY-MM-DD-<slug>.md` — one record per entry

## When to write

- **Bootstrap**: copy `templates/` (inside this skill) into the project root.
- **On request**: the user says "save", "記録して", "メモして", "update memory".
- **Significant decision / architecture change**: ask the user first.

## Record format

Each entry:

```markdown
# <Title>

- date: YYYY-MM-DD
- status: draft | decided | superseded
- related: <paths or entry slugs>

## Context

Why this exists.

## Decision / Finding

## Open Questions
```

## Protocol

1. Read `AGENTS.md` and `docs/memory/README.md` first when memory exists.
2. Add new entries as `docs/memory/YYYY-MM-DD-<slug>.md`.
3. Keep the `README.md` index up to date when adding entries.
4. When a decision is superseded, mark the old entry `status: superseded` and
   link the new one.
5. Keep entries short and factual — bullet lists over prose.