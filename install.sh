#!/bin/bash

set -u
set -e

DOTFILE_REPO_ROOT='https://github.com/NellyWhadsDev/dotfiles'

# SUDO_USER fallback (set by `sudo` itself; falls back to current user)
if [ -z "${SUDO_USER:-}" ]; then
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

# OS-specific sudo policy
if [ "$MACHINE" = "MacOS" ] && [ "$(id -u)" -eq 0 ]; then
    printf '\e[31;1m%s\e[0m\n' "Error: Don't run this script under sudo on macOS." 1>&2
    printf '\e[33m%s\e[0m\n' "  Homebrew refuses to run as root. Re-run as your user:" 1>&2
    printf '\n  %s\n\n' "    ./install.sh${1:+ $*}" 1>&2
    printf '\e[33m%s\e[0m\n' "  The script will prompt for your password where it actually" 1>&2
    printf '\e[33m%s\e[0m\n' "  needs root (writing /etc/shells, running chsh)." 1>&2
    exit 1
fi
if [ "$USER" != "root" ] && { [ "$MACHINE" = "Ubuntu" ] || [ "$MACHINE" = "Arch" ]; }; then
    printf '\e[33m%s\e[0m\n' "Note: On $MACHINE the script will use inline sudo for apt/pacman, /etc/shells, chsh." 1>&2
    printf '\e[33m%s\e[0m\n' "      You'll be prompted for your password as needed." 1>&2
fi

# Get UI type from CLI args
export UI_TYPE=default
if [ "${1-}" = "--headless" ]; then
     printf '\e[34;1m%s\e[0m\n' "Only installing heeadless components..." 1>&2
     export UI_TYPE="headless"
fi

export REPOS_DIR=$HOME/workspaces/public
printf '\e[34m%s\e[0m\n' "Setting up public workspaces dir @ '$REPOS_DIR'..." 1>&2
mkdir -p $REPOS_DIR

printf '\e[34m%s\e[0m\n' "Setting script permissions..." 1>&2
chmod +x ./*/install.sh

printf '\e[34m%s\e[0m\n' "Installing universal dependencies..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get update
    sudo apt-get install curl git -y
elif [ "$MACHINE" = "MacOS" ]; then
    if ! command -v brew &>/dev/null; then
        if [ ! -t 0 ]; then
            printf '\e[31;1m%s\e[0m\n' "Homebrew must be installed from an interactive terminal (stdin is not a TTY)." 1>&2
            printf '\e[33m%s\e[0m\n' "Run this script from Terminal.app or iTerm, not from Cursor/IDE:" 1>&2
            printf '  %s\n' "cd \"$(pwd)\" && ./install.sh $*" 1>&2
            exit 1
        fi
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install curl git
elif [ "$MACHINE" = "Arch" ]; then
    pacman -Sy --noconfirm
    pacman -S curl git --noconfirm
fi

# mise setup
(cd mise ; ./install.sh)

# Tmux setup
(cd tmux ; ./install.sh)

# ZSH setup
(cd zsh ; ./install.sh)

# Cursor setup
(cd cursor ; ./install.sh)

# User setup
if [ ! -f $HOME/.gitconfig ]; then
    printf '\e[34m%s\e[0m\n' "Setting global git user..." 1>&2
    git config --global user.name "Nelly Whads"
    git config --global user.email "nellywhads@gmail.com"
fi

printf '\n\e[34;1m%s\e[0m\n\n' "Done setting up OS tools" 1>&2
exit 0
