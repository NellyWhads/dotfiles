# Personal aliases. Sourced from .zshrc.
#
# The vast majority of formerly-inline aliases now come from community
# plugins listed in .zsh_plugins.txt:
#   - lsd:        z-shell/zsh-lsd
#   - tmux ta/ts/...:  ohmyzsh/ohmyzsh path:plugins/tmux
#   - cpv (rsync):     ohmyzsh/ohmyzsh path:plugins/cp
#   - cp/mv/rm -i:     ohmyzsh/ohmyzsh path:plugins/common-aliases
#   - safe-paste:      ohmyzsh/ohmyzsh path:plugins/safe-paste (and zsh built-in)
#   - apt aliases:     ohmyzsh/ohmyzsh path:plugins/debian
#   - uv aliases:      ohmyzsh/ohmyzsh path:plugins/uv
#
# This file holds only the truly personal stuff — git worktree workflow
# helpers that don't have a community equivalent.

# --- Git worktree workflow (Neil's personal flow) ---
alias gw='git worktree'
alias gwl='git worktree list'
alias gwa='git worktree add'
alias gwr='git worktree remove'
alias gwac='git worktree add --checkout'
alias gwp='git worktree prune'
alias glogb='git log --oneline --decorate --graph --branches'

alias gwd='git rev-parse --show-toplevel'
alias gst='git worktree prune ; git worktree list | grep --color -E "$(gwd).*|$" ; git --no-pager branch ; git status --short ; git --no-pager stash list'
alias grbom='git fetch origin $(git_main_branch) && git rebase origin/$(git_main_branch)'
alias grbiom='git fetch origin $(git_main_branch) && git rebase -i origin/$(git_main_branch)'

# --- fkill: pick processes via fzf, kill selected ---
# Usage: `fkill` (default SIGTERM) or `fkill 9` (SIGKILL).
# Tab multi-selects; Enter sends the signal.
fkill() {
    local pids
    pids=$(ps -ef | sed 1d | fzf -m \
        --header="[fkill: Tab to multi-select, Enter to send signal ${1:-15}]" \
        --preview='echo {}' --preview-window=down:3:wrap \
        | awk '{print $2}')
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -"${1:-15}"
    fi
}
