# bin/

自作ツール・スクリプトを置く場所。

インストール方法は2通りある。

- **単一ファイルのスクリプト** — `bin/` 直下に置くと `make install` が
  `~/.local/bin/<name>` へシンボリックリンクする（`.zshrc` で PATH 済み）。
- **ビルドが必要なツール / ディレクトリ型**（Go ソース、Python パッケージなど） —
  `scripts/bin-tools.py` がビルド・コピーする。`make bin-tools` で導入。

## スクリプトを追加する手順

1. ファイルを `bin/` に置く
2. 実行権限を付ける: `chmod +x bin/<script>`
3. `make install` を再実行してリンクを更新（新ファイルの場合）

ディレクトリ型のツールは `scripts/bin-tools.py` の `TOOLS` に追記し、
`make bin-tools` を実行する。

## 注意

- shebang (`#!/usr/bin/env bash` など) を必ず先頭に書く
- 拡張子なし推奨（`my-tool` は `my-tool.sh` より使いやすい）
- `README*` とディレクトリは `make install` のリンク対象外
