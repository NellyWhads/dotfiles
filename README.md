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

`zsh/install.sh` also installs **glow** (Markdown in the terminal) and symlinks
`zsh/glow.yml` into `~/.config/glow/`. Optional **command hints** (once-a-day
`cat`→`bat` nudge, per-invocation `cat`+`.md`→`glow`) load from
`zsh/command-hints.zsh`; set `DOTFILES_COMMAND_HINTS=0` to disable, or edit
`zsh/command-hints.conf`.

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

### Migrating from legacy shell stack (Ubuntu 22.04 / 24.04)

If another machine still has **Antigen**, **nvm**, **direnv**, **thefuck**, **pyenv** shims in `~/.zshrc.local`, etc., run **`scripts/nuclear-clean-legacy-shell.sh`** once **before** switching to this branch’s `zsh/install.sh`. It defaults to **dry-run**; use **`--execute`** to apply. It purges common apt packages (`direnv`, `thefuck`, `pyenv` when installed), removes **`~/.nvm`**, Antigen trees under **`~/Repos/antigen`** (and a few fallbacks), **`~/.antigen`**, strips matching lines/blocks from shell RC files (skips **`~/.zshrc`** if it is already a symlink into a **`dotfiles`** checkout), removes **`~/.zcompdump*`**, and can uninstall **`thefuck`** via **`uv`** / **`pipx`**. Optional nuclear flags: **`--remove-pyenv-root`**, **`--remove-fnm-root`**, **`--remove-volta-root`**, **`--remove-conda-root`**, **`--reset-atuin`**, **`--no-apt`**. Rewritten RC files are copied under **`~/.dotfiles-nuclear-cleanup-backup-<timestamp>/`** first.

### Machine-local config

Anything machine-specific (work secrets, SSO profiles, host-specific aliases)
goes in `~/.zshrc.local` — it's sourced last by `~/.zshrc` and is never
tracked.

### Cursor and Obsidian (durable notes)

This repo includes an **AI memory kit**: `AGENTS.md` at the repo root, project rules under `.cursor/rules/`, pasteable prompts in `cursor/prompts/`, Obsidian templates in `obsidian/templates/`, and a triage workflow in `obsidian/workflows/`. Clone your vault as a sibling of this repo (e.g. `~/workspaces/public/obsidian-vault` next to `~/workspaces/public/dotfiles`) or set `OBSIDIAN_VAULT` to an absolute path. Copy `obsidian/templates/` into your vault’s templates folder if you use Obsidian’s templating. Optional: symlink `cursor/skills/obsidian-note-writer` into `~/.cursor/skills/` for the same behavior in other workspaces.

