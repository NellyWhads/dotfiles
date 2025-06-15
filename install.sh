#!/bin/bash

set -u
set -e

DOTFILE_REPO_ROOT='https://github.com/NellyWhadsDev/dotfiles'

# Sudo check
if [ "$USER" != "root" ]; then
    printf '\e[31;1m%s\e[0m\n' "Warning: This script is expected to run as root" 1>&2
    SUDO_USER=$USER
fi

# Env check
printf '\e[34m%s\e[0m\n' "Installing for user $SUDO_USER with home directory $HOME" 1>&2
read -r -p "Is this correct? " response
case "$response" in
    [yY])       ;;
    *)    exit 1;;
esac

# Get system type
unameOut="$(uname -s)"
case "$unameOut" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=MacOS;;
    *)          machine="UNKNOWN:$unameOut";;
esac

# If this is a Linux system, check for Ubuntu vs unknown
if [ "$machine" = "Linux" ]; then
    unameOut="$(uname -v)"
    case "$unameOut" in
        *Ubuntu*)    machine=Ubuntu;;
        *)           machine="UNKNOWN:$unameOut";;
    esac
fi

# If this is an unknown distro, ask user to override using Ubuntu or MacOS config
if [ "$machine" = "UNKNOWN:$unameOut" ]; then
    read -r -p "Unknown installation ($machine); Assume [U]buntu [M]acOS or [A]rch? " response
    case "$response" in
        [uU])  machine=Ubuntu;;
        [mM])  machine=MacOS;;
        [aA])  machine=Arch;;
        *)                  ;;
    esac
fi

# If nothing matched, ask user to optionally override
export MACHINE=$machine

if [ "$MACHINE" = "Ubuntu" ] || [ "$MACHINE" = "MacOS" ] || [ "$MACHINE" = "Arch" ]; then
    printf '\e[34m%s\e[0m\n' "Installing on $MACHINE" 1>&2
else
    printf '\e[31;1m%s\e[0m\n' "Unsupported environment: '$MACHINE'" 1>&2
    exit 1
fi

# Get UI type from CLI args
export UI_TYPE=default
if [ "${1-}" = "--headless" ]; then
     printf '\e[34;1m%s\e[0m\n' "Only installing heeadless components..." 1>&2
     export UI_TYPE="headless"
fi

export REPOS_DIR=$HOME/Workspaces/Public
printf '\e[34m%s\e[0m\n' "Setting up 'Workspaces/Public' dir @ '$REPOS_DIR'..." 1>&2
mkdir -p $REPOS_DIR

printf '\e[34m%s\e[0m\n' "Setting script permissions..." 1>&2
chmod +x ./*/install.sh

printf '\e[34m%s\e[0m\n' "Installing universal dependancies..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    apt-get update
    apt-get install curl git -y
elif [ "$MACHINE" = "MacOS" ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
    brew install curl git
elif [ "$MACHINE" = "Arch" ]; then
    pacman -Sy --noconfirm
    pacman -S curl git --noconfirm
fi

printf '\e[34m%s\e[0m\n' "Installing Dependancy: UV ..." 1>&2
if ! uv --version &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ZSH setup
(cd zsh ; ./install.sh)

# Tmux setup
(cd tmux ; ./install.sh)

# VSCode setup
(cd vscode ; ./install.sh)

# User setup
if [ ! -f $HOME/.gitconfig ]; then
    printf '\e[34m%s\e[0m\n' "Setting global git user..." 1>&2
    git config --global user.name "Nelly Whads"
    git config --global user.email "nellywhads@gmail.com"
fi

printf '\n\e[34;1m%s\e[0m\n\n' "Done setting up OS tools" 1>&2
exit 0
