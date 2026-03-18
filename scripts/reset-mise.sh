#!/usr/bin/env bash
# Reset mise config and installs so you can re-run the dotfiles mise install
# and verify tools + completion sync from scratch.
# Usage: ./scripts/reset-mise.sh   (run from repo root)

set -e

echo "This will remove:"
echo "  - mise installs, plugins, shims (~/.local/share/mise)"
echo "  - mise state e.g. trust (~/.local/state/mise)"
echo "  - mise cache (optional)"
echo "  - mise-completions-sync output (~/.local/share/mise-completions)"
echo "  - zsh compdump (~/.zcompdump*) so completions rebuild"
echo ""
read -r -p "Continue? [y/N] " response
case "${response}" in
    [yY]) ;;
    *) echo "Aborted."; exit 0 ;;
esac

# Mise data (installs, plugins, shims)
if [[ -d "${HOME}/.local/share/mise" ]]; then
    echo "Removing ~/.local/share/mise ..."
    rm -rf "${HOME}/.local/share/mise"
fi

# Mise state (trust, etc.)
if [[ -d "${HOME}/.local/state/mise" ]]; then
    echo "Removing ~/.local/state/mise ..."
    rm -rf "${HOME}/.local/state/mise"
fi

# Mise cache (optional; safe to delete per docs)
for dir in "${HOME}/.cache/mise" "${HOME}/Library/Caches/mise" 2>/dev/null; do
    if [[ -d "${dir}" ]]; then
        echo "Removing ${dir} ..."
        rm -rf "${dir}"
    fi
done

# mise-completions-sync output
COMPLETIONS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/mise-completions"
if [[ -d "${COMPLETIONS_DIR}" ]]; then
    echo "Removing ${COMPLETIONS_DIR} ..."
    rm -rf "${COMPLETIONS_DIR}"
fi

# Zsh completion cache so compinit rebuilds with fresh completions
if compgen -G "${HOME}/.zcompdump"* >/dev/null 2>&1; then
    echo "Removing ~/.zcompdump* ..."
    rm -f "${HOME}/.zcompdump"*
fi

echo ""
echo "Done. Next steps:"
echo "  1. Re-link config and reinstall tools (from repo root):"
echo "     cd mise && ./install.sh"
echo "  2. Open a new terminal (or run: exec zsh) so the shell sees mise and new completions."
echo "  3. Trust the config when prompted, then run: mise-completions-sync"
echo "     (or rely on the postinstall hook; completions should already be synced)."
