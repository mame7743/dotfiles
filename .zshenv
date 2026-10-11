# .zshenv — loaded for all zsh invocations (login, interactive, scripts)
# Keep this minimal: only environment variables that must always be set.

# Editor: 既定は Neovim。$EDITOR / $VISUAL を設定すればそちらが優先される。
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="ja_JP.UTF-8"
export LC_ALL="ja_JP.UTF-8"

# XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
