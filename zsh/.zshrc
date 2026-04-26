# ~/.zshrc — managed by dotfiles repo
# Goals: fast startup, declarative plugin list, cross-platform (macOS/Linux).

# ---------- PATH (early, before anything sources binaries) ----------
# Order matters: homebrew goes BEFORE ~/.cargo/bin so brew's cargo wins
# over rustup's (rustup's stable can lag behind for new edition features).
# ~/.cargo/bin still needs to be on PATH so cargo-installed binaries
# (pay-respects, etc.) are found.
# Non-existent paths are harmless — zsh just won't find anything in them.
typeset -U path PATH    # de-dup
path=(
    "$HOME/.local/bin"                          # mise binary, starship (Ubuntu fallback)
    "/opt/homebrew/bin"                         # macOS Apple Silicon homebrew
    "/home/linuxbrew/.linuxbrew/bin"            # Linuxbrew (if used)
    "/usr/local/bin"                            # macOS Intel homebrew, generic
    "$HOME/.cargo/bin"                          # cargo-installed binaries
    $path
)
export PATH

REPOS_DIR="${HOME}/workspaces/public"

# ---------- History size ----------
# zsh's defaults are 1000 / 2000 — way too small for any modern shell.
# zsh-saneopt enables HIST_IGNORE_DUPS / SHARE_HISTORY / etc. but doesn't
# set the size. Atuin keeps its own SQLite history regardless of these.
HISTSIZE=100000
SAVEHIST=100000

# ---------- Resolve dotfiles dir for sourcing peers (aliases.zsh, plugin list)
# Follow symlinks: ~/.zshrc points at <repo>/zsh/.zshrc, so resolve and dirname.
ZSH_DOTFILES="${ZSH_DOTFILES:-${${(%):-%x}:A:h}}"

# ---------- mise activation (was hidden inside OMZ mise plugin) ----------
# mise lays down per-tool completions under XDG_DATA_HOME/mise-completions/zsh
# via mise-completions-sync. mise's OWN completion (_mise) needs to be
# generated separately — do that here, lazily, if it's missing or stale.
_MISE_COMP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/mise-completions/zsh"
# ~/.zfunc: drop-in dir for local/tool-generated completions (_mytool files).
# Tools should write their _completion file here and optionally `rm ~/.zcompdump`
# to invalidate the cache — they must NOT call compinit or touch ~/.zshrc.
mkdir -p "${HOME}/.zfunc"
fpath=("$_MISE_COMP_DIR" "${HOME}/.zfunc" $fpath)
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
    if [[ ! -r "${_MISE_COMP_DIR}/_mise" || \
          "$(command -v mise)" -nt "${_MISE_COMP_DIR}/_mise" ]]; then
        mkdir -p "$_MISE_COMP_DIR"
        mise completion zsh >| "${_MISE_COMP_DIR}/_mise" 2>/dev/null
    fi
fi
unset _MISE_COMP_DIR

# ---------- ZSH_CACHE_DIR for OMZ-style plugins -----------
# Several OMZ plugins (e.g. plugins/uv) write generated completions to
# $ZSH_CACHE_DIR/completions and reference $ZSH_CACHE_DIR at source time.
# OMZ normally sets this; outside the framework we have to ourselves.
# APPEND (not prepend) so mise-completions-sync's authoritative versions
# win over the OMZ plugin's runtime-generated ones (which fail when a shim
# can't resolve a tool version, e.g. `uv` outside a mise-aware directory).
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh}"
mkdir -p "$ZSH_CACHE_DIR/completions"
fpath+=("$ZSH_CACHE_DIR/completions")

# ---------- antidote plugin loader ----------
# antidote install locations across platforms:
#   macOS (brew):    /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
#   Linux (brew):    /home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh
#   Arch (AUR):      /usr/share/zsh-antidote/antidote.zsh
#   Ubuntu (apt):    /usr/share/zsh-antidote/antidote.zsh
#   git fallback:    ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
for _antidote_path in \
    "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" \
    "/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh" \
    "/usr/share/zsh-antidote/antidote.zsh" \
    "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"; do
    if [[ -r "$_antidote_path" ]]; then
        source "$_antidote_path"
        break
    fi
done
unset _antidote_path

# ---------- Robust completion init (the two-phase pattern) ----------
# Why two phases:
#   Phase 1: compinit defines `compdef` so plugins that call it during sourcing
#            don't fail with "command not found: compdef".
#   Phase 2: After the bundle has appended _completion files to fpath,
#            `compinit -C` picks them up (uses the cached dump, no rescan
#            cost) so things like _uv, _git, _docker actually load.
# This is what fixes the "uv/git autocomplete sometimes doesn't work" bug.
# Cost: ~5ms for the second compinit. Worth it.
ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.zcompdump"
autoload -Uz compinit
if [[ -n "${ZSH_COMPDUMP}"(#qN.mh+24) ]]; then
    # Dump is older than 24h (or missing) — full rescan with security check.
    compinit -d "$ZSH_COMPDUMP"
else
    # Fast path — trust the dump.
    compinit -C -d "$ZSH_COMPDUMP"
fi

# Static bundle file: regenerate only when the source list is newer.
zsh_plugins_txt="${ZSH_DOTFILES}/.zsh_plugins.txt"
zsh_plugins_zsh="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"
if [[ -r "$zsh_plugins_txt" ]]; then
    if [[ ! "$zsh_plugins_zsh" -nt "$zsh_plugins_txt" ]]; then
        (antidote bundle <"$zsh_plugins_txt" >"$zsh_plugins_zsh")
    fi
    source "$zsh_plugins_zsh"
    # Phase 2: re-init to pick up _foo files that plugins added to fpath.
    compinit -C -d "$ZSH_COMPDUMP"
fi

# SSH completion: config Host aliases + suppress passwd users.
# Must load after compinit — see zsh/ssh-completion.zsh for details.
source "${ZSH_DOTFILES}/ssh-completion.zsh"

# ---------- OMZ git library helpers ----------
# OMZ's plugins/git provides the aliases (gpsup, gst, etc.) but their
# implementation references functions like `git_current_branch` and
# `git_main_branch` which live in OMZ's lib/git.zsh — not in the plugin
# subdir. Antidote's `path:plugins/git` only pulls the plugin dir, so
# we source the lib explicitly from antidote's cache.
# Our personal aliases.zsh also relies on `git_main_branch` for `grbom`.
for _omz_git_lib in \
    "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/git.zsh" \
    "$HOME/.cache/antidote/github.com/ohmyzsh/ohmyzsh/lib/git.zsh"; do
    if [[ -r "$_omz_git_lib" ]]; then
        source "$_omz_git_lib"
        break
    fi
done
unset _omz_git_lib

# ---------- fzf key bindings + completions (cross-platform) ----------
# Use fd as the file source if present (faster, respects .gitignore by
# default). Use bat for previews if present.
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
if command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || cat {}'"
fi

for _fzf_path in \
    "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" \
    "/usr/share/fzf/key-bindings.zsh" \
    "/usr/share/doc/fzf/examples/key-bindings.zsh"; do
    if [[ -r "$_fzf_path" ]]; then
        source "$_fzf_path"
        break
    fi
done
unset _fzf_path
for _fzf_comp in \
    "/opt/homebrew/opt/fzf/shell/completion.zsh" \
    "/usr/share/fzf/completion.zsh" \
    "/usr/share/doc/fzf/examples/completion.zsh"; do
    if [[ -r "$_fzf_comp" ]]; then
        source "$_fzf_comp"
        break
    fi
done
unset _fzf_comp

# fzf-git.sh: Ctrl-G [B/T/H/R/S/W] for fuzzy branches/tags/hashes/remotes/
# status/worktrees, all with live diff/log preview. Cloned by zsh/install.sh.
[[ -r "${HOME}/.local/share/fzf-git.sh/fzf-git.sh" ]] && \
    source "${HOME}/.local/share/fzf-git.sh/fzf-git.sh"

# ---------- Edit current command in $EDITOR (Ctrl-X Ctrl-E) ----------
# Built-in zsh widget — not bound by default. Pressing Ctrl-X Ctrl-E
# pops the current command line into $EDITOR. Save and quit, and zsh
# runs the (possibly multi-line) edited version. Perfect for editing
# long `&&`/`||`/`|` chains, multi-line scripts, or anything that
# doesn't fit on one screen line.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ---------- Word-boundary tweaks ----------
# zsh's default WORDCHARS includes /, ., -, _, etc. — so Alt-Backspace
# deletes the whole path back to the previous space, not one path
# component. `select-word-style bash` restores the alnum-only word
# behavior oh-my-zsh used to give us via WORDCHARS=''.
autoload -Uz select-word-style
select-word-style bash

# Ctrl-Backspace and Alt-Backspace both delete the previous word.
# Most terminals send ^H for Ctrl-Backspace; ^[^? and \e\b are the two
# common Alt-Backspace encodings across terminals/keymaps.
bindkey '^H'   backward-kill-word    # Ctrl-Backspace
bindkey '^[^?' backward-kill-word    # Alt-Backspace (most terminals)
bindkey '\e\b' backward-kill-word    # Alt-Backspace (alternate encoding)

# ---------- zoxide: smarter `cd` with frecency. `z foo` jumps to the
# best match by usage; `zi` opens an fzf picker. ----------
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ---------- pay-respects: type `f` after a typo to fix and re-run ----------
# Correct CLI form is `pay-respects <shell> [--alias <name>]` — the shell
# name is positional, not a flag.
if command -v pay-respects >/dev/null 2>&1; then
    eval "$(pay-respects zsh --alias f)"
fi

# ---------- atuin: SQLite-backed shell history.
# We init with --disable-up-arrow --disable-ctrl-r so HSM keeps Ctrl-R
# (its multi-word UI is great as the default). atuin records every
# command into ~/.local/share/atuin/history.db regardless.
#
# Hybrid keybinding strategy:
#   Ctrl-R = HSM (default, fast, multi-word fuzzy)
#   Alt-R  = atuin's full TUI (Tab cycles Global → Host → Session → Directory)
#   `atuin search <pattern>` from CLI for ad-hoc queries
#   `atuin stats` for fun (top commands, longest sessions, etc.) ----------
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
    # The widget name is `atuin-search` (atuin's `zle -N atuin-search
    # _atuin_search` makes the underscore-prefix the inner function and
    # the dash-prefix the actual ZLE widget — bindkey wants the widget).
    # Atuin defines this widget regardless of --disable-ctrl-r; we just
    # bind it to keys that don't fight HSM. Multiple bindings to handle
    # different terminals' encodings:
    #   ^X^R      universal chord — works in every terminal, every mode
    #   CSI u    Ctrl-Shift-R when the terminal uses the kitty keyboard
    #            protocol (ghostty, kitty, wezterm by default; iTerm2 needs
    #            the "Report modifiers using CSI u" setting enabled).
    # Note: legacy terminal mode can't distinguish Ctrl-Shift-R from Ctrl-R,
    # which is why we don't try to bind a literal `^R` for Shift here.
    bindkey '^X^R'      atuin-search    # Ctrl-X Ctrl-R (universal)
    bindkey '^[[82;5u'  atuin-search    # Ctrl-Shift-R, iTerm2-style CSI u
    bindkey '^[[114;6u' atuin-search    # Ctrl-Shift-R, kitty-style CSI u

    # ---- Append-from-atuin (chain-mode) ----
    # Default atuin-search REPLACES the current buffer. This sibling
    # widget INSERTS the selected command at the cursor instead, so you
    # can chain multiple history hits:
    #   1. Ctrl-X Ctrl-Y, find cmd1, Enter           → buffer is "cmd1"
    #   2. type " && "                                → buffer is "cmd1 && "
    #   3. Ctrl-X Ctrl-Y, find cmd2, Enter           → buffer is "cmd1 && cmd2"
    #   4. (repeat)                                   → "cmd1 && cmd2 && cmd3"
    #   5. Enter to run, or Ctrl-X Ctrl-E to massage further in $EDITOR.
    _atuin_yank_at_cursor() {
        local output
        output=$(__atuin_search_cmd "$@")
        zle reset-prompt
        if [[ -n "$output" ]]; then
            LBUFFER+="$output"
        fi
    }
    zle -N _atuin_yank_at_cursor
    bindkey '^X^Y' _atuin_yank_at_cursor   # Ctrl-X Ctrl-Y ("eXtended Yank")
fi

# ---------- fzf-based history yank-at-cursor (HSM-equivalent data) ----------
# Wrapping HSM directly is fragile (it calls .accept-line internally, which
# would execute the line before our wrapper can capture). Instead, this
# widget reads zsh's history file (the same source HSM uses) and pipes
# through fzf for picking, then inserts at cursor.
#
# Use this when you want chain-mode search backed by the plain zsh history
# rather than atuin's SQLite db (e.g. for compatibility with non-atuin
# machines, or when you specifically want HSM's data set).
_zsh_history_yank_at_cursor() {
    if ! command -v fzf >/dev/null 2>&1; then
        zle -M "fzf not found — Ctrl-X Y needs fzf installed."
        return 1
    fi
    local picked
    # `fc -rln 1` = list history newest-first, no line numbers, starting at 1.
    picked=$(fc -rln 1 | awk '!seen[$0]++' | fzf --tiebreak=index --no-sort \
        --prompt='zsh-history > ' \
        --preview-window=hidden \
        --height=40%)
    if [[ -n "$picked" ]]; then
        LBUFFER+="$picked"
    fi
    zle reset-prompt
}
zle -N _zsh_history_yank_at_cursor
bindkey '^XY' _zsh_history_yank_at_cursor   # Ctrl-X Y (no second Ctrl)

# ---------- aliases / functions ----------
[[ -r "${ZSH_DOTFILES}/aliases.zsh" ]] && source "${ZSH_DOTFILES}/aliases.zsh"

# ---------- ghostty workaround ----------
if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi

# ---------- Starship prompt ----------
# Must come AFTER plugins so it wins the PROMPT setting. Starship's container
# module auto-detects when you're inside a Docker/Podman container and renders
# the indicator (configured in zsh/starship.toml symlinked to ~/.config/).
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ---------- machine-local overrides (NOT tracked) ----------
# Drop machine-specific env (work secrets, SSO profiles, etc.) here:
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
