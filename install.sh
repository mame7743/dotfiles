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

# --- opencode global config -------------------------------------------------
# Individual files/subdirs only (never the whole dir: node_modules, skills
# symlinks, and generated files live in ~/.config/opencode).
OC_DIR="$HOME_DIR/.config/opencode"
mkdir -p "$OC_DIR"
if [[ -f "$DOTFILES_DIR/config/opencode/opencode.jsonc" ]]; then
  info "Linking opencode.jsonc"
  link "$DOTFILES_DIR/config/opencode/opencode.jsonc" "$OC_DIR/opencode.jsonc"
fi
for d in agent command; do
  if [[ -d "$DOTFILES_DIR/config/opencode/$d" ]]; then
    info "Linking ~/.config/opencode/$d"
    link "$DOTFILES_DIR/config/opencode/$d" "$OC_DIR/$d"
  fi
done

# --- bin/ (custom tools) -----------------------------------------------------
info "Linking ~/bin → $DOTFILES_DIR/bin"
mkdir -p "$HOME_DIR/bin"
for script in "$DOTFILES_DIR/bin/"*; do
  [[ -f "$script" ]] || continue
  chmod +x "$script"
  link "$script" "$HOME_DIR/bin/$(basename "$script")"
done

# --- LLM skills --------------------------------------------------------------
# Each skill in $DOTFILES_DIR/skills/<name> is symlinked into every agent's
# skills directory (opencode / claude / codex / ~/.agents).
SKILL_DIRS=(
  "$HOME_DIR/.config/opencode/skills"
  "$HOME_DIR/.claude/skills"
  "$HOME_DIR/.codex/skills"
  "$HOME_DIR/.agents/skills"
)

if [[ -d "$DOTFILES_DIR/skills" ]]; then
  for dir in "${SKILL_DIRS[@]}"; do
    mkdir -p "$dir"
  done
  for skill in "$DOTFILES_DIR/skills/"*; do
    [[ -d "$skill" ]] || continue
    name="$(basename "$skill")"
    for dir in "${SKILL_DIRS[@]}"; do
      link "$skill" "$dir/$name"
    done
  done
fi

# --- vim undo directory ------------------------------------------------------
mkdir -p "$HOME_DIR/.vim/undo"

info "Done! Open a new shell to apply changes."
