---
description: Save the current work context to this project's memory bank.
agent: build
---

Update this project's memory bank with the current state of work. Follow the
memory-bank skill:

1. Read `AGENTS.md` and `docs/memory/README.md` if they exist.
2. Append a dated entry in `docs/memory/YYYY-MM-DD-<slug>.md`.
3. Update the `README.md` index.
4. Mark superseded entries `status: superseded`.

$ARGUMENTS may contain a short summary of what to record. If no memory bank
exists yet, bootstrap it from the memory-bank skill's templates.