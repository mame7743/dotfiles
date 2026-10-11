# private 集約スキルを一旦 dotfiles から除外

- date: 2026-10-11
- status: decided
- related: agent-skills/manifest.toml, .gitmodules, scripts/install.sh, agent-skills/README.md
- depends-on: 2026-10-11-memory-bank-public-repo

## Context（背景）

ワンライナー導入を認証なしで完結させたい一方、`mame7743/agent-skills`（private）は
認証が無い環境では取得できず、`design-dashboard` / `organize-codebase-structure` が
警告付きスキップになっていた。`memory-bank` は public 化済み。private 集約は
今すぐ必要ではないため、一旦 dotfiles に含めない方針とした。

## Decision（決定）

- submodule `agent-skills/repos/custom`（`mame7743/agent-skills`）を dotfiles から削除。
- `manifest.toml` から `design-dashboard` / `organize-codebase-structure` の
  `[[skills]]` を削除。
- 現在 dotfiles が持つ submodule は public のみ:
  `memory-bank` / `mattpocock` / `caarlos0` / `ui-ux-pro-max`。
- `scripts/install.sh` に、削除済み skill の旧リンク（`repos/custom/...` を指すもの）
  だけを掃除する処理を追加。任意の異なるリンクは従来通り触らない。
- 復帰手順は `agent-skills/README.md` の「一旦除外中のスキル」に記載。

## Verification（検証）

- 一時 HOME に旧リンク 3 件（design-dashboard / organize-codebase-structure / 旧 memory-bank）
  を作成 → `scripts/install.sh` で全て除去、memory-bank は public submodule へ再リンク。
- 実機: 旧リンク 2 件を除去し、既存リンク 59 件・競合 0 件。
- ワンライナー（別記録）: submodule は public 4 件のみ取得、スキップ 0 件。

## Revert（元に戻す）

- `git submodule add https://github.com/mame7743/agent-skills.git agent-skills/repos/custom`
  を再実行し、`manifest.toml` に該当 `[[skills]]` を戻す。
