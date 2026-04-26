#!/bin/bash
set -eu

printf '\n\e[34;1m%s\e[0m\n\n' "--------ZSH Installation--------" 1>&2

export ZSH_DIR=$(pwd)

# ---------- Helper: ensure cargo is available (needed by pay-respects) ----------
# Install Rust toolchain if missing, using the OS-appropriate method.
# - macOS: brew install rust (latest stable)
# - Linux: rustup non-interactive (latest stable; apt's cargo can be too old
#          for crates that require recent edition features, e.g. edition2024)
ensure_cargo() {
    if command -v cargo >/dev/null 2>&1; then
        return 0
    fi
    case "$MACHINE" in
        MacOS)
            brew install rust
            ;;
        Ubuntu|Arch)
            printf '\e[34m%s\e[0m\n' "  Installing rustup non-interactively (latest stable)..." 1>&2
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
                | sh -s -- -y --default-toolchain stable --profile minimal
            # Make ~/.cargo/bin available in this script's process for the
            # subsequent cargo install calls.
            if [ -f "$HOME/.cargo/env" ]; then
                # shellcheck disable=SC1091
                . "$HOME/.cargo/env"
            else
                export PATH="$HOME/.cargo/bin:$PATH"
            fi
            ;;
    esac
}

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

# ---------- Install starship (the new prompt) ----------
printf '\e[34m%s\e[0m\n' "Installing starship..." 1>&2
if [ "$MACHINE" = "Ubuntu" ]; then
    # apt has starship on 24.04+; otherwise official installer.
    if apt-cache show starship >/dev/null 2>&1; then
        sudo apt-get install -y starship
    else
        # Install to ~/.local/bin (already in PATH per .zshrc) so we don't
        # need sudo to write to /usr/local/bin.
        mkdir -p "$HOME/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
    fi
elif [ "$MACHINE" = "MacOS" ]; then
    brew install starship
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S --noconfirm starship
fi

# ---------- Install pay-respects (typo corrector — Rust thefuck) ----------
# Not in brew, not in mise's default registry. cargo is the universal
# install path. On Arch, prefer an AUR helper (prebuilt) if available.
#
# On macOS we explicitly prefer brew's cargo (/opt/homebrew/bin/cargo).
# rustup's ~/.cargo/bin/cargo can lag the toolchain version brew tracks
# and miss new Rust edition features (pay-respects 0.8.7 needs
# edition2024 → Rust 1.85+).
printf '\e[34m%s\e[0m\n' "Installing pay-respects..." 1>&2

if [ "$MACHINE" = "Arch" ] && command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm pay-respects || \
        printf '\e[33m%s\e[0m\n' "  pay-respects install failed (continuing)" 1>&2
elif [ "$MACHINE" = "Arch" ] && command -v paru >/dev/null 2>&1; then
    paru -S --noconfirm pay-respects || \
        printf '\e[33m%s\e[0m\n' "  pay-respects install failed (continuing)" 1>&2
else
    ensure_cargo
    PR_CARGO="$(command -v cargo || true)"
    if [ "$MACHINE" = "MacOS" ] && [ -x "/opt/homebrew/bin/cargo" ]; then
        PR_CARGO="/opt/homebrew/bin/cargo"
    fi
    if [ -n "$PR_CARGO" ]; then
        # cargo install is idempotent — exits 0 with a note if already installed.
        # Don't let a build failure abort the rest of the script.
        "$PR_CARGO" install pay-respects || \
            printf '\e[33m%s\e[0m\n' "  pay-respects install failed (continuing). Try: cargo install pay-respects" 1>&2
    else
        printf '\e[33m%s\e[0m\n' "  Skipping pay-respects: cargo not found and rustup install failed." 1>&2
    fi
fi

# ---------- Install tealdeer (Rust `tldr`) ----------
# Recent releases don't publish binaries to GitHub Releases, so mise's
# aqua backend can't fetch it. brew on macOS, apt on newer Ubuntu,
# pacman on Arch, cargo as last resort.
printf '\e[34m%s\e[0m\n' "Installing tealdeer..." 1>&2
if [ "$MACHINE" = "MacOS" ]; then
    brew install tealdeer
elif [ "$MACHINE" = "Ubuntu" ]; then
    if apt-cache show tealdeer >/dev/null 2>&1; then
        sudo apt-get install -y tealdeer
    else
        ensure_cargo
        if command -v cargo >/dev/null 2>&1; then
            cargo install tealdeer || \
                printf '\e[33m%s\e[0m\n' "  tealdeer install failed (continuing)" 1>&2
        else
            printf '\e[33m%s\e[0m\n' "  Skipping tealdeer: no apt pkg and cargo not available." 1>&2
        fi
    fi
elif [ "$MACHINE" = "Arch" ]; then
    pacman -S --noconfirm tealdeer
fi

# ---------- Clone fzf-git.sh (Ctrl-G key bindings for fuzzy git) ----------
# Single shell script, not a binary — clone to a stable path and source it
# from .zshrc.
printf '\e[34m%s\e[0m\n' "Installing fzf-git.sh..." 1>&2
FZF_GIT_DIR="${HOME}/.local/share/fzf-git.sh"
if [ -d "${FZF_GIT_DIR}/.git" ]; then
    git -C "${FZF_GIT_DIR}" pull --ff-only --quiet
else
    mkdir -p "$(dirname "${FZF_GIT_DIR}")"
    git clone --quiet --depth=1 https://github.com/junegunn/fzf-git.sh.git "${FZF_GIT_DIR}"
fi

# ---------- Wire delta into git's pager ----------
# Idempotent — these git config lines are global but only set the delta
# integration; they don't touch user.name / user.email.
if command -v delta >/dev/null 2>&1 || mise which delta >/dev/null 2>&1; then
    printf '\e[34m%s\e[0m\n' "Wiring delta into ~/.gitconfig..." 1>&2
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global merge.conflictstyle zdiff3
fi

# ---------- Link configs ----------
printf '\e[34m%s\e[0m\n' "Linking configs..." 1>&2
ln -sfn "$ZSH_DIR/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config"
ln -sfn "$ZSH_DIR/starship.toml" "$HOME/.config/starship.toml"
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
