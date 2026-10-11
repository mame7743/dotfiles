# core 環境の再定義（日常ターミナル開発環境・端末・エージェント）

- date: 2026-10-11
- status: decided
- related: deps/core.txt, Brewfile, install-deps.sh, install-deps.ps1, install.sh, install.ps1, deps/versions.env, deps/check.sh, config/wezterm/wezterm.lua, docs/dependency-policy.md
- supersedes: 2026-10-10-core-apps

## Context（背景）

3つの目的を同時に満たしたい:

1. 日常のターミナル開発環境を少ない手間で再現する
2. インストール数・保守対象を最小化する
3. macOS / Linux / Windows（ネイティブ PowerShell）をできるだけ揃える

## Decision / Finding（決定・発見）

- `core` は「dotfiles が壊れない最小」ではなく、**日常のターミナル開発環境を
  再現するセット**とする。`deps/core.txt` が唯一の情報源（現状 macOS のみ）。
- 端末は **WezTerm**（ペイン分割・タブ。標準キーバインドを維持）。
  `tmux` は使用していないため導入・設定・リンクから削除。
- エージェントの永続実行は **Herdr** + **opencode**。Herdr は tmux 代替ではなく
  エージェント専用ランタイムと位置づける。
- `jj`（Jujutsu）を導入し、管理 TUI は **jjui**（lazygit は Git 用として残す）。
- Windows は **PowerShell 7 (pwsh) + WezTerm** を標準とする。
- `core` 導入時も **`mise install` を実行**し、言語ランタイムを揃える。
- `starship` / `zoxide` は現行の zsh / PowerShell 設定で有効化していないため対象外。

### core.txt（macOS / Homebrew）

- 追加: `jj`, `jjui`, `opencode`, `herdr`, `cask wezterm`
- 削除: `tmux`

### jjui の導入経路

- macOS: `brew install jjui`
- Windows: `winget install IbrahimDursun.jjui`
- Linux: `go install github.com/idursun/jjui/cmd/jjui@<固定版>`（`JJUI_VERSION="v0.10.11"`）

## Verification（検証）

- `bash -n` で install.sh / install-deps.sh / deps/check.sh / bootstrap.sh の構文 OK。
- `install-deps.sh --core --dry-run` が 23 formula + 1 cask（wezterm）を生成。
- `deps/check.sh` の core 検査が新リストを反映（jj=ok, jjui/wezterm/opencode=warn 等）。
- `deps/versions.env` に `JJUI_VERSION` を追加。`REQUIRED_KEYS` と Linux 版チェックに反映。
- リポジトリ内の tmux 参照は意図的な注記・履歴メモリ・外部 submodule のみ。
- 実インストール（brew bundle / winget）は未実行（dry-run のみ）。

## Open Questions（未解決の問い）

- `workstation` / `specialized` の3層プロファイルは未実装（core のみ）。
- OS別リストの単一マニフェスト化（重複排除）は将来対応。
- `core` の Linux / Windows 実装は未対応（`--core` は現状 macOS のみ）。
- Windows winget ID（`jj-vcs.jj`, `SST.opencode`, `Herdr.Herdr.Preview` 等）は
  実機での確認が必要。
- Linux 版 `jj` 本体は未導入（jjui のみ）。`jj` は配布バイナリ＋チェックサム固定が別途必要。
- WezTerm の Linux 導入は未実装（APT リポジトリ等）。
