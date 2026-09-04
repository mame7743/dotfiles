#!/usr/bin/env bash
# install.sh — create symlinks for all dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

# --- Helpers -----------------------------------------------------------------
info()    { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
error()   { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; }

link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sfn "$src" "$dst"
  success "$dst → $src"
}

# --- HOME dotfiles -----------------------------------------------------------
SYMLINK_FILES=(
  .zshrc
  .zshenv
  .gitconfig
  .gitignore_global
  .vimrc
  .tmux.conf
)

info "Linking dotfiles into $HOME_DIR"
for f in "${SYMLINK_FILES[@]}"; do
  link "$DOTFILES_DIR/$f" "$HOME_DIR/$f"
done

# --- XDG config dir ----------------------------------------------------------
mkdir -p "$HOME_DIR/.config"

info "Linking ~/.config/nvim"
link "$DOTFILES_DIR/config/nvim" "$HOME_DIR/.config/nvim"

# --- bin/ (custom tools) -----------------------------------------------------
info "Linking ~/bin → $DOTFILES_DIR/bin"
mkdir -p "$HOME_DIR/bin"
for script in "$DOTFILES_DIR/bin/"*; do
  [[ -f "$script" ]] || continue
  chmod +x "$script"
  link "$script" "$HOME_DIR/bin/$(basename "$script")"
done

# --- vim undo directory ------------------------------------------------------
mkdir -p "$HOME_DIR/.vim/undo"

info "Done! Open a new shell to apply changes."
