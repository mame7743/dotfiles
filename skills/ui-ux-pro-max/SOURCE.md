# Source / Provenance

- Upstream: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- Homepage: https://uupm.cc
- Installed with: `ui-ux-pro-max-cli@2.15.0` → `uipro init --ai opencode` (2026-10-07)
- Repo `main` at install time: `477bcb28c9812b385cb51a4605ddf30d7b2266e2` (2026-10-03)
- License: MIT (see `LICENSE`)

This directory is the self-contained `ui-ux-pro-max` skill produced by the official
installer. Only this skill was vendored; the CLI's other bundled skills
(`design`, `design-system`, `brand`, `ui-styling`, `banner-design`, `slides`)
were intentionally not added.

The `ui-ux-pro-max` skill is self-contained: `scripts/search.py` reads `data/`
relative to this directory. Requires Python 3 (standard library only).

## Update

```sh
tmp="$(mktemp -d)"; (cd "$tmp" && npx -y ui-ux-pro-max-cli@latest init --ai opencode)
# then copy "$tmp/.opencode/skills/ui-ux-pro-max/." over this directory
```
