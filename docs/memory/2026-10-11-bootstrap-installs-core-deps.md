# bootstrap は既定で core 依存も導入する

- date: 2026-10-11
- status: decided
- related: bootstrap.sh, bootstrap.ps1, scripts/install-deps.sh, deps/core.txt, README.md
- depends-on: 2026-10-11-bootstrap-submodules, 2026-10-11-core-environment

## Context（背景）

新規PCで `curl ... bootstrap.sh | bash` を実行したところ、設定のリンクはされるが
アプリ（jj/jjui/wezterm/opencode 等）が入っておらず、別途 `--deps` / `--deps-core` が
必要だった。ワンライナー完結を優先し、既定で必要ソフトを導入する方針にした。

## Decision（決定）

- `bootstrap.sh`: 既定で `scripts/install-deps.sh --core` を実行（core プロファイル）。
  - `--no-deps` … リンクのみ（アプリを入れない）
  - `--deps` … フル導入（Brewfile 全部）
  - `--deps-core` … core（既定と同じ。後方互換のため維持）
- `bootstrap.ps1`: 既定で `install-deps.ps1` を実行。`-NoDeps` で無効化（`-Deps` は維持）。
- 依存導入に失敗したら、dotfiles のリンクは完了済みである旨を明示して `exit 1`。
- `scripts/install-deps.sh`: `--core` の Linux 未対応（`exit 1`）を解消。Linux は
  Brewfile が無いため core でも apt + 固定リリースのセットを導入する。
- `deps/core.txt` は macOS 用であることを明記（Linux は同スクリプトの apt 経路）。

## Verification（検証）

- `bash -n bootstrap.sh` / `scripts/install-deps.sh` OK。
- ワイヤリング: install-deps をスタブ化した一時クローンで確認。
  - 既定 → `install-deps.sh --core`
  - `--deps` → 引数なし（フル）
  - `--no-deps` → スキップ
  - 失敗時 → 日本語エラーと再実行コマンドを出して `exit 1`
- `scripts/install-deps.sh --core --dry-run` で brew 行を表示（実導入なし）。
- 実導入（`brew bundle install`）は実行していない。core は `deps/check.sh` で
  既に満たしていることを確認済み。

## Revert（元に戻す）

- `bootstrap.sh` / `bootstrap.ps1` の既定を依存なしに戻し、README を旧記載へ戻す。
