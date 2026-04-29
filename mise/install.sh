#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------mise Installation--------" 1>&2

MISE_DIR="$(pwd)"

printf '\e[34m%s\e[0m\n' "Installing mise..." 1>&2
bash -c 'curl https://mise.run | sh'

if [ -z "${SKIP_MISE_TOOL_INSTALL:-}" ]; then
    printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
    # Modern mise uses ~/.config/mise/config.toml (with subdir) as the global
    # config. The legacy ~/.config/mise.toml location isn't reliably picked up,
    # which is why `uv` shim resolution kept failing with "No version is set".
    # Migrate any legacy symlink and create the new one.
    LEGACY_LINK="${HOME}/.config/mise.toml"
    NEW_LINK="${HOME}/.config/mise/config.toml"
    if [ -L "$LEGACY_LINK" ] || [ -f "$LEGACY_LINK" ]; then
        rm -f "$LEGACY_LINK"
    fi
    mkdir -p "${HOME}/.config/mise"
    ln -sfn "${MISE_DIR}/mise.toml" "$NEW_LINK"

    printf '\e[34m%s\e[0m\n' "Installing mise tools..." 1>&2
    bash -c "${HOME}/.local/bin/mise install"
else
    printf '\e[34m%s\e[0m\n' "Skipping mise tool install (SKIP_MISE_TOOL_INSTALL=1)..." 1>&2
fi
