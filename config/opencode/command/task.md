---
description: 新しいタスクを共有状態（.multiagent/）に登録し、初期化する。マルチAgent作業を開始するときに使う。Register a new task into the shared multiagent state.
agent: build
---

新しいタスクを共有状態に登録し、初期化してください。マルチAgent構成の設計に従います。

1. 概要: $ARGUMENTS（タスクの目的・範囲。空なら要約を依頼）。
2. 単独処理で足りるかをまず判断する。足りる場合は `.multiagent/` を作らず、その旨を伝える。
3. マルチAgentが必要なら:
   - `.multiagent/` ディレクトリを用意する。
   - `templates/task.json` の雛形を基に `tasks/<task_id>.json` を作る（task_id は `T-YYYYMMDD-NNN`）。
   - `registry.json` を初期化・更新する。
   - 必要なら `planner` エージェントに詳細なタスク分割・依存グラフ作成を委ねる。

$ARGUMENTS は短い場合、目的の明確化のために1〜2の質問をしてもよい。詳細は `docs/multi-agent-design.md` と
`config/opencode/AGENTS.md` を参照すること。
