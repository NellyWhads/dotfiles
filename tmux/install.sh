#!/bin/bash

printf '\n\e[34;1m%s\e[0m\n\n' "--------Tmux Installation--------" 1>&2

export TMUX_DIR=$(pwd)

printf '\e[34m%s\e[0m\n' "Installing Tmux..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install tmux -y
elif [ "$MACHINE" = "MacOS" ]; then
    brew install tmux
fi

printf '\e[34m%s\e[0m\n' "Creating links..." 1>&2
ln -sfn $TMUX_DIR/.tmux.conf $HOME/.tmux.conf
