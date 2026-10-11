#!/usr/bin/env bash
# install-deps.sh — install dotfiles dependencies across platforms
#   macOS   : Homebrew bundle (Brewfile) + mise (language runtimes)
#   Linux   : apt (Debian/Ubuntu) + pinned GitHub releases + mise
#   Windows : run scripts/install-deps.ps1 instead (native PowerShell / winget)
#
# 固定バージョンは deps/versions.env、ランタイムは config/mise/config.toml が情報源。
# 方針は docs/dependency-policy.md を参照。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"
VIZ_VENV="$HOME/.local/venvs/visualization"

# 固定バージョン・チェックサムの唯一の情報源
# shellcheck source=/dev/null
source "$DOTFILES_DIR/deps/versions.env"

info()    { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }

# --- 引数 -------------------------------------------------------------------
#   --core / --profile core : deps/core.txt の最低限セットのみ導入
#   -n / --dry-run          : 導入せず内容を表示（--core と併用）
PROFILE=full
DRY_RUN=0
usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --core)       PROFILE=core ;;
    --profile)    PROFILE="${2:?--profile には値が必要です}"; shift ;;
    --profile=*)  PROFILE="${1#*=}" ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)    usage; exit 0 ;;
    *) warn "不明な引数: $1" ;;
  esac
  shift
done

if [[ "$DRY_RUN" == 1 && "$PROFILE" != core ]]; then
  warn "--dry-run は --core（core プロファイル）と併用してください"
  exit 2
fi

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# 期待チェックサムと一致しなければ 1 を返す
verify_sha256() { # $1=file $2=expected
  local actual
  actual="$(sha256_of "$1")"
  if [[ "$actual" != "$2" ]]; then
    warn "チェックサム不一致: 期待 $2 / 実際 $actual"
    return 1
  fi
}

# deps/core.txt から Brewfile を生成する（core プロファイル）
# 形式: <manager> <name>  (manager: brew | cask)
core_brewfile() { # $1=出力先
  local out="$1" line manager name
  : > "$out"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"                 # 行末コメントを除去
    line="$(printf '%s' "$line" | xargs)"
    [[ -z "$line" ]] && continue
    manager="${line%% *}"
    name="${line#* }"
    case "$manager" in
      brew) printf 'brew "%s"\n' "$name" >> "$out" ;;
      cask) printf 'cask "%s"\n' "$name" >> "$out" ;;
      *)    warn "deps/core.txt: 未知の manager: $line" ;;
    esac
  done < "$DOTFILES_DIR/deps/core.txt"
}

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  MINGW*|MSYS*|CYGWIN*)
    warn "Git Bash / Cygwin が検出されました。ネイティブWindowsでは scripts/install-deps.ps1 を使ってください。"
    exit 0 ;;
  *)
    warn "未対応OS: $(uname -s)"
    exit 1 ;;
esac

# ===========================================================================
# ツール導入関数（OS 共通で定義。呼び出し側で使うものを選ぶ）
# ===========================================================================

# fd shim (Debian は fdfind として導入される)
install_fd_shim() {
  if command -v fd >/dev/null 2>&1; then return; fi
  if command -v fdfind >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$LOCAL_BIN/fd"
    success "fd -> fdfind (shim)"
  fi
}

install_gibo() {
  command -v gibo >/dev/null 2>&1 && { success "gibo (installed)"; return; }
  curl -fsSL "https://raw.githubusercontent.com/simonwhitaker/gibo/master/gibo" -o "$LOCAL_BIN/gibo"
  chmod +x "$LOCAL_BIN/gibo"
  success "gibo -> $LOCAL_BIN/gibo"
}

# 固定バージョン + チェックサム検証付きで GitHub リリースを取得
install_lazygit() {
  command -v lazygit >/dev/null 2>&1 && { success "lazygit (installed)"; return; }
  # versions.env は v なしで保存する（タグは v 付き / アセット名は v なし）
  local ver="${LAZYGIT_VERSION#v}" url tmp sum
  case "$LAZYGIT_ARCH" in
    x86_64) sum="$LAZYGIT_LINUX_AMD64_SHA256" ;;
    arm64)  sum="$LAZYGIT_LINUX_ARM64_SHA256" ;;
    *)      warn "lazygit: 未対応アーキテクチャ $LAZYGIT_ARCH"; return 1 ;;
  esac
  url="https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_linux_${LAZYGIT_ARCH}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/lazygit.tar.gz" || { warn "lazygit: ダウンロード失敗"; rm -rf "$tmp"; return 1; }
  verify_sha256 "$tmp/lazygit.tar.gz" "$sum" || { warn "lazygit: 検証失敗のため中止"; rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp"
  install -Dm755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
  rm -rf "$tmp"
  success "lazygit $ver -> $LOCAL_BIN/lazygit"
}

install_luals() {
  command -v lua-language-server >/dev/null 2>&1 && { success "lua-language-server (installed)"; return; }
  local ver="$LUALS_VERSION" url tmp sum dest extracted
  case "$LUALS_ARCH" in
    x64)   sum="$LUALS_LINUX_X64_SHA256" ;;
    arm64) sum="$LUALS_LINUX_ARM64_SHA256" ;;
    *)     warn "lua-language-server: 未対応アーキテクチャ $LUALS_ARCH"; return 1 ;;
  esac
  url="https://github.com/LuaLS/lua-language-server/releases/download/${ver}/lua-language-server-${ver}-linux-${LUALS_ARCH}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/luals.tar.gz" || { warn "lua-language-server: ダウンロード失敗"; rm -rf "$tmp"; return 1; }
  verify_sha256 "$tmp/luals.tar.gz" "$sum" || { warn "lua-language-server: 検証失敗のため中止"; rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/luals.tar.gz" -C "$tmp"
  if [[ -d "$tmp/bin" ]]; then
    extracted="$tmp"
  else
    extracted="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n1)"
    [[ -z "$extracted" ]] && extracted="$tmp"
  fi
  dest="$LOCAL_SHARE/lua-language-server"
  rm -rf "$dest"
  mv "$extracted" "$dest"
  ln -sfn "$dest/bin/lua-language-server" "$LOCAL_BIN/lua-language-server"
  rm -rf "$tmp"
  success "lua-language-server $ver -> $LOCAL_BIN"
}

install_ghq() {
  command -v ghq >/dev/null 2>&1 && { success "ghq (installed)"; return; }
  go install "github.com/x-motemen/ghq@${GHQ_VERSION}"
  success "ghq ${GHQ_VERSION} (go install)"
}

# jj 用 TUI（jjui）。macOS は Homebrew、Linux は go install（固定版）
install_jjui() {
  command -v jjui >/dev/null 2>&1 && { success "jjui (installed)"; return; }
  go install "github.com/idursun/jjui/cmd/jjui@${JJUI_VERSION}"
  success "jjui ${JJUI_VERSION} (go install)"
}

# Linux には mise が無いので公式インストーラで導入（macOS は Homebrew）
install_mise() {
  if command -v mise >/dev/null 2>&1; then success "mise (installed)"; return; fi
  if ! command -v curl >/dev/null 2>&1; then warn "curl がないため mise を導入できません"; return; fi
  curl -fsSL https://mise.run | sh
  export PATH="$LOCAL_BIN:$PATH"
  success "mise -> $LOCAL_BIN/mise"
}

# 言語ランタイムは mise に一本化（config/mise/config.toml が情報源）
install_mise_runtimes() {
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise が見つかりません — 言語ランタイムはスキップ"
    return
  fi
  info "mise install（config/mise/config.toml のランタイム）"
  mise install
  success "言語ランタイム (mise)"
}

# VS Code 拡張機能 (deps/vscode-extensions.txt)
install_vscode_extensions() {
  command -v code >/dev/null 2>&1 || { warn "VS Code の code CLI が見つかりません — 拡張機能はスキップ"; return; }
  local ext
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    if code --list-extensions 2>/dev/null | grep -qx "$ext"; then
      success "code --install-extension $ext (installed)"
    else
      info "code --install-extension $ext"
      code --install-extension "$ext" || warn "$ext のインストールに失敗しました"
    fi
  done < "$DOTFILES_DIR/deps/vscode-extensions.txt"
}

# PyVista 系ライブラリ
#   入力は deps/python/requirements-visualization.txt（人手）、
#   実際に導入するのは固定済みの .lock（make deps-update で再生成）
install_visualization() {
  command -v uv >/dev/null 2>&1 || { warn "uv が見つかりません — Python visualization はスキップ"; return; }
  local lock="$DOTFILES_DIR/deps/python/requirements-visualization.lock"
  [[ -f "$lock" ]] || { warn "requirements-visualization.lock がありません（make deps-update）"; return; }
  if [[ ! -x "$VIZ_VENV/bin/python" ]]; then
    info "Creating venv: $VIZ_VENV"
    uv venv "$VIZ_VENV"
  fi
  uv pip install --python "$VIZ_VENV/bin/python" -r "$lock"
  success "PyVista 系ライブラリ -> $VIZ_VENV"
}

# ===========================================================================
# OS 別インストール
# ===========================================================================

if [[ "$OS" == macos ]]; then
  # -------------------------------------------------------------------------
  # macOS
  # -------------------------------------------------------------------------
  if [[ "$PROFILE" == core ]]; then
    if [[ "$DRY_RUN" == 1 ]]; then
      info "dry-run: deps/core.txt から生成する Brewfile は次のとおり"
      core_brewfile /dev/stdout
      success "dry-run: 実際の導入は行っていません"
    else
      info "macOS: core プロファイル（deps/core.txt）を Homebrew で導入"
      core_tmp="$(mktemp)"
      core_brewfile "$core_tmp"
      brew bundle --file="$core_tmp"
      rm -f "$core_tmp"
      success "Core dependencies installed (Homebrew)"
    fi
  else
    info "macOS detected — installing via Homebrew bundle"
    brew bundle --file="$DOTFILES_DIR/Brewfile"
    success "Dependencies installed (Homebrew)"
  fi
elif [[ "$OS" == linux ]]; then
  # -------------------------------------------------------------------------
  # Linux (Debian/Ubuntu)
  # -------------------------------------------------------------------------
  if [[ "$PROFILE" == core ]]; then
    warn "core プロファイルは現在 macOS のみ対応です（Linux は未対応）"
    exit 1
  fi
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64)          LAZYGIT_ARCH=x86_64; LUALS_ARCH=x64 ;;
    aarch64|arm64)   LAZYGIT_ARCH=arm64;  LUALS_ARCH=arm64 ;;
    *) warn "未対応アーキテクチャ: $ARCH"; exit 1 ;;
  esac

  info "Debian/Ubuntu detected — installing via apt"
  sudo apt-get update -y
  sudo apt-get install -y \
    bat curl fd-find fzf git golang-go ripgrep zlib1g-dev \
    ca-certificates unzip build-essential

  mkdir -p "$LOCAL_BIN" "$LOCAL_SHARE"

  install_fd_shim
  install_gibo
  install_lazygit
  install_luals
  install_ghq
  install_jjui
  install_mise

  success "Dependencies installed (Linux/apt)"
fi

# ===========================================================================
# 共通
# ===========================================================================
# core プロファイルは最小セットのみ（VS Code 拡張・可視化は対象外）。
# 言語ランタイムは core でも導入し、日常環境を再現できるようにする。
if [[ "$PROFILE" == core ]]; then
  if [[ "$DRY_RUN" == 1 ]]; then
    success "dry-run: core プロファイルの内容を表示しました（変更なし）"
  else
    install_mise_runtimes
    success "core プロファイルの導入が完了しました"
  fi
  exit 0
fi

install_mise_runtimes
install_vscode_extensions
install_visualization

success "Dependencies installed"
