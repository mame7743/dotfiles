---
description: 現在の作業状態をこのプロジェクトのメモリバンクに保存する。Save the current work context to the project's memory bank.
agent: build
---

このプロジェクトのメモリバンクを現在の作業状態で更新してください。memory-bank スキルに従って:

1. 存在すれば `AGENTS.md` と `docs/memory/README.md` を読む。
2. `docs/memory/YYYY-MM-DD-<slug>.md` に日付付きエントリを追加する。
3. `README.md` の索引を更新する。
4. 破棄されたエントリは `status: superseded` にする。

$ARGUMENTS には記録したい短い要約を入れられる。メモリバンクがまだ存在しない場合は、
memory-bank スキルの templates/ から初期化する。