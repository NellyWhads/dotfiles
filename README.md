# dotfiles
My dotfiles for a clean OS rampup.

## Supported OSes (detected automatically)

- Ubuntu (tested on >= 22.04)
- macOS (tested on >= 10.11)
- Arch Linux

## Installation

1. Clone this repo (e.g. into `~/workspaces/public/dotfiles` or wherever you keep repos).
2. From the repo root, run the OS-appropriate command below.
3. **macOS:**
   ```bash
   ./install.sh
   ```
   Run from **Terminal.app** or **iTerm** (not from Cursor or another IDE) so password prompts work. Do **not** use `sudo` — Homebrew refuses to run as root. The script prompts for your password inline where it actually needs root (`/etc/shells`, `chsh`).
4. **Ubuntu:** Preserve your home directory so tools install under your user:
   ```bash
   sudo -E ./install.sh
   ```
5. **Arch:**
   ```bash
   sudo ./install.sh
   ```

### Headless mode

`./install.sh --headless` (or `sudo -E ./install.sh --headless` on Ubuntu) — skips GUI apps (e.g. Chrome, VSCode).

### Shell completions (mise tools)

Completions for mise-installed tools (e.g. uv) are provided by [mise-completions-sync](https://github.com/alltuner/mise-completions-sync). They sync automatically after `mise install` (postinstall hook). To sync manually: `mise-completions-sync`.

### Resetting mise (clean reinstall)

To wipe mise installs, state, and completion cache and reinstall from your dotfiles (e.g. to verify completion sync):

```bash
./scripts/reset-mise.sh
cd mise && ./install.sh
exec zsh
```

### Skipping mise tool installation

To skip installing mise tools and linking config (e.g. for a minimal install or on CI), set the `SKIP_MISE_TOOL_INSTALL` environment variable:
```bash
SKIP_MISE_TOOL_INSTALL=1 ./install.sh         # macOS
SKIP_MISE_TOOL_INSTALL=1 sudo -E ./install.sh # Ubuntu
```

### zsh setup

The shell is `zsh` with [antidote](https://getantidote.github.io) as the plugin
manager (replacing antigen). Plugin list lives in `zsh/.zsh_plugins.txt` —
edit, save, open a new shell. The cached bundle (`~/.zsh_plugins.zsh`) is
regenerated automatically when the source list changes.

Heavy plugins (`zsh-autosuggestions`, `fast-syntax-highlighting`,
`alias-tips`, `almostontop`) are deferred via antidote's `kind:defer`
annotation, so the prompt draws first and they kick in milliseconds later.

To benchmark startup:

```bash
./scripts/zsh-bench.sh                  # current ~/.zshrc, 10 samples
./scripts/zsh-bench.sh --compare        # current vs proposed, side-by-side
./scripts/zsh-bench.sh --compare -n 20  # more samples for stability
```

`--proposed` and `--compare` run the proposed setup in an isolated
`~/.cache/zsh-bench-proposed/` sandbox — **your real `~/.zshrc`,
`~/.antidote`, and `~/.zsh_plugins.zsh` are not touched**. Antidote
clones into the sandbox on first run if it isn't already on the system.
Cleanup: `rm -rf ~/.cache/zsh-bench-proposed`.

### Machine-local config

Anything machine-specific (work secrets, SSO profiles, host-specific aliases)
goes in `~/.zshrc.local` — it's sourced last by `~/.zshrc` and is never
tracked.
