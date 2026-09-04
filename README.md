# dotfiles

My dotfiles.

## ワンライナーインストール

```bash
curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash
```

依存パッケージもまとめて入れたい場合:

```bash
curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash -s -- --deps
```

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