# agent-skills — エージェントスキルの宣言的導入

複数の Agent で使うスキルを dotfiles で一元管理し、別 PC でも同じスキル・同じ
バージョンを再現するための仕組み。

- **正本は Git submodule の参照commit**。README にバージョンを二重管理しない。
- スキル本体は**原文のまま**使う（`SKILL.md` と付属物を編集しない）。
- どのスキルを・どこから・どの Agent へ導入するかは `manifest.toml` で宣言する。
- 実際のリンク作成は `install.sh` が行う。**Git / submodule 操作は含まない**。

## 構成

```
agent-skills/
├── README.md          # この文書
├── manifest.toml      # 導入するスキルの宣言（唯一の情報源）
├── install.sh         # manifest に従って symlink を作成（--dry-run 対応）
└── repos/             # Git submodule
    ├── custom/                 # 自作スキル（mame7743/agent-skills, private）
    ├── mattpocock/             # mattpocock/skills
    ├── caarlos0/               # caarlos0/dotfiles
    └── ui-ux-pro-max/          # nextlevelbuilder/ui-ux-pro-max-skill
```

`install.sh` は [OpenCode の公式仕様](https://opencode.ai/docs/skills/) に合わせ、
`~/.config/opencode/skills/<name>/SKILL.md` へリンクする。OpenCode では
**frontmatter `name` がディレクトリ名と一致**し、**全ロケーションで一意**でなければ
ならないため、`manifest.toml` の `name` は SKILL.md の `name` と一致させる。

## manifest.toml の書き方

```toml
[agents]
opencode = "~/.config/opencode/skills"   # 導入先 Agent と読込先（~ 展開対応）

[[skills]]
name   = "tdd"                            # 識別名 = SKILL.md の name
source = "agent-skills/repos/mattpocock/skills/engineering/tdd"
agents = ["opencode"]                     # [agents] のキー
```

- `source` は **dotfiles ルートからの相対パス**（その直下に `SKILL.md`）。
- 同じ導入先 (`agent` × `name`) を複数スキルへ割り当てると `install.sh` がエラーにする。
- 未使用 Agent 向けの定義・処理は追加しない（現在は `opencode` のみ）。

## 導入

通常はリポジトリ直下の `bootstrap.sh` が submodule の取得と導入まで自動で行う。手動で行う場合:

```bash
# 1) submodule を含めて取得（初回）
git clone --recurse-submodules https://github.com/mame7743/dotfiles.git
git -C dotfiles submodule update --init --recursive

# 2) 何が作られるか・競合がないかを確認（ファイルは変更しない）
dotfiles/agent-skills/install.sh --dry-run

# 3) 導入
dotfiles/agent-skills/install.sh
```

`install.sh` の約束:

- カレントディレクトリに依存しない。`--dotfiles` でルートを上書き可能。
- 正しいリンクが既にあれば何もしない（冪等）。同じ設定で再実行しても安全。
- 既存の通常ファイル・ディレクトリ・異なるリンクは**上書きせず競合として報告**し、
  終了コード 1 を返す。
- `source` に `SKILL.md` があること、frontmatter `name` が識別名と一致することを検証する。
- `source` が未取得（private submodule の未認証など）のスキルは**警告してスキップ**し、
  取得できたスキルは導入する。環境差であり設定ミスではないため、ここでは中断しない。
- **外部スキルの付属スクリプトは実行しない**（symlink のみ）。

ルートの `scripts/install.sh` / `scripts/install.ps1` はこのスクリプトを呼び出す。`bootstrap.sh` は
取得時に submodule を**パスごとに**初期化し、1つ失敗しても他を巻き添えにしない。private submodule
（`mame7743/agent-skills`）は認証が無い環境では取得できず、そのスキルは警告付きでスキップされる。
OpenCode 以外（`~/.claude/skills` 等）へは現状リンクしない。

## 配布リポジトリの分け方

分割の基準は「内容の違い」ではなく **配布単位が変わるか**。

- **外部スキル**: 配布元リポジトリ単位で submodule にする。
  - 独自変更しないものは**配布元を直接参照**する。
  - 独自変更するものは**自分のフォーク（またはパッチrepo）を参照**する。
- **自作スキル**: 1リポジトリ（`mame7743/agent-skills`）にまとめる。単一作者・上流なしの
  ため、スキル単位に分割しない。次のいずれかに該当したら、そのスキルだけ独立repoへ切り出す:
  可視性が違う（公開したい）／ライセンスや所有者が違う／外部に独立配布する／独立に
  バージョン固定したい。
- 1つの submodule は repo 単位で1 commit を固定する。自作を1本にまとめる場合、
  スキルごとの個別 pin はできない（通常は問題にならない）。

### 公開フォークと private パッチの使い分け

- **公開でよければ**: 配布元をフォーク（`gh repo fork <upstream> --fork-name <name>`）し、
  翻訳などの変更を commit して submodule をフォークへ切り替える。フォークは public 固定で
  private にできない。
- **非公開にしたい場合**: フォークではなく、変更したスキルだけを入れた private な
  パッチrepoを作り、未変更スキルは upstream、変更スキルだけパッチrepoから選ぶ
  （1配布元＝2 submodule）。`manifest.toml` はスキルごとに `source` を持つので表現できる。
- **ブランチ運用**: フォークの `main` は上流のミラーとして保ち、翻訳などの変更は
  `ja` ブランチに積む（submodule は `ja` の commit を指す）。上流更新時は `main` を
  取り込み、`ja` を rebase してから submodule の参照を更新する。

## 更新運用

```bash
# 1) submodule を含めて取得
git clone --recurse-submodules https://github.com/mame7743/dotfiles.git

# 2) 既存 clone で submodule を初期化・取得
git submodule update --init --recursive

# 3) スキルの追加・選択・導入
#    manifest.toml に [[skills]] を追記 → ./agent-skills/install.sh --dry-run →
#    ./agent-skills/install.sh

# 4) 配布元を直接参照するスキルの更新（例: mattpocock）
git -C agent-skills/repos/mattpocock fetch origin
git -C agent-skills/repos/mattpocock log --oneline HEAD..origin/main
git -C agent-skills/repos/mattpocock checkout <new-commit>
# ※ 最新へ自動追従はしない。必要なものだけ手動で進める。

# 5) フォークへの上流更新の取り込み（フォーク運用の場合）
#    GitHub の "Sync fork" などでフォークを上流へ追従させ、そのうえで作業ブランチに
#    翻訳/変更を載せる。フォーク側 repo で commit・push する。

# 6) 更新内容の確認と dotfiles 側の参照commitの記録
git -C agent-skills/repos/<repo> checkout <commit>
git add agent-skills/repos/<repo>     # gitlink を更新
git diff --cached agent-skills/repos/<repo>

# 7) 過去の commit への切り戻し
git -C agent-skills/repos/<repo> checkout <old-commit>
git add agent-skills/repos/<repo>
```

submodule 内で独自編集する場合は、**作業ブランチで編集 → フォークへ commit・push →
dotfiles 側の参照を更新**する。**未 commit の変更を破棄する操作はしない**。

## 採用するスキルと出所

固定commitは Git submodule が正本（下記の commit は初回登録時点の参考値）。

### 自作スキル: `mame7743/agent-skills`（private）

- 用途: 自分で作成・所有するスキル。
- 元の配布元URL: なし（自作）。
- フォークURL: なし（自リポジトリ）。
- 採用スキル: `memory-bank`, `design-dashboard`, `organize-codebase-structure`
- 独自変更の概要: 自作のため該当なし。編集はこの repo へ commit・push する。

### `mattpocock/skills`（MIT）

- 用途: エンジニアリング／プロダクティビティ系のスキル。
- 元の配布元URL: https://github.com/mattpocock/skills
- フォークURL: https://github.com/mame7743/agent-skills-mattpocock（翻訳は branch `ja`）
- 採用スキル: `skills/engineering` `skills/productivity` の一部＋`skills/in-progress`
  `skills/misc`。上流 `code-review` は caarlos0 と名前が衝突するため**採用しない**。
- 独自変更の概要: 一部スキル（`ask-matt` / `codebase-design` / `diagnosing-bugs` /
  `domain-modeling` / `tdd`）の frontmatter `description` と見出しを日本語化。本文は
  英語のまま。上流更新時は `main` を取り込み `ja` を rebase する。

### `caarlos0/dotfiles`（MIT）

- 用途: Go/Rust/TypeScript/Python 性能、CLI/TUI/dashboard 設計、コードレビュー等。
- 元の配布元URL: https://github.com/caarlos0/dotfiles（`skills/`）
- フォークURL: https://github.com/mame7743/agent-skills-caarlos0（翻訳は branch `ja`）
- 採用スキル: `skills/` の全20スキル（`code-review` はこちらを採用）。
- 独自変更の概要: 一部スキル（`code-review` / `writing-tests` / `cli-design` /
  `tui-design` / `code-simplifier`）の frontmatter `description` と見出しを日本語化。
  本文は英語のまま。

### `nextlevelbuilder/ui-ux-pro-max-skill`（MIT）

- 用途: UI/UX の配色・タイポグラフィ・UX ルール検索とデザインシステム生成。
- 元の配布元URL: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- フォークURL: 未作成（独自変更時に追加）。
- 採用スキル: `.claude/skills/ui-ux-pro-max`（上流の他スキルは採用しない）。
- 独自変更の概要: 現時点なし（原文のまま）。Python スクリプトは標準ライブラリのみ。

> 削除したスキル: `docx` / `xlsx` / `pdf`（Anthropic 独自ライセンスで派生・再配布禁止）、
> `web-design-guidelines`（上流にライセンス表記なし）、`skill-creator` / `frontend-design` /
> `mcp-builder`（方針により除外）。必要なら公式の提供元から各自導入する。

## ライセンス

各 submodule は配布元のライセンス・著作権表示を維持する。本リポジトリ自体のライセンスは
ルートの `LICENSE`（MIT）。外部スキルの取り込み・翻訳を行う場合は、配布元のライセンス条件に
従うこと。
