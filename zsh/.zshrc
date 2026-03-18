REPOS_DIR="${HOME}/workspaces/public"

if ! echo "$PATH" | grep -q "/usr/local/bin" ; then
    export PATH="${PATH}:/usr/local/bin"
fi
if ! echo "${PATH}" | grep -q "${HOME}/.local/bin" ; then
    export PATH="${PATH}:${HOME}/.local/bin"
fi

# mise-completions-sync: must be before compinit (which runs at antigen apply)
fpath=("${XDG_DATA_HOME:-${HOME}/.local/share}/mise-completions/zsh" "${fpath[@]}")

source ${REPOS_DIR}/antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle common-aliases
antigen bundle command-not-found
antigen bundle cp
antigen bundle git
antigen bundle debian
antigen bundle safe-paste
antigen bundle tmux
antigen bundle mise
antigen bundle uv

antigen theme nellywhads/alien-minimal alien-minimal

antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle Valiev/almostontop
antigen bundle zdharma-continuum/history-search-multi-word@main
antigen bundle lukechilds/zsh-nvm
antigen bundle willghatch/zsh-saneopt
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle djui/alias-tips
antigen bundle zdharma-continuum/fast-syntax-highlighting
antigen bundle z-shell/zsh-lsd --branch=main

antigen apply

# Show hostname for in theme
export AM_SSH_SYM=$(hostname -s)
export AM_DOCKER_SYM=$(hostname -s) # Docker stores the container ID as hostname

# Git worktree aliases
alias gw='git worktree'
alias gwl='git worktree list'
alias gwa='git worktree add'
alias gwr='git worktree remove'
alias gwac='git worktree add --checkout'
alias gwp='git worktree prune'
alias glogb='git log --oneline --decorate --graph --branches'

# Custom git aliases
alias gwd='git rev-parse --show-toplevel'
alias gst='git worktree prune ; git worktree list | grep --color -E "$(gwd).*|$" ; git --no-pager branch ; git status --short ; git --no-pager stash list'
alias grbom='git fetch origin $(git_main_branch) && git rebase origin/$(git_main_branch)'
alias grbiom='git fetch origin $(git_main_branch) && git rebase -i origin/$(git_main_branch)'

# Workaround for ghostty
if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi
