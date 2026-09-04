#!/usr/bin/env bash
# install-deps.sh — install dotfiles dependencies across platforms
#   macOS   : Homebrew bundle (Brewfile)
#   Linux   : apt (Debian/Ubuntu) + GitHub release downloads
#   Windows : run install-deps.ps1 instead (native PowerShell / winget)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"

info()    { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  MINGW*|MSYS*|CYGWIN*)
    warn "Git Bash / Cygwin が検出されました。ネイティブWindowsでは install-deps.ps1 を使ってください。"
    exit 0 ;;
  *)
    warn "未対応OS: $(uname -s)"
    exit 1 ;;
esac

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------
if [[ "$OS" == macos ]]; then
  info "macOS detected — installing via Homebrew bundle"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
  success "Dependencies installed (Homebrew)"
  exit 0
fi

# ---------------------------------------------------------------------------
# Linux (Debian/Ubuntu)
# ---------------------------------------------------------------------------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)          LAZYGIT_ARCH=x86_64; LUALS_ARCH=x64 ;;
  aarch64|arm64)   LAZYGIT_ARCH=arm64;  LUALS_ARCH=arm64 ;;
  *) warn "未対応アーキテクチャ: $ARCH"; exit 1 ;;
esac

info "Debian/Ubuntu detected — installing via apt"
sudo apt-get update -y
sudo apt-get install -y \
  bat curl fd-find fzf git golang-go ripgrep tmux zlib1g-dev \
  ca-certificates unzip build-essential

mkdir -p "$LOCAL_BIN" "$LOCAL_SHARE"

# fd shim (Debian は fdfind として導入される)
install_fd_shim() {
  if command -v fd >/dev/null 2>&1; then return; fi
  if command -v fdfind >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$LOCAL_BIN/fd"
    success "fd -> fdfind (shim)"
  fi
}

# GitHub 最新リリースのアセットURLを取得
github_asset_url() {
  local repo="$1" pattern="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | grep -oE 'https://[^"]+' \
    | grep -E "$pattern" \
    | head -n1 || true
}

install_gibo() {
  command -v gibo >/dev/null 2>&1 && { success "gibo (installed)"; return; }
  curl -fsSL "https://raw.githubusercontent.com/simonwhitaker/gibo/master/gibo" -o "$LOCAL_BIN/gibo"
  chmod +x "$LOCAL_BIN/gibo"
  success "gibo -> $LOCAL_BIN/gibo"
}

install_lazygit() {
  command -v lazygit >/dev/null 2>&1 && { success "lazygit (installed)"; return; }
  local url tmp
  url="$(github_asset_url "jesseduffield/lazygit" "lazygit_[0-9.]+_linux_${LAZYGIT_ARCH}\.tar\.gz")"
  if [[ -z "$url" ]]; then warn "lazygit: release URL が見つかりません"; return 1; fi
  tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
  install -Dm755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
  rm -rf "$tmp"
  success "lazygit -> $LOCAL_BIN/lazygit"
}

install_luals() {
  command -v lua-language-server >/dev/null 2>&1 && { success "lua-language-server (installed)"; return; }
  local url tmp dest extracted
  url="$(github_asset_url "luals/lua-language-server" "lua-language-server-[0-9.]+-linux-${LUALS_ARCH}\.tar\.gz")"
  if [[ -z "$url" ]]; then warn "lua-language-server: release URL が見つかりません"; return 1; fi
  tmp="$(mktemp -d)"
  curl -fsSL "$url" | tar -xz -C "$tmp"
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
  success "lua-language-server -> $LOCAL_BIN"
}

install_ghq() {
  command -v ghq >/dev/null 2>&1 && { success "ghq (installed)"; return; }
  go install github.com/x-motemen/ghq@latest
  success "ghq (go install)"
}

install_pyenv() {
  if [[ -d "$HOME/.pyenv" ]]; then success "pyenv (present)"; return; fi
  git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
  success "pyenv -> $HOME/.pyenv"
}

install_rbenv() {
  if [[ -d "$HOME/.rbenv" ]]; then success "rbenv (present)"; return; fi
  git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  if ! [[ -d "$HOME/.rbenv/plugins/ruby-build" ]]; then
    git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
  fi
  success "rbenv -> $HOME/.rbenv"
}

install_fd_shim
install_gibo
install_lazygit
install_luals
install_ghq
install_pyenv
install_rbenv

success "Dependencies installed (Linux/apt)"