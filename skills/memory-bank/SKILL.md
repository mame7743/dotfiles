---
name: memory-bank
description: プロジェクトの永続メモリ（メモリバンク）。作業開始・再開時、コンテキストや決定事項を保存/更新/記録してほしいとき、重要なアーキテクチャ判断をしたときに使う。AGENTS.md と docs/memory/ を管理する。Use when starting/resuming work, or when the user asks to save/update memory.
---

# メモリバンク（Memory Bank）

プロジェクトの永続的なクロスセッションメモリ。ファイルの作成・変更を伴うため、
ユーザーが明示的に記録を依頼していない限り、ファイル作成前に確認すること。

## 構成

- `AGENTS.md` — プロジェクトの指示 + メモリエントリの索引
- `docs/memory/` — 日付付きの記録
  - `README.md` — 目次 / 索引
  - `YYYY-MM-DD-<slug>.md` — エントリ1件 = 1ファイル

## いつ書くか

- **初期化**: `templates/`（このスキル内）をプロジェクト直下にコピーする
- **依頼時**: ユーザーが「保存して」「記録して」「メモして」「update memory」と言ったとき
- **重要な決定 / アーキテクチャ変更**: まずユーザーに確認する

## エントリの形式

```markdown
# <タイトル>

- date: YYYY-MM-DD
- status: draft | decided | superseded
- related: <パスやエントリのslug>

## Context（背景）

なぜこれが存在するのか。

## Decision / Finding（決定・発見）

## Open Questions（未解決の問い）
```

## プロトコル

1. メモリが存在する場合、まず `AGENTS.md` と `docs/memory/README.md` を読む。
2. 新規エントリは `docs/memory/YYYY-MM-DD-<slug>.md` として追加する。
3. エントリを追加したら `README.md` の索引も更新する。
4. 決定が破棄・置換された場合、古いエントリを `status: superseded` にし、新しいものをリンクする。
5. エントリは短く事実ベースで書く — 長文より箇条書き。