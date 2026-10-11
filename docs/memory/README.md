# メモリ索引

> 永続的なクロスセッションのプロジェクトメモリ。
> 作業開始時はまずこれを読むこと。

## 現在の状態

Proxmox のバックアップ方式は PBS ではなく、既存の restic → S3/B2 方式を継続する。Phase 1 のバックアップ補強を Ansible リポジトリへ実装し、pve ホストへの反映、認証情報配置、初回バックアップ、復元テスト、実データ検証まで完了した。

## エントリ

| 日付 | Slug | 状態 | 概要 |
|------|------|------|------|
| 2026-09-05 | backup-restic-phase1 | decided | restic 継続、初回バックアップ・復元テスト・read-data 検証完了 |
| 2026-09-05 | obsidian-local-vaults | in-progress | `obsidian-work` / `obsidian-home` の新規ローカルVaultを作成 |
| 2026-09-22 | opencode-v2-jev-judge | decided | OpenCode設定をV2ネイティブ化、Jev judgeプラグイン（jev_yesno/choice/score）を追加 |
| 2026-09-22 | ghq-repo-layout | decided | リポジトリをghq管理へ移行、`~/ansible` symlinkを廃止、`home-infra`へ改名、別名ホスト階層を正規化 |
| 2026-09-22 | dependency-management | decided | 依存を3層に分類し層ごとに固定／追従。mise一本化・SHA256固定・ロック・deps-check導入 |
| 2026-10-07 | ui-skills | decided | UI/UXスキル追加（ui-ux-pro-max / web-design-guidelines / design-dashboard、frontend-designは既存） |
| 2026-10-10 | agent-skills-mattpocock-caarlos0 | superseded | 旧: 全58スキルをskills/へvendoring（agent-skills-submodules に置換） |
| 2026-10-10 | agent-skills-submodules | decided | Agent Skillsを配布元ごとのGit submoduleで管理、自作はmame7743/agent-skills、manifestで明示選択 |
| 2026-10-10 | agent-skills-ja-translation | decided | 主要10スキルのdescription＋見出しを和訳、公開フォークのjaブランチへpushしsubmodule参照を切替 |
| 2026-10-10 | core-apps | superseded | 旧: deps/core.txt を定義（2026-10-11-core-environment に置換） |
| 2026-10-11 | core-environment | decided | core を日常ターミナル開発環境として再定義。WezTerm 採用・tmux 廃止・jj/jjui/opencode/herdr 追加・core でも mise install |
| 2026-10-11 | repo-structure | decided | インストーラを scripts/ へ、PowerShell プロファイルを config/ へ、依存宣言を deps/ へ集約。bin/ を ~/.local/bin に統一し make bin-tools を追加。agent-skills/repos を配布元名に統一 |

## 規約

- 新規エントリ: `YYYY-MM-DD-<slug>.md`
- 破棄されたエントリは `status: superseded` にし、置換先をリンクする。
