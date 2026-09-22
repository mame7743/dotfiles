# 依存ソフトウェア管理ポリシー

- 対象: `dotfiles` リポジトリが管理する依存ソフトウェア全般
- 決定日: 2026-09-22
- 関連: `deps/versions.env`, `config/mise/config.toml`, `Brewfile`,
  `install-deps.sh`, `install-deps.ps1`, `Makefile`

## 基本原則

**依存は「なぜ持っているか」で層に分け、層ごとに固定度を使い分ける。**

| 層 | 例 | 固定度 | 情報源 |
|---|---|---|---|
| 基盤（OS / CLI） | `git` `ripgrep` `tmux` `docker` など | **追従** | `Brewfile` / apt / winget |
| 実行環境（ランタイム / ツール） | `python` `node` `go` `ruby`、`lazygit` `lua-language-server` `ghq` | **固定** | `config/mise/config.toml`, `deps/versions.env` |
| 成果物の依存 | Python / Node / Go ライブラリ、AI skills、nvim プラグイン | **固定** | 各ロックファイル |

理由:

- 基盤層は各 OS のパッケージマネージャが整合性を担保するため、固定するとかえって
  壊れやすい。常に追従させ、差分は警告として扱う。
- 実行環境層と成果物層はマシン間・時系列での再現性が要件になるため固定する。

**唯一の情報源 (single source of truth):** 依存は必ず宣言的ファイルに書き、
手順書やスクリプト本文へ直書きしない。

## 層ごとの詳細

### 1. 基盤（OS / CLI）

- macOS: `Brewfile`（`brew bundle --file=Brewfile`）
- Linux: `install-deps.sh` の apt リスト
- Windows: `install-deps.ps1` の winget リスト
- バージョンは固定しない。`make deps-check` は差分を**警告**として報告する
  （FAIL にはしない）。

### 2. 実行環境（ランタイム / ツール）

- 言語ランタイムは **mise に一本化**する。
  - グローバル: `config/mise/config.toml` → `~/.config/mise/config.toml`
  - プロジェクト固有: 各リポジトリの `.tool-versions` / `mise.toml` で上書き
  - 旧 `pyenv` / `rbenv` / `nvm` は廃止（`.zshrc` は `mise activate zsh` のみ）
- GitHub リリースや `go install` で入れる CLI ツールは `deps/versions.env` で固定し、
  GitHub リリースは **SHA256 を検証**する。
- `install-deps.sh` / `install-deps.ps1` は `@latest` や `releases/latest` を使わない。
  （`deps/update.sh` だけが「最新版を調べる」ためにこれらを参照する唯一の例外。）

### 3. 成果物の依存

| 対象 | ロック | 生成 |
|---|---|---|
| Python (可視化) | `python/requirements-visualization.lock` | `uv pip compile`（入力は `.txt`） |
| nvim プラグイン | `config/nvim/lazy-lock.json` | lazy.nvim |
| AI skills | `skills-lock.json`（`home-infra` 側） | skills 管理ツール |

## 運用コマンド

| コマンド | 内容 |
|---|---|
| `make deps` | 依存をインストール（OS 自動判定） |
| `make deps-check` | 宣言 vs 実インストールのドリフト検知（ハードゲート） |
| `make deps-update` | 固定版とロックを最新へ更新（コミットはしない） |

更新フロー:

1. `make deps-update` を実行
2. `deps/versions.env` と `*.lock` の差分を確認
3. `make deps-check` で整合を確認
4. コミットして PR にする

## 禁止事項

- スクリプトに `@latest` / `releases/latest` / バージョン未指定の取得を書かない。
- 依存を README やコメントにだけ書いて宣言ファイルへ反映しない。
- 秘密値・実 IP・トークンを `deps/` 以下のファイルへ書かない。

## 既知の例外

バージョン固定が難しいため、当面は例外として許容する（将来対応の候補）。

- `install_gibo`: gibo はバージョン付きリリース資産を持たないため
  `raw.githubusercontent.com/simonwhitaker/gibo/master/gibo` から取得する。
- `install_mise`（Linux）: mise 自身のブートストラップは公式の `https://mise.run | sh` を使う。
- `deps/update.sh`: 最新版を調べる目的で `releases/latest` / `@latest` を参照する唯一の例外。
