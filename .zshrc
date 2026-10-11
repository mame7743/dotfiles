# zsh
autoload -Uz compinit && compinit # 補完有効

# alias
alias x86='arch -x86_64 zsh'
alias arm='arch -arm64 zsh'
alias lg='lazygit'
alias gia='create_gitignore'
alias get_idf='. $HOME/esp/esp-idf/export.sh'
alias oc='opencode'

# Apple silicon 向けの設定
if [[ $(uname -m) == 'arm64' ]]; then
    export PATH="/opt/homebrew/bin:$PATH" # brew arm64 対応のため
fi

# .local/binをPATHに追加
export PATH="$HOME/.local/bin:$PATH"

export XDG_CONFIG_HOME=${HOME}/.config

# 言語ランタイム (python / node / go / ruby) — mise で統一管理
# 版は ~/.config/mise/config.toml（dotfiles 管理）が情報源
# 旧 pyenv / rbenv / nvm は廃止
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# golang
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# giboで.gitignoreを作成
create_gitignore() {
    local input_file="$1"

    # 引数がない場合は.gitignoreに追加
    if [[ -z "$input_file" ]]; then
        input_file=".gitignore"
    fi

    # テンプレートを選択
    local selected=$(gibo list | fzf \
        --rever
        --multi \
        --preview "gibo dump {} | bat --style=numbers --color=always --paging=never")

    # 未選択の場合は終了
    if [[ -z "$selected" ]]; then
        echo "No templates selected. Exiting."
        return
    fi

    # 選択したテンプレートを指定したファイルに追加
    echo "$selected" | xargs gibo dump >> "$input_file"

    # 結果のファイルをbatで表示
    bat "$input_file"
}

# ghq + fzf — リポジトリを選んで操作
#   gcd : 選んだリポジトリへ移動
#   gco : 選んだリポジトリをエディタで開く（$GCO_EDITOR / $EDITOR / $VISUAL 優先）
_ghq_pick() {
    ghq list -p | fzf \
        --prompt='ghq> ' \
        --height=60% \
        --reverse \
        --preview 'git -C {} --no-pager log --oneline --decorate -12 2>/dev/null || ls -la {}' \
        --preview-window='right:50%:wrap'
}

gcd() {
    local repo
    repo="$(_ghq_pick)" || return
    [[ -n "$repo" ]] || return
    cd "$repo" || return
}

# エディタ解決: 環境変数を優先し、未設定なら nvim → vim → vi にフォールバック。
#   1. $GCO_EDITOR  … gco 専用。VS Code など別のエディタを指定したいとき
#   2. $EDITOR      … 汎用（既定 nvim）
#   3. $VISUAL
# 対話起動では待たないよう --wait は外す（git commit 等は $EDITOR 側で管理）。
_editor() {
    local ed="${GCO_EDITOR:-${EDITOR:-${VISUAL:-}}}"
    if [[ -z "$ed" ]]; then
        local c
        for c in nvim vim vi; do
            if command -v "$c" >/dev/null 2>&1; then ed="$c"; break; fi
        done
    fi
    [[ -n "$ed" ]] || ed="vi"
    print -r -- "${ed//--wait/}"
}

gco() {
    local repo
    repo="$(_ghq_pick)" || return
    [[ -n "$repo" ]] || return
    local ed
    ed="$(_editor)"
    "${=ed}" "$repo"
}

export PATH="$HOME/.local/bin:$PATH"

# direnv — auto-load .envrc when entering a directory
eval "$(direnv hook zsh)"

# Machine-local overrides (not tracked by git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
