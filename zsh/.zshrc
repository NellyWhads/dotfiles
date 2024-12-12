source $HOME/Repos/antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle common-aliases
antigen bundle command-not-found
antigen bundle cp
antigen bundle git
antigen bundle debian
antigen bundle thefuck
antigen bundle safe-paste
antigen bundle tmux
antigen bundle direnv

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

antigen apply

# Source bash profile if it exists
[[ -f ~/.bash_profile ]] && source ~/.bash_profile

# Show hostname for in theme
export AM_SSH_SYM=$(hostname -s)
export AM_DOCKER_SYM=$(hostname -s) # Docker stores the container ID as hostname

# Git worktree aliases
alias gw='git worktree'
alias gwl='git worktree list'
alias gwa='git worktree add'
alias gwac='git worktree add --checkout'
alias gwp='git worktree prune'

# Custom git status alias
alias gwd='git rev-parse --show-toplevel'
alias gst='git worktree prune ; git worktree list | grep --color -E "$(gwd).*|$" ; git --no-pager branch ; git status --short ; git --no-pager stash list'

# VSCode Insiders Alias
alias icode='code-insiders'

# Add user packages/scripts/tools to path
PATH=$PATH:"$HOME/.local/bin"

# Add fuck alias
eval "$(thefuck --alias)"

# TORC_ML
export PYTORC_AWS_PROFILE=pytorc-dev
