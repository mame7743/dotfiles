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
| 依存 | `install-deps.sh` (brew/apt) | `install-deps.ps1` (winget) |
| symlink | シンボリックリンク | ディレクトリはJunction / ファイルはSymlink→HardLink |

WSLはLinux側のHOME（`$HOME`）へ展開されます。Windows側（PowerShellプロファイル等）へ
展開したい場合はネイティブPowerShellで `install.ps1` を実行してください。

## 構成

- `install.sh` — 各ファイルのsymlink作成（`.zshrc`, `.gitconfig`, nvim, bin, LLM skills など）
- `install-deps.sh` / `install-deps.ps1` — OS自動検出で依存インストール（brew / apt / winget）
- `bootstrap.sh` — 上記を1コマンドで実行するエントリポイント
- `skills/` — LLMスキル（opencode / Claude Code / Codex へ自動展開）
- `config/opencode/` — opencodeのサブエージェント・コマンド
- `templates/` — プロジェクト雛形（`.envrc`, memory-bank など）

## 利用手順

1. 上記のワンライナーで展開
2. 新しいシェルを開いて反映

machine固有の設定は `.zshrc.local`（git管理外）に置く。