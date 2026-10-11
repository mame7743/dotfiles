# dotfiles

My dotfiles.

## ワンライナーインストール

### macOS / Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash
```

依存パッケージもまとめて入れたい場合:

```bash
curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash -s -- --deps
```

### Windows (PowerShell)

```powershell
Set-ExecutionPolicy -Scope Process Bypass
irm https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.ps1 | iex
```

依存パッケージもまとめて入れる場合（`-Deps` 付き）:

```powershell
iwr https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.ps1 -OutFile $env:TEMP\bootstrap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\bootstrap.ps1 -Deps
```

### プラットフォーム別の展開先

| 項目 | macOS / Linux / WSL | Windows |
|---|---|---|
| インストーラ | `scripts/install.sh` | `scripts/install.ps1` |
| HOME | `$HOME` | `$USERPROFILE` |
| シェル設定 | `.zshrc` / `.zshenv` | `config/powershell/Microsoft.PowerShell_profile.ps1` |
| 依存 | `scripts/install-deps.sh` (brew/apt + mise) | `scripts/install-deps.ps1` (winget + mise) |
| symlink | シンボリックリンク | ディレクトリはJunction / ファイルはSymlink→HardLink |

WSLはLinux側のHOME（`$HOME`）へ展開されます。Windows側（PowerShellプロファイル等）へ
展開したい場合はネイティブPowerShellで `scripts/install.ps1` を実行してください。

## 構成

- `scripts/` — インストーラ群。`scripts/install.sh`（symlink作成 + `agent-skills/install.sh` 呼び出し）、`scripts/install-deps.sh` / `scripts/install-deps.ps1`（OS自動検出で依存インストール）、`scripts/bin-tools.py`（`bin/` のビルド型ツール導入、`make bin-tools`）
- `bootstrap.sh` / `bootstrap.ps1` — リポジトリ取得から上記インストーラ実行までを1コマンドで行う入口（ルート固定）
- `Brewfile` — macOS依存ソフトウェア一覧（カテゴリ別）
- `deps/versions.env` — 固定するツールのバージョンと SHA256（唯一の情報源）
- `deps/core.txt` — 日常のターミナル開発環境（core プロファイル）の唯一の情報源（`make deps-core`）
- `deps/check.sh` / `deps/update.sh` — 依存ドリフト検知 / 固定版とロックの更新
- `config/mise/config.toml` — 言語ランタイム（python/node/go/ruby）のグローバル固定
- `config/wezterm/wezterm.lua` — 端末・ペイン分割（WezTerm）の共通設定。標準キーバインドを維持し、Windows のみ既定シェルを PowerShell 7 にする
- `deps/vscode-extensions.txt` — VS Code拡張機能一覧（`scripts/install-deps.sh` が自動導入）
- `deps/python/requirements-visualization.txt` — PyVista系ライブラリの入力（`.lock` が実際に導入される固定版）
- `agent-skills/` — エージェントスキルの宣言的導入。`manifest.toml` が「識別名 / dotfilesからの相対ソース / 導入先Agent」を管理し、`install.sh` が選択したスキルだけを対象Agent（現在はOpenCode）の読込先へ symlink する。外部スキルは配布元リポジトリをGit submoduleで参照commitに固定し、自作・公開スキルは用途ごとのリポジトリで管理。詳細・更新手順は `agent-skills/README.md`
- `config/opencode/` — opencode のサブエージェント・コマンド・オーケストレーション手順（`AGENTS.md` = マルチAgent構成のメインAgent）
- `config/powershell/` — Windows PowerShell 7 のプロファイル
- `config/jjui/config.lua` — jjui の日本語操作メニュー。`m` で開き、選択コミット（`[選択]`）／`@`・全体（`[全体]`）の操作を日本語から選べる。jjui が同ディレクトリへ `types.lua` を生成するためファイル単位で symlink する
- `docs/dependency-policy.md` — 依存ソフトウェア管理の方針（層ごとの固定／追従）
- `docs/multi-agent-design.md` — マルチAgent構成の設計書（ルーター / パネル＋ジャッジ / 共有メッセージボックスのハイブリッド）
- `bin/` — 自作ツール。単一ファイルは `make install` で `~/.local/bin` へ、ビルド型（Go/Python など）は `make bin-tools` で導入
- `templates/` — プロジェクトにコピーして使う雛形（`envrc.example`, `obsidian-live-sync/`, `task.json`）。dotfiles からは自動展開しない

## 利用手順

1. 上記のワンライナーで展開
2. 新しいシェルを開いて反映

machine固有の設定は `.zshrc.local`（git管理外）に置く。

## 依存の更新

```bash
make deps-core     # 日常のターミナル開発環境を導入（macOS / deps/core.txt）
make deps-core-dry # 導入内容の確認（変更なし）
make deps-check    # 宣言と実インストールの差分を検知
make deps-update   # 固定版 (deps/versions.env) とロックを最新へ更新
```

方針は `docs/dependency-policy.md` を参照。言語ランタイムは mise
（`config/mise/config.toml`）で固定し、`pyenv` / `rbenv` / `nvm` は使用しない。
