# git-alias-completion.zsh — make Tab after OMZ-style git aliases use _git, not _files.
#
# Problem: aliases like glog='git log …' define a *new* command word. Unless
# complete_aliases is set (and/or compdef maps the alias to the git-* service),
# zsh completes "glog" with file names — not branches/tags/commits.
#
# Load after the antidote bundle (git.plugin.zsh) and compinit — see .zshrc.

emulate -L zsh

# Expand aliases for completion so "glog <Tab>" is completed like "git log …".
setopt complete_aliases

# Belt-and-suspenders: map common oh-my-zsh git plugin aliases to the same
# _git services OMZ uses for functions (see git.plugin.zsh compdef lines).
# Only register when the alias exists (user may trim the plugin list).
if (( ${+functions[compdef]} )); then
    local pair
    local -a _git_omz_alias_pairs=(
        g=git
        glog=git-log
        gloga=git-log
        glol=git-log
        glo=git-log
        glgg=git-log
        glgga=git-log
        glgm=git-log
        glods=git-log
        glod=git-log
        glola=git-log
        glols=git-log
        gb=git-branch
        gba=git-branch
        gbd=git-branch
        gbD=git-branch
        gco=git-checkout
        gcb=git-checkout
        gcB=git-checkout
        gcor=git-checkout
        gd=git-diff
        gdca=git-diff
        gdcw=git-diff
        gds=git-diff
        gdw=git-diff
        gdup=git-diff
        gdt=git-diff-tree
        gsw=git-switch
        gswc=git-switch
        gf=git-fetch
        gfa=git-fetch
        gfo=git-fetch
        gst=git-status
        gss=git-status
        gsb=git-status
        gp=git-push
        gl=git-pull
        gr=git-remote
        gcl=git-clone
    )
    for pair in "${_git_omz_alias_pairs[@]}"; do
        [[ -n "${aliases[${pair%%=*}]:-}" ]] || continue
        compdef "_git" "${pair}" 2>/dev/null || true
    done
    unset pair _git_omz_alias_pairs

    # Hyphenated "git-log" style wrappers (alias or external command).
    if [[ -n "${aliases[git-log]:-}" ]] || (( ${+commands[git-log]} )); then
        compdef _git git-log=git-log 2>/dev/null || true
    fi
fi
