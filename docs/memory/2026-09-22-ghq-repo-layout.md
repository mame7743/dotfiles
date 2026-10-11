# ghq リポジトリ配置・`~/ansible` symlink 廃止・`home-infra` リネーム

- date: 2026-09-22
- status: decided
- related: `/Users/atsushi/ghq/github.com/mame7743/home-infra`, `/Users/atsushi/ghq/github.com/mame7743/dotfiles`

## Context

リポジトリを `ghq`（root: `~/ghq`）管理へ移行した。`~/dotfiles` と `~/ansible` は
実体を `~/ghq/github.com/mame7743/` 配下へ移動し、`~` 側は互換 symlink としていた。

- 「ansible」というローカルの呼び名のフォルダは、リポジトリ `home-infra`（旧 `proxmox-homelab`）の作業コピー。
  中身は Proxmox ホームラボの構築・管理用 Ansible playbooks（`ansible.cfg` / `playbooks/` / `inventory/` / `files/`）。

## Decision / Finding

1. `~/ansible` の互換 symlink は**廃止**し、ghq の実体パスを直接使う。
2. リポジトリ名を `proxmox-homelab` → `home-infra` に変更（GitHub）。
   ローカルの ghq ディレクトリも `~/ghq/github.com/mame7743/home-infra` に統一。
   - 既存の**空**リポジトリ `mame7743/home-infra`（コミット0・2026-05-29 作成）が名前を占有していたため、
     `mame7743/home-infra-archive` へ退避してからリネームした。
   - `origin` remote は `https://github.com/mame7743/home-infra.git`。
3. `~/dotfiles` の互換 symlink は**維持**する（`install.sh` や各ドキュメントが `~/dotfiles` を前提にしているため）。
4. 旧絶対パス `/Users/atsushi/ansible` と旧名 `proxmox-homelab` を、両リポジトリの全テキストから置換した。

## 変更ファイル

- dotfiles: `AGENTS.md`, `docs/memory/2026-09-05-backup-restic-phase1.md`, `docs/memory/README.md`, `.multiagent/**`（gitignore 対象）
- home-infra: `README.md`（タイトル）, `.multiagent/tasks/*.json`（追跡対象）

## 影響・確認

- `ansible.cfg` と playbook は相対パス前提のため、ghq 実体ディレクトリで実行すれば従来どおり動作する。
- `ghq list` / `ghq look` は `home-infra` として解決される。

## 未対応 / 注意

- **forgejo remote**（`jitaku-tools/proxmox-homelab`）はサーバ側が未リネーム。`10.0.1.30:3000` に
  到達できないため後日対応。`.git/config` の URL は旧名のまま温存している。
- `mame7743/home-infra-archive`（空）は削除可（GitHub トークンに `delete_repo` スコープが必要）。
- ~~別名ホスト階層を正規化していない~~ → 2026-09-22 に正規化済み（下記「追記」参照）。
- VS Code の recent folder は旧パスのまま（任意で更新）。

## 追記: 別名ホスト階層の正規化（2026-09-22）

`includeIf` の会社 identity 切り替えに引きずられて残っていた別名ホスト階層を、
標準レイアウト `~/ghq/github.com/<owner>/<repo>` へ統合した（`mv` ベース、重複なし）。

| 旧 | 新 |
|---|---|
| `github.com.mame7743/mame7743/lispy` | `github.com/mame7743/lispy` |
| `github.com.rohm/mnfsys-rohm/rlc` | `github.com/mnfsys-rohm/rlc` |
| `github.com.rohm/mnfsys-rohm/github-ops-handbook` | `github.com/mnfsys-rohm/github-ops-handbook` |
| `github.com.sub/rohm/tlra_control_main` | `github.com/rohm/tlra_control_main` |

- 空になった `github.com.mame7743/` `github.com.rohm/` `github.com.sub/` は削除。
- `~/.gitconfig.local` の `includeIf` から `github.com.rohm/` と `github.com.sub/` を削除し、
  `github.com/rohm/` を追加（`tlra_control_main` の会社 identity を維持）。
- 検証: dirty 数は移動前後で不変（lispy 0 / rlc 37 / handbook 11 / tlra 20）、
  `rlc` の未push 171 コミットも保持。`git config user.email` は rohm/mnfsys-rohm 系=会社、
  mame7743 系=個人を確認。`lispy` の `.venv` は絶対パス依存のため `uv sync` で再作成。
