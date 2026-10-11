# bootstrap のサブモジュール自動初期化と欠落スキルのスキップ

- date: 2026-10-11
- status: decided
- related: bootstrap.sh, scripts/install.sh, agent-skills/install.sh, agent-skills/README.md
- depends-on: 2026-10-10-agent-skills-submodules

## Context（背景）

`curl .../bootstrap.sh | bash` のワンライナーで導入したのに、別PCで
「agent-skills: submodule 未初期化のためスキップ」と警告が出て、手動で
`git submodule update --init --recursive` が必要だった。ワンライナー完結を妨げていた。

## 調査結果（事実）

- `bootstrap.sh` は submodule を取得していなかった（リンクのみ実行）。
- `mame7743/agent-skills.git`（自作スキル、submodule `agent-skills/repos/custom`）は
  **非公開**。認証の無い環境では clone できない（他3つは public）。
- `git submodule update --init --recursive` は**1つ失敗すると全体を中断**するため、
  private の失敗で public 3つまで巻き添えで未取得になっていた。
- `agent-skills/install.sh` は「ソースディレクトリが無い」を**エラー**として扱い、
  1件でもあると**ファイルを変更せず全体を中断**していた（公開スキルも入らない）。

## Decision（決定）

1. `bootstrap.sh`: submodule を **パスごとに** `submodule update --init --recursive`
   する。1つ失敗しても他を巻き添えにせず、失敗パスをまとめて警告する
   （非公開は認証が必要、と案内）。
2. `agent-skills/install.sh`: ソース未取得は**警告してスキップ**（環境差であり
   設定ミスではないため中断しない）。取得できたスキルは導入する。
   `SKILL.md` 欠落・frontmatter `name` 不一致・導入先競合は**従来通りエラー**。
3. `scripts/install.sh`: 1つでも submodule が取得済みなら `agent-skills/install.sh`
   を実行。全て未取得なら従来通り**単一の警告**でスキップ（警告の氾濫を避ける）。
4. `bootstrap.sh` の未知引数処理が `warn` 定義前に `warn` を呼ぶ潜在バグを修正
   （ヘルパー定義を引数ループより前へ移動）。

## Verification（検証）

一時 HOME / 一時 clone で実施（実 HOME は変更していない）:

- CASE A（submodule 未初期化）: 単一の警告でスキップ。
- CASE B（public 3つ取得済み・private 未取得）: **58 件導入 / 3 件スキップ**
  （memory-bank, design-dashboard, organize-codebase-structure）。
- 失敗 submodule は `取得できなかった submodule: agent-skills/repos/custom` と表示。
- 実リポジトリ（全 submodule 取得済み）: `git submodule status` 正常、既存動作に影響なし。

## 残るリスク・前提

- private submodule は依然として認証が必要（`gh auth login` 等）。認証が無ければ
  自作3スキルは入らないが、公開スキルは導入される。
- Windows（`scripts/install.ps1`）は submodule を取得しない。別途
  `git submodule update --init --recursive` が必要（未検証）。

## Revert（元に戻す）

- `bootstrap.sh` の submodule ブロック、`agent-skills/install.sh` のスキップ分岐、
  `scripts/install.sh` のガードを元に戻す。
