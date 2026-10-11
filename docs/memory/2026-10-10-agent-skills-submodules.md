# Agent Skills を Git submodule で管理・配布する仕組み

- date: 2026-10-10
- status: decided
- related: agent-skills/, agent-skills/manifest.toml, agent-skills/install.sh, install.sh, install.ps1, .gitmodules, mame7743/agent-skills, docs/dependency-policy.md
- supersedes: 2026-10-10-agent-skills-mattpocock-caarlos0

## Context（背景）

前段で mattpocock/skills と caarlos0/dotfiles の全スキルを `skills/` にベンダリング
していたが、別 PC での再現性・バージョン固定・上流追従のため、配布元リポジトリ単位の
Git submodule 管理へ移行する要望。

## Decision / Finding（決定・発見）

- 配置は新規 `agent-skills/`（README / manifest.toml / install.sh / repos/）。
  ルート `install.sh` / `install.ps1` は `agent-skills/install.sh` を呼ぶだけにした。
- **外部スキルは配布元ごとの Git submodule**。登録済み:
  - `agent-skills/repos/mattpocock-skills` → mattpocock/skills（MIT, `49dd158d`）
  - `agent-skills/repos/caarlos0-dotfiles` → caarlos0/dotfiles（MIT, `892360f9`）
  - `agent-skills/repos/ui-ux-pro-max-skill` → nextlevelbuilder/ui-ux-pro-max-skill（MIT, `50d8a7de`）
  - `agent-skills/repos/custom-skills` → **自作** `mame7743/agent-skills`（private, `5a18b185`）
- **自作スキルは 1 リポジトリ**（`mame7743/agent-skills`）。新規作成し push 済み。
  分割は「可視性/ライセンス/所有者/独立配布」が変わる単位でのみ行う方針を README に明記。
- **`manifest.toml` が唯一の情報源**。`name`（= SKILL.md の name）/ `source`（dotfiles 相対）/
  `agents` を管理。現在は `opencode` のみ対象。全 61 スキルを明示列挙（自動全導入はしない）。
- **ライセンス非許諾分は削除**: `docx` / `xlsx` / `pdf`（Anthropic 独自ライセンスで派生・
  再配布禁止）、`web-design-guidelines`（上流ライセンス表記なし）、`skill-creator` /
  `frontend-design` / `mcp-builder`（方針により除外）。
- **名前衝突**: 両者に `code-review` があるため caarlos0 側のみ採用。mattpocock 側は
  原文を改変せず不採用（OpenCode は `name` == ディレクトリ名かつ全ロケーション一意を要求）。
- **翻訳**（独自変更）は後続タスク。変更時はフォーク（公開）または private パッチrepoを
  追加し、`manifest.toml` の `source` を切り替える。フォークは public 固定で private 不可、
  非公開にしたい場合はパッチrepo方式、という注意を README に明記。
- OpenCode の読込先を公式ドキュメントで確認:
  `~/.config/opencode/skills/<name>/SKILL.md`（他に `.claude` / `.agents` 互換）。
  推測パスは使っていない。

## 実装（install.sh の保証）

- `--dry-run` で作成予定・競合を確認でき、ファイルを変更しない。
- 検証と計画（フェーズ1）→ 作成（フェーズ2）の2段。設定/前提の問題は変更前に exit 2。
- 冪等（正しいリンクは何もしない）。競合（既存通常ファイル/ディレクトリ/異なるリンク）は
  上書きせず報告し exit 1。同じ導入先への複数割当は exit 2。
- カレントディレクトリ非依存、Git/submodule 操作なし、付属スクリプトを実行しない。

## Verification（検証）

- 実機: `~/.config/opencode/skills` に 61 リンク作成。再実行で「作成 0 / 既存 61 / 競合 0」。
- サンドボックス（一時dir）で確認:
  - dry-run はファイルを作らない。
  - 実作成・再実行（冪等）。
  - 既存通常ファイル競合 → exit 1、ファイル無変更。
  - 同名スキル2件 → exit 2、リンクを1つも作らない（2段化後）。
- OpenCode が 61 スキルを認識（ハーネスに反映）。
- `bash -n` / `/bin/bash -n`（3.2）で構文 OK。assoc array 等の bash4 依存なし。

## Open Questions（未解決の問い）

- 翻訳（一部和訳）の範囲と、フォーク（公開）/ private パッチの選択は未決。後続タスク。
- OpenCode 以外（Claude / Codex / .agents）の読込先対応は意図的に未実装。
- private submodule（自作）は clone 時に GitHub 認証が必要。
- submodule は repo 単位で1 commit 固定のため、自作スキルの個別 pin は不可。
