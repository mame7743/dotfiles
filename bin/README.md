# bin/

自作ツール・スクリプトを置く場所。`install.sh` を実行すると `~/bin/` に自動でシンボリックリンクが張られ、PATH に追加されます。

## スクリプトを追加する手順

1. ファイルを `bin/` に置く
2. 実行権限を付ける: `chmod +x bin/<script>`
3. `make install` を再実行してリンクを更新（新ファイルの場合）

## 注意

- shebang (`#!/usr/bin/env bash` など) を必ず先頭に書く
- 拡張子なし推奨（`my-tool` は `my-tool.sh` より使いやすい）
