#!/usr/bin/env bash
# deps/update.sh — deps/versions.env と Python ロックを最新へ更新する
#
# 使い方: make deps-update
#   1. GitHub / Go proxy から最新バージョンとチェックサムを取得
#   2. deps/versions.env を書き換え
#   3. python/requirements-visualization.lock を再生成
#   4. 変更点を git diff で表示（コミットはしない）
#
# 秘密値・トークンは扱わない。GitHub API は未認証で呼ぶ（レート制限時は GH_TOKEN を任意で利用）。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="$DOTFILES_DIR/deps/versions.env"
PY_IN="$DOTFILES_DIR/python/requirements-visualization.txt"
PY_LOCK="$DOTFILES_DIR/python/requirements-visualization.lock"

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
die()   { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl が必要です"
command -v jq   >/dev/null 2>&1 || die "jq が必要です（brew install jq）"

# --- GitHub helpers ----------------------------------------------------------
gh_api() {
  local url="https://api.github.com/repos/$1"
  if [[ -n "${GH_TOKEN:-}" ]]; then
    curl -fsSL -H "Authorization: Bearer $GH_TOKEN" "$url"
  else
    curl -fsSL "$url"
  fi
}

gh_latest_tag() { gh_api "$1/releases/latest" | jq -r '.tag_name'; }

gh_asset_digest() {
  # $1=repo $2=asset name regex  →  sha256 hex
  gh_api "$1/releases/latest" \
    | jq -r --arg re "$2" '.assets[] | select(.name|test($re)) | .digest' \
    | head -n1 | sed 's/^sha256://'
}

# Go module proxy の最新安定版
go_latest() {
  curl -fsSL "https://proxy.golang.org/$1/@latest" | jq -r '.Version'
}

# --- versions.env の書き換え --------------------------------------------------
set_var() {
  local key="$1" value="$2"
  if ! grep -q "^${key}=" "$VERSIONS_FILE"; then
    die "deps/versions.env に $key がありません（キーを消さないでください）"
  fi
  local tmp; tmp="$(mktemp)"
  sed "s|^${key}=.*|${key}=\"${value}\"|" "$VERSIONS_FILE" > "$tmp"
  mv "$tmp" "$VERSIONS_FILE"
}

# --- 最新版の取得 ------------------------------------------------------------
info "最新バージョンを取得中…"

# lazygit のタグは v 付きだがアセット名は v なし。保存は v なしに正規化する
LAZYGIT_VERSION="$(gh_latest_tag jesseduffield/lazygit | sed 's/^v//')"
LUALS_VERSION="$(gh_latest_tag LuaLS/lua-language-server)"
GHQ_VERSION="$(go_latest github.com/x-motemen/ghq)"
GOPLS_VERSION="$(go_latest golang.org/x/tools/gopls)"
GOLANGCI_LINT_VERSION="$(go_latest github.com/golangci/golangci-lint/v2)"

LAZYGIT_LINUX_AMD64_SHA256="$(gh_asset_digest jesseduffield/lazygit 'lazygit_[0-9.]+_linux_x86_64\.tar\.gz$')"
LAZYGIT_LINUX_ARM64_SHA256="$(gh_asset_digest jesseduffield/lazygit 'lazygit_[0-9.]+_linux_arm64\.tar\.gz$')"
LUALS_LINUX_X64_SHA256="$(gh_asset_digest LuaLS/lua-language-server 'lua-language-server-[0-9.]+-linux-x64\.tar\.gz$')"
LUALS_LINUX_ARM64_SHA256="$(gh_asset_digest LuaLS/lua-language-server 'lua-language-server-[0-9.]+-linux-arm64\.tar\.gz$')"

for v in LAZYGIT_VERSION LUALS_VERSION GHQ_VERSION GOPLS_VERSION GOLANGCI_LINT_VERSION \
         LAZYGIT_LINUX_AMD64_SHA256 LAZYGIT_LINUX_ARM64_SHA256 \
         LUALS_LINUX_X64_SHA256 LUALS_LINUX_ARM64_SHA256; do
  [[ -n "${!v}" ]] || die "$v の取得に失敗しました"
done

set_var LAZYGIT_VERSION "$LAZYGIT_VERSION"
set_var LUALS_VERSION "$LUALS_VERSION"
set_var GHQ_VERSION "$GHQ_VERSION"
set_var GOPLS_VERSION "$GOPLS_VERSION"
set_var GOLANGCI_LINT_VERSION "$GOLANGCI_LINT_VERSION"
set_var LAZYGIT_LINUX_AMD64_SHA256 "$LAZYGIT_LINUX_AMD64_SHA256"
set_var LAZYGIT_LINUX_ARM64_SHA256 "$LAZYGIT_LINUX_ARM64_SHA256"
set_var LUALS_LINUX_X64_SHA256 "$LUALS_LINUX_X64_SHA256"
set_var LUALS_LINUX_ARM64_SHA256 "$LUALS_LINUX_ARM64_SHA256"
ok "deps/versions.env を更新"

# --- Python ロックの再生成 ---------------------------------------------------
if command -v uv >/dev/null 2>&1; then
  info "python/requirements-visualization.lock を再生成中…"
  uv pip compile "$PY_IN" -o "$PY_LOCK" --quiet --no-header
  ok "Python ロックを更新"
else
  warn "uv が見つかりません — Python ロックは未更新"
fi

# --- 差分表示 ----------------------------------------------------------------
echo
if command -v git >/dev/null 2>&1 && git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  info "変更点:"
  git -C "$DOTFILES_DIR" --no-pager diff --stat -- deps/versions.env python/requirements-visualization.lock || true
  echo
  info "内容を確認してコミットしてください（自動コミットはしません）。"
else
  warn "git リポジトリではないため差分は表示しません"
fi
