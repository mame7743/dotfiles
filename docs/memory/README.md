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

## 規約

- 新規エントリ: `YYYY-MM-DD-<slug>.md`
- 破棄されたエントリは `status: superseded` にし、置換先をリンクする。
