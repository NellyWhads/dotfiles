#!/bin/bash

export ANTIGEN_DIR=$SOFTWARE_DIR/antigen
export ZSH_DIR=$(pwd)

printf '\n%s\n\n' "--------ZSH Installation--------" 1>&2

printf '%s\n' "Installing Dependancy: Antigen..." 1>&2
mkdir -p $ANTIGEN_DIR
curl -L git.io/antigen > $ANTIGEN_DIR/antigen.zsh

printf '%s\n' "Installing ZSH..." 1>&2
sudo apt-get install zsh

printf '%s\n' "Creating links..." 1>&2
#echo "source $ZSH_DIR/.zshrc" > $HOME/.zshrc
ln -s $ZSH_DIR/.zshrc $HOME/.zshrc
chsh -s $(which zsh)
