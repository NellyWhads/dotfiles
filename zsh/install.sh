#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------ZSH Installation--------" 1>&2

export ANTIGEN_DIR=$REPOS_DIR/antigen
export ZSH_DIR=$(pwd)

printf '\e[34m%s\e[0m\n' "Installing Dependency: Antigen..." 1>&2
mkdir -p $ANTIGEN_DIR
curl -L git.io/antigen > $ANTIGEN_DIR/antigen.zsh


printf '\e[34m%s\e[0m\n' "Installing ZSH..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install zsh -y
elif [ "$MACHINE" = "MacOS" ]; then
    brew install zsh
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S zsh --noconfirm
fi

printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
ln -sfn $ZSH_DIR/.zshrc $HOME/.zshrc
if [ "$MACHINE" = "MacOS" ]; then
    echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
fi

printf '\e[34m%s\e[0m\n' "Updating shell..." 1>&2

if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$USER"
fi

ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7 || echo "")"

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    echo "Setting default shell for $TARGET_USER to $ZSH_PATH" 1>&2
    if ! chsh -s "$ZSH_PATH" "$TARGET_USER" 2>/dev/null; then
        printf '\e[31m%s\e[0m\n' "Warning: Could not change shell automatically for $TARGET_USER. Please run 'chsh -s $ZSH_PATH $TARGET_USER' manually." 1>&2
    fi
fi
