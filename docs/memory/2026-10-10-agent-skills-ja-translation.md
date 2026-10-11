# Agent Skills の一部和訳（公開フォーク運用）

- date: 2026-10-10
- status: decided
- related: agent-skills/README.md, agent-skills/repos/mattpocock-skills, agent-skills/repos/caarlos0-dotfiles, .gitmodules
- depends-on: 2026-10-10-agent-skills-submodules

## Context（背景）

submodule 管理へ移行後、スキルの「一部和訳」を実施。方針は前段の決定に従い、
独自変更は**公開フォーク**に載せ、`manifest.toml` の `source` はパス不変のまま
submodule の URL と参照commitをフォークへ切り替える。

## Decision / Finding（決定・発見）

- 対象（約10件）: 以下 10 スキルを選定。
  - mattpocock: `ask-matt` / `codebase-design` / `diagnosing-bugs` / `domain-modeling` / `tdd`
  - caarlos0: `code-review` / `writing-tests` / `cli-design` / `tui-design` / `code-simplifier`
  - 自作 `memory-bank` は既に日本語のため対象外（`code-simplifier` で代替）。
- 深さ: **frontmatter `description` と markdown 見出しのみ**を日本語化。本文は英語のまま
  （差分を小さくし、上流追従を容易にするため）。
- 置き場所: **公開フォーク**。`gh repo fork --fork-name` で作成。
  - `mattpocock/skills` → `mame7743/agent-skills-mattpocock`
  - `caarlos0/dotfiles` → `mame7743/agent-skills-caarlos0`（名前衝突回避のため改名）
- ブランチ運用: フォークの `main` は上流ミラーのまま。変更は **`ja` ブランチ**に積み、
  submodule は `ja` の commit を指す。上流更新時は `main` を取り込み `ja` を rebase。
- submodule URL を `.gitmodules` ごとフォークへ変更（gitlink も更新）:
  - mattpocock: `2d1d95bd033cd506d30d17744ac27db7e6b66238`
  - caarlos0: `ab18edb8e97a4a5d7d95fc80c7385f265822399d`
- ライセンス: 両者とも MIT。著作権表示は維持（`description`/見出し以外は未改変）。

## Verification（検証）

- フォーク2つが public の fork として存在し、`ja` ブランチに翻訳 commit を push 済み。
- `.gitmodules` の URL が両フォークを指し、`git submodule status` が `ja` の commit を表示。
- OpenCode のスキル一覧で、対象10件の `description` が日本語に更新されたことを確認。
- `install.sh` はパス不変のため再リンク不要（symlink は submodule 内の更新されたファイルを
  そのまま参照）。`--dry-run` で競合0を確認。

## Note / 落とし穴

- zsh では `path` が `PATH` と連動する特殊パラメータ。関数内で `local path=...` とすると
  `PATH` を壊し `git: command not found` になる。変数名に `path` を使わない。

## Open Questions（未解決の問い）

- 残り約51スキルの和訳をどう進めるか（同一手順で追加可能）。
- 上流が大きく変わった際の `ja` rebase 運用は未実施（手順のみ README に記載）。
- フォークは public 固定。非公開にしたくなった場合は private パッチrepo方式へ切替が必要。
