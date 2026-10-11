# dotfiles リポジトリ構成の整理（scripts/ 集約・config 移動・repos 改名）

- date: 2026-10-11
- status: decided
- related: scripts/, config/powershell/, config/mise/config.toml, agent-skills/repos/, .gitmodules, agent-skills/manifest.toml, .gitignore, README.md, docs/dependency-policy.md
- method: organize-codebase-structure スキルの4問（発見容易性 / 除去容易性 / 公開境界 / 規則の反復）

## Context（背景）

ルートに HOME dotfiles・インストーラ・設定が混在し、新しいファイルの置き場が曖昧だった。
未使用ファイル（`lib/utils.sh`、`install.py`）と生成物（`__pycache__`）が残り、
`agent-skills/repos/` の名前も不統一だった。

## Decision（決定）

- 実行して環境を作るスクリプトを `scripts/` に集約。`bootstrap.sh` / `bootstrap.ps1`
  だけルート固定（raw URL one-liner の入口のため）。
  - `install.sh` / `install.ps1` / `install-deps.sh` / `install-deps.ps1` / `install.py`（→ `scripts/bin-tools.py`）
  - 各スクリプトのリポジトリルート解決を `scripts/` の親に修正
    （bash: `dirname/BASH_SOURCE/..`、PowerShell: `$PSScriptRoot` の親、Python: `Path(__file__).parent.parent`）
- PowerShell プロファイルを `config/powershell/Microsoft.PowerShell_profile.ps1` へ移動。
- 未使用の `lib/utils.sh` と `__pycache__/` を削除。`.gitignore` の旧 `skills/*` ブロックを削除。
- `agent-skills/repos/` の名前を配布元に統一:
  `custom-skills`→`custom`, `mattpocock-skills`→`mattpocock`,
  `caarlos0-dotfiles`→`caarlos0`, `ui-ux-pro-max-skill`→`ui-ux-pro-max`。
  `.gitmodules`・`manifest.toml`・README・install スクリプトの参照を更新。

## Verification（検証）

- `bash -n` で scripts/install.sh, scripts/install-deps.sh, agent-skills/install.sh, deps/check.sh, bootstrap.sh OK。
- `scripts/install-deps.sh --core --dry-run` が core 一覧を生成。Python は `py_compile` OK。
- サブモジュールは `git mv` + modules ディレクトリ改名 + gitfile 更新 + `.git/config` セクション改名 +
  `git submodule sync` で、`git submodule status` が 4 件とも正常（pinned commit 維持）。
- `~/.config/opencode/skills` の旧パスリンク 61 件を張り直し、壊れたリンク 0・競合 0・冪等を確認。

## 追加整理（同日 2 回目）

- 依存宣言を `deps/` に集約: `vscode-extensions.txt` → `deps/vscode-extensions.txt`、
  `python/requirements-visualization.{txt,lock}` → `deps/python/`。参照を
  `scripts/install-deps.{sh,ps1}`, `deps/update.sh`, `deps/check.sh`, README, Brewfile,
  `docs/dependency-policy.md` で更新。
- `bin/` のインストール不整合を修正。`install.sh` は `~/bin`（PATH 外）へリンクしており、
  `bin-tools.py` は `~/.local/bin`（PATH 済み）へ入れており不一致だった。`install.sh` の
  リンク先を `~/.local/bin` に統一し、`README*` とディレクトリを除外、旧 `~/bin` の
  自リポジトリリンクを掃除。`~/.local/bin` に `git-cleanup` を再リンク。
- 未参照だった `scripts/bin-tools.py` に入口を付与: `make bin-tools`。`ctx`(Go) をビルド、
  `new`(Python) をコピーして `~/.local/bin` へ導入できることを確認。
- `templates/` は「プロジェクトへコピーする雛形で dotfiles からは自動展開しない」旨を README に明記。

## Verification（追加分）

- `make bin-tools` で `~/.local/bin/ctx`（Go build, 4.4MB）と `new` を導入、`ctx --help` 動作確認。
- `install.sh` 再実行で旧 `~/bin` リンクを削除し `~/.local/bin` へ移行、`~/bin` は空になり削除。冪等。
- `bash -n`（install / install-deps / check / update / bootstrap）OK、`--core --dry-run` OK。

## 環境反映（macOS 実機）

- `make deps-core` を実行。jjui / zsh / WezTerm(cask) / opencode を導入、mise の4ランタイム
  （node/python/go/ruby）は導入済みを確認。
- opencode の重複を解消。既存の `opencode-v2`（anomalyco/tap）と homebrew-core の
  `opencode` がバイナリ競合したため、**homebrew-core の `opencode` に統一**。
  `opencode-v2` を削除し `anomalyco/tap` を untap（`opencode --version` = 2.0.25）。
  Windows の winget `SST.opencode` は別系統のため未整合（要確認）。
- `deps/update.sh` のバグを修正。`uv pip compile` は出力先が既存だと版を据え置くため、
  Python ロックが更新されなかった。`--upgrade` を付与し、`deps/python/requirements-visualization.lock`
  を再生成（charset-normalizer / cyclopts / fonttools / platformdirs / rich-rst / vtk が更新）。
  `make deps-check` が全 OK に。

## Open Questions（未解決の問い）

- `agent-skills` の buckets 構成（自作スキルは flat のまま。mattpocock は engineering/ 等で分類）。
- Windows winget の実機検証（別メモ）。`scripts/` 移行後の Windows 経路は未実機確認。
- `deps/check.sh` は `deps/python/requirements-visualization.lock` を「古い」と報告する
  （移行前から同じ内容で、uv 環境差による既存の同期ずれと思われる。要 `make deps-update` 判断）。
