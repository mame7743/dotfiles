# 依存ソフトウェア管理ポリシー（層ごとの固定／追従）

- date: 2026-09-22
- status: decided
- related: `docs/dependency-policy.md`, `deps/versions.env`, `config/mise/config.toml`,
  `install-deps.sh`, `install-deps.ps1`, `Makefile`

## Context

dotfiles の依存管理は層ごとにバラバラで、特に「実行環境」層が浮動だった。

- `Brewfile` はバージョン無指定（追従）
- `install-deps.sh` は `releases/latest` / `go install @latest` / `git clone`（master）で取得
- `python/requirements-visualization.txt` はピン無し
- `mise` は Brewfile にあるが未使用で、`pyenv` / `rbenv` / `nvm` と役割が重複
- ランタイムの版はどこにも宣言されていなかった

## Decision

依存を「基盤 / 実行環境 / 成果物」の3層に分け、固定度を使い分ける。

1. **基盤（OS / CLI）は追従**。各OSのパッケージマネージャに委譲し、差分は警告に留める。
2. **実行環境は固定**。言語ランタイムは mise に一本化し、CLI ツールは
   `deps/versions.env` で版と SHA256 を固定する。
3. **成果物は固定**。ロックファイルを必須とする。

唯一の情報源を宣言的ファイルに置き、スクリプト本文への直書きを禁止する。

## 変更ファイル

- 追加: `deps/versions.env`, `deps/check.sh`, `deps/update.sh`,
  `config/mise/config.toml`, `python/requirements-visualization.lock`,
  `docs/dependency-policy.md`
- 変更: `install-deps.sh`, `install-deps.ps1`, `install.sh`, `Brewfile`,
  `.zshrc`, `Makefile`, `README.md`
- 変更（副次）: `install-deps.sh` の macOS が Linux ブロックへ落下する既存バグを修正

## 主な内容

- `install-deps.sh`: `@latest` / `releases/latest` を廃止し、`deps/versions.env` を
  source して固定URL + SHA256 検証で取得。`pyenv` / `rbenv` を削除し `mise install` を追加。
- `.zshrc`: `pyenv init` / `rbenv init` / nvm を削除し `mise activate zsh` に統一。
  併せて存在しない Intel パスを指していた `LDFLAGS` / `CPPFLAGS` / `PKG_CONFIG_PATH`
  （zlib）を削除（ruby ビルドを阻害していた）。
- `config/mise/config.toml`: `node 26.8.1` / `python 3.11.4` / `go 1.27.1` / `ruby 3.2.0`
  を固定。python-build-standalone は attestations を発行しないため
  `python.github_attestations = false`（SHA256 検証は有効のまま）。
- Python 可視化は `.txt`（人手）→ `uv pip compile` → `.lock`（固定）を導入。
- `make deps-check`（ドリフト検知）と `make deps-update`（版・ロック更新）を追加。

## 検証

- `bash -n` / `zsh -n` で構文確認。
- `mise install` で4ランタイムを導入し、新しい対話シェルで
  `python` / `node` / `go` / `ruby` が mise 管理下で解決することを確認。
- `make deps-check` が成功（`mise` ランタイム、Python ロック同期 OK。
  `Brewfile` の未反映依存は警告表示）。
- `install-deps.sh` の macOS 経路を `brew` / `code` / `uv` スタブで実行し、
  共通セクションまで到達することを確認。

## 未対応 / 注意

- 旧 `pyenv`（3.10.12 / 3.11.4）・`rbenv`（3.2.0）・`nvm`（22.x）の実体と
  `~/.pyenv` / `~/.rbenv` / `~/.nvm` は残置。不要なら手動削除。
- `Brewfile` と現マシンの差分（`jupyterlab` / `docker` / `obsidian` / `paraview` /
  `python` / `pyright` など未反映）は既知。`make deps` 実行で同期される。
- Linux / Windows の実機検証は未実施（スクリプトの構文確認と経路確認のみ）。
- ruby 3.2.0 は EOL。上げる場合は `config/mise/config.toml` を編集して `mise install`。
