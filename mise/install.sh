#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------mise Installation--------" 1>&2

MISE_DIR="$(pwd)"

printf '\e[34m%s\e[0m\n' "Installing mise..." 1>&2
bash -c 'curl https://mise.run | sh'

if [ -z "${SKIP_MISE_TOOL_INSTALL:-}" ]; then
    printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
    ln -sfn "${MISE_DIR}/mise.toml" "${HOME}/.config/mise.toml"

    printf '\e[34m%s\e[0m\n' "Installing mise tools..." 1>&2
    bash -c "${HOME}/.local/bin/mise install"
else
    printf '\e[34m%s\e[0m\n' "Skipping mise tool install (SKIP_MISE_TOOL_INSTALL=1)..." 1>&2
fi
