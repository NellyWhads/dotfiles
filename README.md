# dotfiles
My dotfiles for a clean OS rampup.

## Supported OSes (detected automatically)

- Ubuntu (tested on >= 22.04)
- macOS (tested on >= 10.11)
- Arch Linux

## Installation

1. Clone this repo (e.g. into `~/workspaces/public/dotfiles` or wherever you keep repos).
2. From the repo root, run:
   ```bash
   sudo ./install.sh
   ```
3. **macOS:** If Homebrew isn’t installed yet, run the script from **Terminal.app** or **iTerm** (not from Cursor or another IDE), so it can prompt for your password.
4. **Ubuntu:** Preserve your home directory so tools install under your user:
   ```bash
   sudo -E ./install.sh
   ```

### Headless mode

`sudo ./install.sh --headless` — skips GUI apps (e.g. Chrome, VSCode).

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
SKIP_MISE_TOOL_INSTALL=1 sudo ./install.sh
```
