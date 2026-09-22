#!/usr/bin/env bash
# deps/check.sh — 宣言した依存と実際のインストール状態のドリフトを検知する
#
# 使い方: make deps-check
# 終了コード: 0 = すべて OK / 1 = FAIL あり
#
# 方針:
#   - macOS の lazygit / luals / ghq は Homebrew が版を決めるため固定値と比較しない
#     （Brewfile と brew bundle check で整合を見る）
#   - Linux では deps/versions.env の固定値とインストール済み版を比較する
#   - 言語ランタイムは config/mise/config.toml と mise の状態を比較する
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSIONS_FILE="$DOTFILES_DIR/deps/versions.env"
MISE_CONFIG="$DOTFILES_DIR/config/mise/config.toml"
PY_IN="$DOTFILES_DIR/python/requirements-visualization.txt"
PY_LOCK="$DOTFILES_DIR/python/requirements-visualization.lock"

FAIL=0
ok()   { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
fail() { printf '\033[0;31m[fail]\033[0m  %s\n' "$*"; FAIL=1; }
warn() { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
skip() { printf '\033[0;33m[skip]\033[0m  %s\n' "$*"; }
info() { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }

# 先頭の v を無視して比較
norm() { echo "${1#v}"; }

# --- 1. versions.env の必須キー ---------------------------------------------
info "deps/versions.env を検査"
# shellcheck source=/dev/null
source "$VERSIONS_FILE"
REQUIRED_KEYS=(
  LAZYGIT_VERSION LUALS_VERSION GHQ_VERSION GOPLS_VERSION GOLANGCI_LINT_VERSION
  LAZYGIT_LINUX_AMD64_SHA256 LAZYGIT_LINUX_ARM64_SHA256
  LUALS_LINUX_X64_SHA256 LUALS_LINUX_ARM64_SHA256
)
for key in "${REQUIRED_KEYS[@]}"; do
  if [[ -n "${!key:-}" ]]; then
    ok "versions.env: $key=${!key}"
  else
    fail "versions.env: $key が空です"
  fi
done

# --- 2. mise のランタイム ----------------------------------------------------
info "mise ランタイムを検査"
if command -v mise >/dev/null 2>&1; then
  if [[ ! -f "$MISE_CONFIG" ]]; then
    fail "config/mise/config.toml がありません"
  elif ! mise ls --json >/dev/null 2>&1; then
    fail "mise ls --json の実行に失敗しました"
  else
    # [tools] セクションの `tool = "version"` のみを列挙（[settings] は除外）
    while IFS='=' read -r tool want; do
      tool="$(echo "$tool" | xargs)"
      want="$(echo "$want" | tr -d '" ' )"
      [[ -z "$tool" || -z "$want" ]] && continue
      installed="$(mise ls --json 2>/dev/null | jq -r --arg t "$tool" '.[$t][]? | select(.requested_version==$v) | .installed' --arg v "$want" 2>/dev/null | head -n1)"
      if [[ "$installed" == "true" ]]; then
        ok "mise: $tool $want (installed)"
      else
        fail "mise: $tool $want が未インストール（mise install を実行してください）"
      fi
    done < <(awk '/^\[tools\]/{f=1;next} /^\[/{f=0} f && /=/' "$MISE_CONFIG")
  fi
else
  skip "mise が見つかりません"
fi

# --- 3. プラットフォーム別の固定ツール --------------------------------------
case "$(uname -s)" in
  Linux)
    info "Linux: 固定ツールのバージョンを検査"
    check_cmd_version() { # $1=cmd $2=expected
      local cmd="$1" want="$2" got
      if ! command -v "$cmd" >/dev/null 2>&1; then
        skip "$cmd 未インストール"
        return
      fi
      # 出力形式はツールごとに異なるため、最初の semver を抽出する
      got="$("$cmd" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
      if [[ "$got" == "$(norm "$want")" ]]; then
        ok "$cmd $got"
      else
        fail "$cmd の版が固定値と不一致: 期待 $(norm "$want") / 実際 ${got:-unknown}"
      fi
    }
    check_cmd_version lazygit "$LAZYGIT_VERSION"
    check_cmd_version ghq "$GHQ_VERSION"
    check_cmd_version lua-language-server "$LUALS_VERSION"
    ;;
  Darwin)
    info "macOS: Homebrew の整合を検査"
    if command -v brew >/dev/null 2>&1; then
      if brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
        ok "brew bundle check"
      else
        # 基盤層は「追従」方針のため、差分は警告に留める（FAIL にしない）
        warn "Brewfile に未反映の依存があります（brew bundle --file=Brewfile で同期）"
      fi
    else
      skip "brew が見つかりません"
    fi
    ;;
  *)
    skip "未対応 OS: $(uname -s)"
    ;;
esac

# --- 4. Python ロックの同期 --------------------------------------------------
info "Python ロックを検査"
if [[ ! -f "$PY_LOCK" ]]; then
  fail "python/requirements-visualization.lock がありません"
elif ! command -v uv >/dev/null 2>&1; then
  skip "uv が見つかりません"
else
  tmp="$(mktemp)"
  if uv pip compile "$PY_IN" -o "$tmp" --quiet --no-header 2>/dev/null; then
    if diff -q "$tmp" "$PY_LOCK" >/dev/null 2>&1; then
      ok "requirements-visualization.lock は同期済み"
    else
      fail "requirements-visualization.lock が古い（make deps-update）"
    fi
  else
    skip "uv pip compile に失敗（ネットワーク未接続の可能性）"
  fi
  rm -f "$tmp"
fi

echo
if [[ "$FAIL" -eq 0 ]]; then
  ok "依存チェック: すべて OK"
else
  fail "依存チェック: 失敗あり"
fi
exit "$FAIL"
