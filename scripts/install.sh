#!/usr/bin/env bash
# install.sh — create symlinks for all dotfiles
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
)

info "Linking dotfiles into $HOME_DIR"
for f in "${SYMLINK_FILES[@]}"; do
  link "$DOTFILES_DIR/$f" "$HOME_DIR/$f"
done

# --- XDG config dir ----------------------------------------------------------
mkdir -p "$HOME_DIR/.config"

info "Linking ~/.config/nvim"
link "$DOTFILES_DIR/config/nvim" "$HOME_DIR/.config/nvim"

# --- WezTerm (terminal / panes) ---------------------------------------------
if [[ -f "$DOTFILES_DIR/config/wezterm/wezterm.lua" ]]; then
  info "Linking ~/.config/wezterm"
  link "$DOTFILES_DIR/config/wezterm" "$HOME_DIR/.config/wezterm"
fi

# --- opencode global config -------------------------------------------------
# Individual files/subdirs only (never the whole dir: node_modules, skills
# symlinks, and generated files live in ~/.config/opencode).
OC_DIR="$HOME_DIR/.config/opencode"
mkdir -p "$OC_DIR"
if [[ -f "$DOTFILES_DIR/config/opencode/opencode.jsonc" ]]; then
  info "Linking opencode.jsonc"
  link "$DOTFILES_DIR/config/opencode/opencode.jsonc" "$OC_DIR/opencode.jsonc"
fi
if [[ -f "$DOTFILES_DIR/config/opencode/AGENTS.md" ]]; then
  info "Linking ~/.config/opencode/AGENTS.md"
  link "$DOTFILES_DIR/config/opencode/AGENTS.md" "$OC_DIR/AGENTS.md"
fi
# Legacy V1 directory names (singular) are superseded by the V2 plural layout.
for legacy in agent command; do
  if [[ -L "$OC_DIR/$legacy" ]]; then
    rm "$OC_DIR/$legacy"
    success "Removed legacy link $OC_DIR/$legacy"
  fi
done

for d in agents commands plugins; do
  if [[ -d "$DOTFILES_DIR/config/opencode/$d" ]]; then
    info "Linking ~/.config/opencode/$d"
    link "$DOTFILES_DIR/config/opencode/$d" "$OC_DIR/$d"
  fi
done

# --- mise (言語ランタイムの固定) ---------------------------------------------
# config/mise/config.toml がグローバルなランタイム版の情報源
if [[ -f "$DOTFILES_DIR/config/mise/config.toml" ]]; then
  mkdir -p "$HOME_DIR/.config/mise"
  info "Linking ~/.config/mise/config.toml"
  link "$DOTFILES_DIR/config/mise/config.toml" "$HOME_DIR/.config/mise/config.toml"
fi

# --- jjui (jujutsu TUI の日本語操作メニュー) ---------------------------------
# jjui 自身が types.lua / .luarc.json を同ディレクトリへ生成するため、
# ディレクトリ全体ではなくファイル単位でリンクする。
if [[ -f "$DOTFILES_DIR/config/jjui/config.lua" ]]; then
  mkdir -p "$HOME_DIR/.config/jjui"
  info "Linking ~/.config/jjui/config.lua"
  link "$DOTFILES_DIR/config/jjui/config.lua" "$HOME_DIR/.config/jjui/config.lua"
fi

# --- bin/ (custom tools) -----------------------------------------------------
# トップレベルの実行ファイルを ~/.local/bin（.zshrc で PATH 済み）へリンクする。
# ビルドが必要なツールやディレクトリ型は scripts/bin-tools.py（make bin-tools）が担当。
LOCAL_BIN="$HOME_DIR/.local/bin"
info "Linking bin/* → $LOCAL_BIN"
mkdir -p "$LOCAL_BIN"
for script in "$DOTFILES_DIR/bin/"*; do
  [[ -f "$script" ]] || continue          # ディレクトリは bin-tools.py が担当
  [[ "$(basename "$script")" == README* ]] && continue
  chmod +x "$script"
  link "$script" "$LOCAL_BIN/$(basename "$script")"
done

# 旧 ~/bin（PATH 外だった）へのリンクを掃除して ~/.local/bin へ移行
if [[ -d "$HOME_DIR/bin" ]]; then
  for stale in "$HOME_DIR/bin"/*; do
    [[ -L "$stale" ]] || continue
    case "$(readlink "$stale")" in
      "$DOTFILES_DIR"/*) rm "$stale"; success "Removed stale link $stale" ;;
    esac
  done
  rmdir "$HOME_DIR/bin" 2>/dev/null || true
fi

# --- LLM skills --------------------------------------------------------------
# スキルは agent-skills/manifest.toml で宣言し、agent-skills/install.sh が
# 選択したものだけを Agent の読込先へ symlink する。
# Git / submodule 操作はここでは行わない（README の手順に分離）。
if [[ -x "$DOTFILES_DIR/agent-skills/install.sh" ]]; then
  # 1つでも submodule が取得済みなら install.sh を実行する
  # （未取得のスキルは install.sh 側が警告してスキップする）。
  submodules_ready=0
  for d in "$DOTFILES_DIR"/agent-skills/repos/*/; do
    [[ -d "$d" ]] || continue
    if [[ -n "$(ls -A "$d" 2>/dev/null | grep -v '^\.git$')" ]]; then
      submodules_ready=1
      break
    fi
  done
  if [[ "$submodules_ready" == "1" ]]; then
    info "Installing agent skills from agent-skills/manifest.toml"
    bash "$DOTFILES_DIR/agent-skills/install.sh" || warn "agent-skills: 競合のため一部未導入"
  else
    warn "agent-skills: submodule 未初期化のためスキル導入をスキップ"
    warn "  → git submodule update --init --recursive を実行してください"
  fi
fi

# --- vim undo directory ------------------------------------------------------
mkdir -p "$HOME_DIR/.vim/undo"

info "Done! Open a new shell to apply changes."
