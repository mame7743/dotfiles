# Obsidian Vault のローカル展開

- date: 2026-09-05
- status: in-progress
- related: `~/Documents/Obsidian/obsidian-work`, `~/Documents/Obsidian/obsidian-home`

## Context

Homeserver の CouchDB にある `obsidian-work` と `obsidian-home` を、macOS のローカル Obsidian で新規展開する。

## Decision / Finding

- 新規ローカルVaultの配置先は `~/Documents/Obsidian/obsidian-work` と `~/Documents/Obsidian/obsidian-home` とする。
- 既存の `~/valult` と `~/Documents/my_valult` は削除・移動せず、退避元として残す。
- 各新規Vaultには Self-hosted LiveSync プラグイン本体を配置済み。
- LiveSync の接続情報・認証情報は新規Vaultへ流用しない。各Vaultで対応するDB名を明示して設定する。
- `obsidian-work` は既存のLiveSync設定を新規Vaultへ移し、Homeserverからの初回取得を確認した。

## Open Questions

- `obsidian-home` は初回同期ログ・ノート取得を確認できていない。Obsidian上で `obsidian-home` DBの接続先を再確認する必要がある。
