# zsh
autoload -Uz compinit && compinit # 補完有効

# alias
alias x86='arch -x86_64 zsh'
alias arm='arch -arm64 zsh'
alias lg='lazygit'
alias gia='create_gitignore'
alias get_idf='. $HOME/esp/esp-idf/export.sh'

# Apple silicon 向けの設定
if [[ $(uname -m) == 'arm64' ]]; then
    export PATH="/opt/homebrew/bin:$PATH" # brew arm64 対応のため
fi

# .local/binをPATHに追加
export PATH="$HOME/.local/bin:$PATH"

export XDG_CONFIG_HOME=${HOME}/.config

# python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export LDFLAGS="-L/usr/local/opt/zlib/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include"
export PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig"

# golang
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# nodejs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ruby
export PATH="$PATH:$HOME/.rbenv/bin"
eval "$(rbenv init -)"

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
export PATH="$HOME/.local/bin:$PATH"

# direnv — auto-load .envrc when entering a directory
eval "$(direnv hook zsh)"

# Machine-local overrides (not tracked by git)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
