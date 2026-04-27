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

# --- find-style shortcuts (powered by fd) ---
# These are FAST SHORTCUTS for the common cases, NOT a replacement for
# find. /usr/bin/find still does everything it always did — reach for
# it when you need predicates fd doesn't have (-newer, -mtime, -prune,
# -mount, complex -exec ... \;, etc.).
#
# Examples:
#   ff foo               # find files matching "foo" (substring or regex)
#   ffd build            # find directories named build
#   ffe py               # find *.py files (no dot, no glob needed)
#   ffi readme           # case-insensitive — matches README, Readme, etc.
#   ffh dotfile          # include hidden/dotfiles in the search
#   ffa pattern          # show ALL: hidden + .gitignored
if command -v fd >/dev/null 2>&1; then
    alias ff='fd'              # default: respects .gitignore, skips hidden
    alias ffd='fd -t d'        # directories only
    alias ffe='fd -e'          # by extension: ffe py == fd -e py
    alias ffi='fd -i'          # case-insensitive
    alias ffh='fd -H'          # include hidden / dotfiles
    alias ffa='fd -HI'         # include hidden AND .gitignored
fi

# OMZ lib/directories.zsh supplies `md`/`rd`; if the antidote cache path ever
# misses, these one-liners keep mkdir ergonomics without maintaining the full lib.
(( ${+aliases[md]} )) || alias md='mkdir -p'
(( ${+aliases[rd]} )) || alias rd='rmdir'
