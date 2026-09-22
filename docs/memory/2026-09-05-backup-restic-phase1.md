# restic バックアップ Phase 1 の実装状態

- date: 2026-09-05
- status: decided
- related: `ansible/files/backup/backup.sh`, `ansible/files/backup/restore-test.sh`, `ansible/playbooks/backup/deploy-services.yml`, `.multiagent/artifacts/T-20260905-007/service-backup-plan.md`

## Context（背景）

Proxmox Backup Server への移行も比較したが、LXC の再構築を Ansible で管理しており、追加筐体なしで S3/B2 に保存できる restic 方式を継続することにした。

## Decision / Finding（決定・発見）

- バックアップ方式は **restic → S3/B2 のみ**。PBS と sanjo への二重保存は現時点で採用しない。
- `.env` は restic の暗号化バックアップに含め、秘密値のエスクローは 1Password でも行う。Pocket-ID の鍵と DB の整合性を優先する。
- 保持期間は `daily 7 / weekly 4 / monthly 6` を維持する。
- `backup.sh` に、サービス再起動後の Forgejo/Pocket-ID/Hermes の HTTP 状態を manifest に記録する post-health 検証を追加した。
- `restore-test.sh` を追加し、最新スナップショットを一時領域へ復元して各 `data.tar` のアーカイブ完全性を月次検証する構成にした。
- `backup-read-data.timer`（毎月1日）と `backup-restore-test.timer`（毎月第1土曜）を追加した。
- `ansible-playbook playbooks/backup/deploy-services.yml` を実行し、pve へ restic 0.18.0、runner、3つの systemd timer を反映済み。
- `/Users/atsushi/ansible/files/backup/backup.env` は権限を `0600` に修正し、pve の `/etc/backup.env` へ `0600 root:root` で配置済み。
- restic のランダムパスワードを 1Password の `Private/Proxmox Restic Repository` に保存済み。Ansible playbook 経由で pve の `/etc/backup/restic-password` に `0600 root:root` で配置済み。
- B2 の restic リポジトリを初期化し、初回バックアップを成功させた。約 1.439 GiB のスナップショットを保存。
- 実機検証で判明した `backup.sh` の環境変数 export 不足、`restore-test.sh` の `jq` 依存漏れ、非圧縮 tar に対する gzip 前提を修正・再デプロイした。
- 復元テストで homedata/git/infra/hermes の4アーカイブを復元・検証済み。`restic check --read-data` も27パック・全データ読み出しでエラーなし。
- 検証済み: `bash -n`、YAML パース、`ansible-playbook --syntax-check`、pve への playbook 実行成功、timer の enabled 状態。

## Open Questions（未解決の問い）

- Ansible リポジトリの未コミット変更は、内容確認後に別途コミット方針を決める。
- 次回以降は日次バックアップ、月次 `backup-read-data.timer`、月次 `backup-restore-test.timer` の自動実行を監視する。
