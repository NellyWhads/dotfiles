#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------Tmux Installation--------" 1>&2

export TMUX_DIR=$(pwd)

printf '\e[34m%s\e[0m\n' "Installing Dependency: TPM..." 1>&2
if [ -d "$HOME/.tmux/plugins/tpm/.git" ]; then
    printf '\e[34m%s\e[0m\n' "TPM already present. Updating..." 1>&2
    git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
else
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

printf '\e[34m%s\e[0m\n' "Installing Tmux..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install tmux -y
elif [ "$MACHINE" = "MacOS" ]; then
    brew install tmux
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S tmux --noconfirm
fi

printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
ln -sfn $TMUX_DIR/.tmux.conf $HOME/.tmux.conf

# ---------- Auto-install tmux plugins via TPM ----------
# Without this, every new machine needs a manual `prefix + I` inside tmux.
# We bootstrap a temporary detached tmux server, source the config, run
# TPM's install script, then tear the server down. Skipped if the user is
# already inside tmux (would mess with their live session).
if command -v tmux >/dev/null 2>&1 && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    if [ -z "${TMUX:-}" ]; then
        printf '\e[34m%s\e[0m\n' "Auto-installing tmux plugins via TPM..." 1>&2
        tmux start-server
        tmux new-session -d -s _tpm_bootstrap -x 80 -y 24 2>/dev/null || true
        tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>&1 | tail -10
        tmux kill-session -t _tpm_bootstrap 2>/dev/null || true
        tmux kill-server 2>/dev/null || true
    else
        printf '\e[33m%s\e[0m\n' "  Inside tmux — run 'prefix + I' to install/update plugins." 1>&2
    fi
fi
