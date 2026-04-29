# ssh-completion.zsh — SSH-family tab completion from ~/.ssh/config
#
# Sourced by .zshrc after compinit + antidote. Must stay post-compinit;
# do not add to .zsh_plugins.txt (antidote loads before phase-2 compinit).
#
# Problem solved: _ssh_hosts always returns early once _hosts succeeds
# (known_hosts has entries), so its own Host-from-config parser never runs.
# Setting ':completion:*:hosts' makes _hosts use our list instead of reading
# files, so config Host aliases appear and raw known_hosts IDs don't dominate.
#
# Performance: ~3ms cold parse → cached in ~/.cache/dotfiles-ssh-hosts keyed
# on mtime+size of ~/.ssh/config. Warm path (every normal startup): ~0.14ms.
# Cache write is backgrounded (&!) so it never blocks startup.
#
# Caveat: editing only an Include'd file (not ~/.ssh/config itself) won't
# auto-invalidate the cache. Run `touch ~/.ssh/config` to force a refresh.

() {
    emulate -L zsh -o extended_glob -o typeset_silent
    [[ -r "${HOME}/.ssh/config" ]] || return

    local cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}"
    [[ -d "${cache_dir}" && -w "${cache_dir}" ]] || cache_dir="${TMPDIR:-/tmp}"
    local cache="${cache_dir}/dotfiles-ssh-hosts"
    local sig_file="${cache}.sig"
    local sig
    sig="$(stat -f '%m %z' "${HOME}/.ssh/config" 2>/dev/null || stat -c '%Y %s' "${HOME}/.ssh/config" 2>/dev/null)"

    local -a ssh_hosts
    if [[ -r "${sig_file}" && -r "${cache}" && "$(<${sig_file})" == "${sig}" ]]; then
        ssh_hosts=( "${(@f)$(<${cache})}" )
    else
        local -A seen
        _parse_ssh_config() {
            local file="${1}" l k v g
            [[ -r "${file}" ]] || return
            local canon="${file:A}"
            (( ${+seen[${canon}]} )) && return; seen[${canon}]=1
            while IFS= read -r l || [[ -n "${l}" ]]; do
                l="${(M)l##[^#]##}"; l="${l##[[:blank:]]##}"
                [[ -z "${l}" ]] && continue
                k="${(L)l%%[[:blank:]=]*}"
                v="${l#*[[:blank:]=]}"; v="${v##[[:blank:]=]##}"
                [[ "${k}" == host ]] && for g in ${(z)v}; do
                    [[ "${g}" == *[\*\?\[]* ]] || ssh_hosts+=("${g}")
                done
                [[ "${k}" == include ]] && for g in ${~${v//'~'/${HOME}}}(N); do
                    _parse_ssh_config "${g}"
                done
            done < "${file}"
        }
        _parse_ssh_config "${HOME}/.ssh/config"
        unfunction _parse_ssh_config
        # Write cache in background — never blocks startup.
        { print -l "${ssh_hosts[@]}" >| "${cache}" && print -rn "${sig}" >| "${sig_file}" } &!
    fi

    (( ${#ssh_hosts} )) && zstyle ':completion:*:hosts' hosts "${ssh_hosts[@]}"
}

# Drop the passwd-backed "users" tag for SSH-family commands so fzf-tab
# doesn't surface macOS _service accounts alongside hostnames.
for _ssh_cmd in ssh scp rsync sftp; do
    zstyle ":completion:*:${_ssh_cmd}:*" tag-order '! users' '-'
done
unset _ssh_cmd
