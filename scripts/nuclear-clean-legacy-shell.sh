#!/usr/bin/env bash
# Nuclear cleanup for machines migrating from legacy dotfiles (Antigen + OMZ,
# zsh-nvm/nvm, direnv, thefuck, pyenv shims in shell RC, etc.) to the shell-speedup
# stack (antidote, mise, pay-respects, …).
#
# Target OS: Ubuntu 22.04 and 24.04 (GNU sed, readlink -f, apt).
#
# Default: dry-run only (prints actions). No changes until you pass --execute.
#
# Usage:
#   ./scripts/nuclear-clean-legacy-shell.sh              # dry-run
#   ./scripts/nuclear-clean-legacy-shell.sh --execute  # perform cleanup
#
# Optional flags (mostly affect rm -rf targets; use with --execute for real deletes):
#   --remove-pyenv-root     rm -rf ~/.pyenv (all pyenv-installed interpreters)
#   --remove-fnm-root       rm -rf ~/.fnm
#   --remove-volta-root     rm -rf ~/.volta
#   --remove-conda-root     rm -rf ~/miniconda3 ~/anaconda3 ~/mambaforge ~/Miniconda3 ~/Anaconda3 (whichever exist)
#   --no-apt                skip apt purge/remove for direnv / thefuck / pyenv packages
#   --reset-atuin           rm -rf ~/.local/share/atuin (DESTROYS shell history DB)
#
set -euo pipefail

SCRIPT_NAME="${0##*/}"
EXECUTE=0
REMOVE_PYENV_ROOT=0
REMOVE_FNM_ROOT=0
REMOVE_VOLTA_ROOT=0
REMOVE_CONDA_ROOT=0
DO_APT=1
RESET_ATUIN=0

usage() {
    sed -n '1,22p' "$0" | tail -n +2
    printf '\nOptions:\n  --execute              apply changes (otherwise dry-run)\n'
    printf '  --remove-pyenv-root    delete ~/.pyenv\n'
    printf '  --remove-fnm-root      delete ~/.fnm\n'
    printf '  --remove-volta-root    delete ~/.volta\n'
    printf '  --remove-conda-root    delete common conda install dirs in \$HOME\n'
    printf '  --no-apt               skip apt package removals\n'
    printf '  --reset-atuin          delete ~/.local/share/atuin (history)\n'
}

while [[ "${1:-}" == -* ]]; do
    case "$1" in
        --execute) EXECUTE=1 ;;
        --remove-pyenv-root) REMOVE_PYENV_ROOT=1 ;;
        --remove-fnm-root) REMOVE_FNM_ROOT=1 ;;
        --remove-volta-root) REMOVE_VOLTA_ROOT=1 ;;
        --remove-conda-root) REMOVE_CONDA_ROOT=1 ;;
        --no-apt) DO_APT=0 ;;
        --reset-atuin) RESET_ATUIN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf '%s: unknown option %s\n' "${SCRIPT_NAME}" "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ "${1:-}" != "" ]]; then
    printf '%s: extra arguments: %s\n' "${SCRIPT_NAME}" "$*" >&2
    exit 2
fi

if [[ "${EXECUTE}" -eq 1 ]] && [[ "$(id -u)" -eq 0 ]]; then
    printf '%s: do not run with --execute as root; use your normal user (sudo only inside apt steps).\n' "${SCRIPT_NAME}" >&2
    exit 1
fi

log() { printf '\e[36m%s\e[0m\n' "$*" >&2; }
warn() { printf '\e[33m%s\e[0m\n' "$*" >&2; }
err() { printf '\e[31m%s\e[0m\n' "$*" >&2; }

BACKUP_ROOT="${HOME}/.dotfiles-nuclear-cleanup-backup-$(date +%Y%m%d%H%M%S)"

# Skip editing files that are symlinks into a dotfiles checkout (do not mangle tracked zshrc).
skip_if_dotfiles_symlink() {
    local f="${1:?}"
    if [[ ! -e "$f" ]]; then
        return 0
    fi
    if [[ -L "$f" ]]; then
        local target
        target="$(readlink -f "$f" 2>/dev/null || true)"
        if [[ -n "${target}" ]] && [[ "${target}" == *dotfiles* ]]; then
            log "skip (symlink into dotfiles): ${f} -> ${target}"
            return 1
        fi
    fi
    return 0
}

backup_file() {
    local f="${1:?}"
    [[ -f "$f" ]] || return 0
    local rel
    rel="${f//\//_}"
    rel="${rel#_}"
    mkdir -p "${BACKUP_ROOT}"
    cp -a "$f" "${BACKUP_ROOT}/${rel}.bak"
    log "backup: ${f} -> ${BACKUP_ROOT}/${rel}.bak"
}

run_apt() {
    local action="${1:?}"
    local pkg="${2:?}"
    if [[ "${DO_APT}" -ne 1 ]]; then
        log "apt skipped (--no-apt): ${action} ${pkg}"
        return 0
    fi
    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get not found; skipping package ${pkg}"
        return 0
    fi
    if [[ "${EXECUTE}" -ne 1 ]]; then
        log "dry-run apt: ${action} ${pkg}"
        return 0
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        apt-get "${action}" -y "${pkg}" || true
    else
        sudo apt-get "${action}" -y "${pkg}" || true
    fi
}

purge_if_installed() {
    local pkg="${1:?}"
    if dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "install ok installed"; then
        log "apt purge: ${pkg}"
        run_apt purge "${pkg}"
    else
        log "apt: package not installed (skip): ${pkg}"
    fi
}

apt_autoremove_once() {
    if [[ "${DO_APT}" -ne 1 ]] || [[ "${EXECUTE}" -ne 1 ]]; then
        if [[ "${DO_APT}" -eq 1 ]] && [[ "${EXECUTE}" -eq 0 ]]; then
            log "dry-run apt: autoremove"
        fi
        return 0
    fi
    if ! command -v apt-get >/dev/null 2>&1; then
        return 0
    fi
    if [[ "$(id -u)" -eq 0 ]]; then
        apt-get autoremove -y || true
    else
        sudo apt-get autoremove -y || true
    fi
}

remove_tree() {
    local path="${1:?}"
    local label="${2:?}"
    if [[ ! -e "${path}" ]]; then
        return 0
    fi
    if [[ "${EXECUTE}" -ne 1 ]]; then
        log "dry-run rm -rf ${label}: ${path}"
        return 0
    fi
    warn "rm -rf ${label}: ${path}"
    rm -rf "${path}"
}

strip_rc_file() {
    local f="${1:?}"
    [[ -f "$f" ]] || return 0
    if ! skip_if_dotfiles_symlink "$f"; then
        return 0
    fi
    if [[ "${EXECUTE}" -ne 1 ]]; then
        if grep -E -n \
            'nvm|NVM_DIR|direnv|thefuck|pyenv|PYENV_ROOT|rbenv|RUBY_ROOT|fnm|volta|conda initialize|mise activate|antigen|oh-my-zsh|zsh-nvm' \
            "$f" 2>/dev/null; then
            log "dry-run would rewrite (strip legacy lines/blocks): ${f}"
        fi
        return 0
    fi
    backup_file "$f"
    python3 - "${f}" <<'PY' || { err "python strip failed for ${f}"; return 1; }
import re
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8", errors="surrogateescape") as fh:
    text = fh.read()
orig = text

# Conda installer blocks
text = re.sub(
    r"\n?# >>> conda initialize >>>\n[\s\S]*?# <<< conda initialize <<<\n?",
    "\n",
    text,
    flags=re.MULTILINE,
)

# pyenv boilerplate (common three-liner + variants)
text = re.sub(
    r"\n?# --- pyenv[^\n]*\n[\s\S]*?eval \"\$\(pyenv init[- ]?[^)]*\)\"\s*\n?",
    "\n",
    text,
    flags=re.MULTILINE,
)
text = re.sub(
    r"\n?export PYENV_ROOT=\"\$HOME/\.pyenv\"\s*\nexport PATH=\"\$PYENV_ROOT/bin:\$PATH\"\s*\n"
    r'eval "\$\(pyenv init[- ]?[^)]*\)"\s*\n?',
    "\n",
    text,
    flags=re.MULTILINE,
)

# rbenv
text = re.sub(
    r"\n?export PATH=\"\$HOME/\.rbenv/bin:\$PATH\"\s*\n"
    r'eval "\$\(rbenv init[- ]?[^)]*\)"\s*\n?',
    "\n",
    text,
    flags=re.MULTILINE,
)

lines = text.splitlines(keepends=True)
out = []
for line in lines:
    # nvm single-line loader
    if re.search(r"\bnvm\.sh\b", line) or "NVM_DIR" in line or "/.nvm/nvm.sh" in line:
        continue
    if "lukechilds/zsh-nvm" in line or "zsh-nvm" in line:
        continue
    if "direnv hook" in line:
        continue
    if "thefuck" in line.lower():
        continue
    if re.search(r"\bpyenv init\b", line) or "PYENV_ROOT" in line:
        continue
    if "rbenv init" in line or ".rbenv/bin" in line:
        continue
    if ("fnm env" in line) or (re.search(r"\bfnm\b", line) and "multishell" in line):
        continue
    if "/.volta/" in line or "volta setup" in line.lower():
        continue
    if "antigen" in line.lower():
        continue
    if "/oh-my-zsh/" in line or re.search(r"\boh-my-zsh\.sh\b", line, re.I):
        continue
    if re.search(r"^\s*ZSH=.*oh-my-zsh", line, re.I):
        continue
    # duplicate mise activate (dotfiles .zshrc will add one)
    if re.match(r'\s*eval "\$\(mise activate zsh\)"\s*$', line):
        continue
    out.append(line)

text = "".join(out)
# collapse excessive blank lines
text = re.sub(r"\n{4,}", "\n\n\n", text)
if text != orig:
    with open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as fh:
        fh.write(text)
    print(f"rewrote: {path}", file=sys.stderr)
else:
    print(f"unchanged: {path}", file=sys.stderr)
PY
}

MODE="DRY-RUN"
if [[ "${EXECUTE}" -eq 1 ]]; then
    MODE="EXECUTE"
fi
log "=== ${SCRIPT_NAME} (${MODE}) ==="
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        warn "Detected OS ID='${ID:-unknown}' (not ubuntu). Script targets Ubuntu 22.04/24.04; apt/dpkg steps may not apply."
    fi
fi
if [[ "${EXECUTE}" -eq 0 ]]; then
    warn "Dry-run mode: no files removed and no apt changes. Re-run with --execute to apply."
else
    warn "EXECUTE: destructive changes will run. Backup root: ${BACKUP_ROOT}"
    mkdir -p "${BACKUP_ROOT}"
    printf '%s\n' "execute ${SCRIPT_NAME} $(date -Iseconds)" > "${BACKUP_ROOT}/MANIFEST.txt"
fi

# --- apt: remove distro packages that overlap the old stack ---
if [[ "${DO_APT}" -eq 1 ]]; then
    for pkg in direnv thefuck pyenv; do
        purge_if_installed "${pkg}"
    done
    apt_autoremove_once
fi

# --- directory trees (legacy managers / caches; never touch ~/.antidote) ---
remove_tree "${HOME}/.nvm" "nvm data"
remove_tree "${HOME}/Repos/antigen" "legacy antigen (Repos)"
remove_tree "${HOME}/repos/antigen" "legacy antigen (repos lowercase)"
remove_tree "${HOME}/workspaces/public/antigen" "legacy antigen (public workspaces)"
remove_tree "${HOME}/.antigen" "antigen bundle cache (not antidote)"
remove_tree "${HOME}/.zsh_plugins.zsh" "cached antidote bundle (regenerated on next shell)"

if [[ "${REMOVE_PYENV_ROOT}" -eq 1 ]]; then
    remove_tree "${HOME}/.pyenv" "pyenv root (--remove-pyenv-root)"
else
    log "note: ~/.pyenv left intact (pass --remove-pyenv-root to delete all pyenv interpreters)"
fi

if [[ "${REMOVE_FNM_ROOT}" -eq 1 ]]; then
    remove_tree "${HOME}/.fnm" "fnm root"
fi
if [[ "${REMOVE_VOLTA_ROOT}" -eq 1 ]]; then
    remove_tree "${HOME}/.volta" "volta root"
fi

if [[ "${REMOVE_CONDA_ROOT}" -eq 1 ]]; then
    for d in "${HOME}/miniconda3" "${HOME}/Miniconda3" "${HOME}/anaconda3" "${HOME}/Anaconda3" \
             "${HOME}/mambaforge" "${HOME}/miniforge3" "${HOME}/Micromamba" \
             "${HOME}/.local/share/micromamba"; do
        remove_tree "${d}" "conda/mamba (--remove-conda-root)"
    done
fi

if [[ "${RESET_ATUIN}" -eq 1 ]]; then
    remove_tree "${HOME}/.local/share/atuin" "atuin history DB (--reset-atuin)"
fi

# zcompdump / old completion cache
if [[ "${EXECUTE}" -eq 1 ]]; then
    shopt -s nullglob
    for z in "${HOME}"/.zcompdump*; do
        log "remove: ${z}"
        rm -f "${z}"
    done
    shopt -u nullglob
else
    comp=$(ls -1 "${HOME}"/.zcompdump* 2>/dev/null || true)
    if [[ -n "${comp}" ]]; then
        log "dry-run: would rm -f ${HOME}/.zcompdump*"
    fi
fi

# --- strip init files ---
for rc in \
    "${HOME}/.zshrc" \
    "${HOME}/.zprofile" \
    "${HOME}/.zshenv" \
    "${HOME}/.zlogin" \
    "${HOME}/.zshrc.local" \
    "${HOME}/.bashrc" \
    "${HOME}/.bash_profile" \
    "${HOME}/.profile"; do
    strip_rc_file "${rc}"
done

# --- uv tool: thefuck if present ---
if command -v uv >/dev/null 2>&1; then
    if uv tool list 2>/dev/null | grep -q '^thefuck'; then
        if [[ "${EXECUTE}" -eq 1 ]]; then
            log "uv tool uninstall thefuck"
            uv tool uninstall thefuck || true
        else
            log "dry-run: uv tool uninstall thefuck"
        fi
    fi
fi

# --- pipx: thefuck if present ---
if command -v pipx >/dev/null 2>&1; then
    if { pipx list --short 2>/dev/null || pipx list 2>/dev/null; } | grep -qx 'thefuck'; then
        if [[ "${EXECUTE}" -eq 1 ]]; then
            log "pipx uninstall thefuck"
            pipx uninstall thefuck || true
        else
            log "dry-run: pipx uninstall thefuck"
        fi
    fi
fi

log "=== done ==="
if [[ "${EXECUTE}" -eq 1 ]]; then
    log "Backups (if any rewrites): ${BACKUP_ROOT}"
    warn "Open a NEW terminal after this. Then run dotfiles zsh/install.sh and mise install as usual."
else
    warn "Dry-run finished. Review output, then: ${SCRIPT_NAME} --execute [extra flags]"
fi
