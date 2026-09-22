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
| インストーラ | `install.sh` | `install.ps1` |
| HOME | `$HOME` | `$USERPROFILE` |
| シェル設定 | `.zshrc` / `.zshenv` | PowerShell profile |
| 依存 | `install-deps.sh` (brew/apt + mise) | `install-deps.ps1` (winget + mise) |
| symlink | シンボリックリンク | ディレクトリはJunction / ファイルはSymlink→HardLink |

WSLはLinux側のHOME（`$HOME`）へ展開されます。Windows側（PowerShellプロファイル等）へ
展開したい場合はネイティブPowerShellで `install.ps1` を実行してください。

## 構成

- `install.sh` — 各ファイルのsymlink作成（`.zshrc`, `.gitconfig`, nvim, bin, LLM skills など）
- `install-deps.sh` / `install-deps.ps1` — OS自動検出で依存インストール（brew / apt / winget）＋ mise で言語ランタイム
- `bootstrap.sh` — 上記を1コマンドで実行するエントリポイント
- `Brewfile` — macOS依存ソフトウェア一覧（カテゴリ別）
- `deps/versions.env` — 固定するツールのバージョンと SHA256（唯一の情報源）
- `deps/check.sh` / `deps/update.sh` — 依存ドリフト検知 / 固定版とロックの更新
- `config/mise/config.toml` — 言語ランタイム（python/node/go/ruby）のグローバル固定
- `vscode-extensions.txt` — VS Code拡張機能一覧（`install-deps.sh` が自動導入）
- `python/requirements-visualization.txt` — PyVista系ライブラリの入力（`.lock` が実際に導入される固定版）
- `skills/` — LLMスキル（opencode / Claude Code / Codex へ自動展開）。`memory-bank` に加え、Anthropic公式スキル（`docx` / `xlsx` / `pdf` / `skill-creator` / `frontend-design` / `mcp-builder`）を同梱
- `config/opencode/` — opencode のサブエージェント・コマンド・オーケストレーション手順（`AGENTS.md` = マルチAgent構成のメインAgent）
- `docs/dependency-policy.md` — 依存ソフトウェア管理の方針（層ごとの固定／追従）
- `docs/multi-agent-design.md` — マルチAgent構成の設計書（ルーター / パネル＋ジャッジ / 共有メッセージボックスのハイブリッド）
- `templates/` — プロジェクト雛形（`.envrc`, memory-bank, `task.json` など）

## 利用手順

1. 上記のワンライナーで展開
2. 新しいシェルを開いて反映

machine固有の設定は `.zshrc.local`（git管理外）に置く。

## 依存の更新

```bash
make deps-check    # 宣言と実インストールの差分を検知
make deps-update   # 固定版 (deps/versions.env) とロックを最新へ更新
```

方針は `docs/dependency-policy.md` を参照。言語ランタイムは mise
（`config/mise/config.toml`）で固定し、`pyenv` / `rbenv` / `nvm` は使用しない。
