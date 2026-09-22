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
- `~/.ssh` の別名ホスト階層（`ghq/github.com.rohm/...`, `ghq/github.com.sub/...`,
  `ghq/github.com.mame7743/mame7743/lispy`）は正規化していない。
- VS Code の recent folder は旧パスのまま（任意で更新）。
