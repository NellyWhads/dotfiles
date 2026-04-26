# ~/.zshrc — managed by dotfiles repo
# Goals: fast startup, declarative plugin list, cross-platform (macOS/Linux).

# ---------- PATH (early, before anything sources binaries) ----------
typeset -U path PATH    # de-dup
path=(
    "$HOME/.local/bin"
    "/opt/homebrew/bin"           # macOS Apple Silicon homebrew
    "/usr/local/bin"
    $path
)
export PATH

REPOS_DIR="${HOME}/workspaces/public"

# ---------- Resolve dotfiles dir for sourcing peers (aliases.zsh, plugin list)
# Follow symlinks: ~/.zshrc points at <repo>/zsh/.zshrc, so resolve and dirname.
ZSH_DOTFILES="${ZSH_DOTFILES:-${${(%):-%x}:A:h}}"

# ---------- mise activation (was hidden inside OMZ mise plugin) ----------
# mise lays down per-tool completions under XDG_DATA_HOME/mise-completions/zsh
# via mise-completions-sync. mise's OWN completion (_mise) needs to be
# generated separately — do that here, lazily, if it's missing or stale.
_MISE_COMP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/mise-completions/zsh"
fpath=("$_MISE_COMP_DIR" $fpath)
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

# ---------- zoxide: smarter `cd` with frecency. `z foo` jumps to the
# best match by usage; `zi` opens an fzf picker. ----------
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ---------- pay-respects: type `f` after a typo to fix and re-run ----------
if command -v pay-respects >/dev/null 2>&1; then
    eval "$(pay-respects --alias f)"
fi

# ---------- atuin: SQLite-backed shell history.
# We init with --disable-up-arrow --disable-ctrl-r so HSM keeps Ctrl-R
# (you said you like its UI). atuin still records every command into
# ~/.local/share/atuin/history.db; query with `atuin search <pattern>`.
# To switch to atuin's Ctrl-R fully, drop the two --disable flags. ----------
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
fi

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
