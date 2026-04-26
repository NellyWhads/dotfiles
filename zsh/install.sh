#!/bin/bash
set -eu

printf '\n\e[34;1m%s\e[0m\n\n' "--------ZSH Installation--------" 1>&2

export ZSH_DIR=$(pwd)

# ---------- Install zsh ----------
printf '\e[34m%s\e[0m\n' "Installing zsh..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install -y zsh
elif [ "$MACHINE" = "MacOS" ]; then
    brew install zsh
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S --noconfirm zsh
fi

# ---------- Install antidote (replaces antigen) ----------
printf '\e[34m%s\e[0m\n' "Installing antidote..." 1>&2
if [ "$MACHINE" = "MacOS" ]; then
    brew install antidote
elif [ "$MACHINE" = "Ubuntu" ]; then
    # apt has zsh-antidote on Ubuntu 24.04+. Fall back to git clone.
    if apt-cache show zsh-antidote >/dev/null 2>&1; then
        sudo apt-get install -y zsh-antidote
    else
        ANTIDOTE_HOME="${HOME}/.antidote"
        if [ -d "${ANTIDOTE_HOME}/.git" ]; then
            git -C "${ANTIDOTE_HOME}" pull --ff-only
        else
            git clone --depth=1 https://github.com/mattmc3/antidote.git "${ANTIDOTE_HOME}"
        fi
    fi
elif [ "$MACHINE" = "Arch" ]; then
    if command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm zsh-antidote
    elif command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm zsh-antidote
    else
        ANTIDOTE_HOME="${HOME}/.antidote"
        if [ -d "${ANTIDOTE_HOME}/.git" ]; then
            git -C "${ANTIDOTE_HOME}" pull --ff-only
        else
            git clone --depth=1 https://github.com/mattmc3/antidote.git "${ANTIDOTE_HOME}"
        fi
    fi
fi

# ---------- Install fzf (replaces history-search-multi-word) ----------
printf '\e[34m%s\e[0m\n' "Installing fzf..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install -y fzf
elif [ "$MACHINE" = "MacOS" ]; then
    brew install fzf
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S --noconfirm fzf
fi

# ---------- Install lsd ----------
printf '\e[34m%s\e[0m\n' "Installing lsd..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    sudo apt-get install -y lsd
elif [ "$MACHINE" = "MacOS" ]; then
    brew install lsd
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S --noconfirm lsd
fi

# ---------- Link configs ----------
printf '\e[34m%s\e[0m\n' "Linking configs..." 1>&2
ln -sfn "$ZSH_DIR/.zshrc" "$HOME/.zshrc"
# .zsh_plugins.txt and aliases.zsh are sourced via $ZSH_DOTFILES discovery in
# .zshrc, so they don't need separate symlinks.

# ---------- Pre-bundle so first interactive shell is fast ----------
printf '\e[34m%s\e[0m\n' "Pre-building plugin bundle and zcompiling rc..." 1>&2
# Run a one-shot interactive zsh; antidote regenerates ~/.zsh_plugins.zsh,
# compinit caches completions, then we exit immediately.
zsh -ic 'true' || true
zsh -c 'zcompile "${HOME}/.zshrc" "${HOME}/.zsh_plugins.zsh" 2>/dev/null' || true

# ---------- Add zsh to /etc/shells (macOS only) ----------
if [ "$MACHINE" = "MacOS" ]; then
    ZSH_PATH="$(command -v zsh)"
    if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
        printf '\n\e[34m%s\e[0m\n' "Adding $ZSH_PATH to /etc/shells..." 1>&2
        printf '\e[33;1m%s\e[0m\n' ">>> sudo will prompt for your password — type it and press Enter <<<" 1>&2
        echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
fi

# ---------- Set zsh as default shell ----------
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$USER"
fi

ZSH_PATH="$(command -v zsh)"
# Cross-platform current-shell lookup: getent on Linux, dscl on macOS.
if command -v getent >/dev/null 2>&1; then
    CURRENT_SHELL="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f7 || echo "")"
elif command -v dscl >/dev/null 2>&1; then
    CURRENT_SHELL="$(dscl . -read /Users/"$TARGET_USER" UserShell 2>/dev/null | awk '{print $2}')"
else
    CURRENT_SHELL=""
fi

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    printf '\n\e[34m%s\e[0m\n' "Setting default login shell for $TARGET_USER to $ZSH_PATH..." 1>&2
    if [ "$MACHINE" = "MacOS" ]; then
        # macOS chsh prompts for the password via PAM with NO label of its own.
        # If you don't warn the user, it just looks like the script hung.
        printf '\e[33;1m%s\e[0m\n' ">>> chsh will prompt SILENTLY for your password — type it and press Enter <<<" 1>&2
    fi
    # Note: do NOT redirect chsh's stderr — that's where the password prompt goes.
    if ! chsh -s "$ZSH_PATH" "$TARGET_USER"; then
        printf '\e[31m%s\e[0m\n' "Warning: Could not change shell automatically for $TARGET_USER." 1>&2
        printf '\e[31m%s\e[0m\n' "         Run manually: chsh -s $ZSH_PATH $TARGET_USER" 1>&2
    fi
fi
