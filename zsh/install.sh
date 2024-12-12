#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------ZSH Installation--------" 1>&2

export ANTIGEN_DIR=$REPOS_DIR/antigen
export ZSH_DIR=$(pwd)

printf '\e[34m%s\e[0m\n' "Installing Dependancy: Antigen..." 1>&2
mkdir -p $ANTIGEN_DIR
curl -L git.io/antigen > $ANTIGEN_DIR/antigen.zsh

printf '\e[34m%s\e[0m\n' "Installing Dependancy: thefuck..." 1>&2
if [ "$MACHINE" = "Ubuntu" ] || ["$MACHINE" = "Arch" ]; then
    uv tool install thefuck
elif [ "$MACHINE" = "MacOS" ]; then
    brew install thefuck
fi

printf '\e[34m%s\e[0m\n' "Installing direnv..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    apt-get install direnv -y
elif [ "$MACHINE" = "MacOS" ]; then
    brew install direnv
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S direnv --noconfirm
fi

printf '\e[34m%s\e[0m\n' "Installing ZSH..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    apt-get install zsh -y
elif [ "$MACHINE" = "MacOS" ]; then
    brew install zsh
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S zsh --noconfirm
fi

printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
ln -sfn $ZSH_DIR/.zshrc $HOME/.zshrc
if [ "$MACHINE" = "MacOS" ]; then
    echo "$(which zsh)" | tee -a /etc/shells > /dev/null
fi

printf '\e[34m%s\e[0m\n' "Updating shell..." 1>&2
chsh -s $(which zsh) $SUDO_USER
