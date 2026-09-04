#!/usr/bin/env bash
# bootstrap.sh — install dotfiles from GitHub with a single command.
#
#   curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash
#
# Options (pass after `bash -s --`):
#   --deps   also install dependencies (install-deps.sh)
set -euo pipefail

REPO_URL="https://github.com/mame7743/dotfiles.git"
BRANCH="master"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
INSTALL_DEPS=0

for arg in "$@"; do
  case "$arg" in
    --deps) INSTALL_DEPS=1 ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
error() { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; }

if ! command -v git >/dev/null 2>&1; then
  error "git is required. Install it first (brew install git / apt install git)."
  exit 1
fi

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Updating existing repo at $DOTFILES_DIR"
  if ! git -C "$DOTFILES_DIR" diff --quiet HEAD; then
    warn "$DOTFILES_DIR has uncommitted changes — skipping update, keeping local state."
  else
    git -C "$DOTFILES_DIR" fetch origin --prune
    git -C "$DOTFILES_DIR" checkout -B "$BRANCH" "origin/$BRANCH"
  fi
else
  info "Cloning dotfiles into $DOTFILES_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$DOTFILES_DIR"
fi

info "Linking dotfiles"
bash "$DOTFILES_DIR/install.sh"

if [[ "$INSTALL_DEPS" == "1" ]]; then
  info "Installing dependencies"
  bash "$DOTFILES_DIR/install-deps.sh"
fi

success "Done! Open a new shell to apply changes."