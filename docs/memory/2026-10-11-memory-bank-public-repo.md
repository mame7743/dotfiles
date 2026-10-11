# memory-bank を公開の独立リポジトリへ移管

- date: 2026-10-11
- status: decided
- related: agent-skills/manifest.toml, .gitmodules, scripts/install.sh, agent-skills/README.md
- supersedes-part-of: 2026-10-10-agent-skills-submodules（「自作スキルは1 repo に集約」の部分）

## Context（背景）

`memory-bank` は汎用性が高く、他者にも使えるスキルだったが、private な
`mame7743/agent-skills` に同居していたため、認証なしの環境では取得できなかった。
一方 `design-dashboard` / `organize-codebase-structure` は当面 private でよい。
可視性が異なるものを1つの submodule に混在させない方がよい。

## Decision（決定）

- `memory-bank` を **public な独立リポジトリ** `mame7743/memory-bank`（MIT）へ移管。
  - リポジトリ直下に `SKILL.md`、`templates/`、`LICENSE`、`README.md`。
  - 初回コミット `638496d`。
- private `mame7743/agent-skills` から `memory-bank` を削除（`091c53c`）。
  README に「公開可能なスキルは個別リポジトリ」と明記。
- dotfiles 側:
  - submodule `agent-skills/repos/memory-bank` を追加（public）。
  - `manifest.toml` の `memory-bank` の `source` を新 submodule へ変更。
  - 配布リポジトリの分割基準を「可視性・配布単位が変わるか」で明文化。
- `scripts/install.sh` に**既知の旧リンクだけ**を安全に張り替える移行処理を追加。
  旧 `repos/custom/skills/memory-bank` を指す symlink のみ削除して新 submodule へ再リンクする。
  それ以外の異なるリンクは従来通り競合として保護する。

## Verification（検証）

- public 確認: 認証なし（credential.helper 無効）で `ls-remote` 成功。
- 移行処理: 一時 HOME に旧リンクを作成 → `scripts/install.sh` 実行で
  「Removed migrated legacy link」後に新 submodule へ再リンク。
- bootstrap: 一時 HOME でワンライナー実行（別途記録）→ 公開分 59 件導入（memory-bank を含む）。

## 残るリスク・前提

- `mame7743/memory-bank` は public のため、内容に秘密情報を入れない運用を守る。
- private の `design-dashboard` / `organize-codebase-structure` は引き続き認証が必要。

## Revert（元に戻す）

- 新 submodule を削除し、`manifest.toml` の `source` を `repos/custom/...` へ戻し、
  private リポジトリへ `memory-bank` を復元する。
