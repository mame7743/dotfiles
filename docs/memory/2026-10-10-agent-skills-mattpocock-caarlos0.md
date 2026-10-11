# mattpocock / caarlos0 のAgent skills追加

- date: 2026-10-10
- status: superseded
- superseded-by: 2026-10-10-agent-skills-submodules
- related: skills/, skills/README.md, install.sh, install.ps1, README.md

## Context（背景）

「Matt Pocock と caarlos0 のAgent skillsを追加したい」という要望。
対象は次の2リポジトリのスキル集:

| 提供元 | リポジトリ | 内容 |
|---|---|---|
| Matt Pocock | `mattpocock/skills` | "Skills for Real Engineers"（engineering 20 / productivity 7 / in-progress 7 / misc 4） |
| caarlos0 | `caarlos0/dotfiles` の `skills/` | Go/Rust/TS/Python 性能、CLI/TUI/dashboard 設計、code review、gh-cli など20スキル |

## Decision / Finding（決定・発見）

- **全スキルを flat にベンダリング**。方針はユーザーが選択:
  「Both collections, complete」＋「Flat, prefix only collisions」。
- 取得: 上流 `main` のtarballを展開し、スキルディレクトリを `skills/<name>/` へコピー。
  - mattpocock: 38スキル（各バケット直下の `README.md` 索引は除外）
  - caarlos0: 20スキル
  - 合計58スキルを追加（既存11 + 58 = 69スキル）。
- **衝突の解決**: 両リポジトリに `code-review` が存在。
  - mattpocock 側 → `pocock-code-review`
  - caarlos0 側 → `caarlos0-code-review`
  - `SKILL.md` の frontmatter `name:` を改名し、スキル内の相互参照
    （`ask-matt` / `implement` / `implement-spec` / `tdd` と caarlos0 の
    `go-performance` 等7ファイル）も新名に更新した。
  - 未改名のまま参照が残っていないことをgrepで確認（bare `code-review` は0件）。
- 全69スキルでディレクトリ名と frontmatter `name:` の一致を検証済み。
- **来歴**: `skills/README.md` に上流URL・commit SHA（mattpocock
  `49dd158d…`, caarlos0 `892360f9…`, いずれも 2026-10-09）・ライセンス・
  改名内容・更新手順を記録。MITのライセンス全文を
  `skills/LICENSE-mattpocock.txt` / `skills/LICENSE-caarlos0.txt` に同梱。
- 配布は既存方式のまま（`skills/*` を flat に各エージェントのskillsディレクトリへ
  symlink）。`skills/README.md` と `LICENSE-*.txt` はファイルなので install 対象外。

## Open Questions（未解決の問い）

- 58スキル追加により、各エージェント起動時に読み込まれるスキル説明が大幅に増える
  （トークン・トリガー競合の懸念）。不要なものは今後削る可能性がある。
- mattpocock の `setup-matt-pocock-skills` はリポジトリ単位で `docs/agents/` 等の
  設定ファイルを生成する前提のスキル。グローバル配置のままで良いかは未検証。
- 上流更新への追従は手動（`skills/README.md` の手順）。定期更新の仕組みは無い。
