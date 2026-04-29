# Benchmark results

**Machine:** TORC-CF7FXGKG5J — macOS Sonoma 23.5.0, arm64 (M-series), zsh 5.9
**Date:** 2026-04-25
**Method:** `./scripts/zsh-bench.sh --compare -n 20` (with `TERM=xterm-256color`
to match real terminal launch). Proposed setup ran in isolated sandbox at
`~/.cache/zsh-bench-proposed/` — `~/.zshrc`, `~/.antidote`, `~/.zsh_plugins.zsh`
were not touched.

## Headline

| | median | min | max | range |
|---|---|---|---|---|
| Current (antigen + OMZ + 14 plugins) | 1057 ms | 822 ms | 1413 ms | 591 ms |
| Proposed (final) | 170 ms | 155 ms | 195 ms | 40 ms |
| **Speedup** | **6.2×** | | | **15× tighter variance** |

Proposed setup saves **~887 ms per new shell**. The variance shrinks from
591 ms (current frequently spikes >1.4 s) to 40 ms — every shell-open feels
the same instead of randomly slow.

> Both rows include ~80–100 ms of python-subprocess timing overhead per sample.
> Direct `/usr/bin/time -p zsh -ic exit` measurements were 890 ms → 110 ms,
> an **~8×** real-world speedup (the user-visible "click new tab" cost).

## What's in the proposed setup

Everything community-managed except the user's personal git-worktree
aliases. Plugin list (in `zsh/.zsh_plugins.txt`):

```
nellywhads/alien-minimal                       # theme
ohmyzsh/ohmyzsh path:plugins/git               # aliases + completions
ohmyzsh/ohmyzsh path:plugins/common-aliases    # cp/mv/rm -i, etc.
ohmyzsh/ohmyzsh path:plugins/command-not-found
ohmyzsh/ohmyzsh path:plugins/cp                # cpv = rsync wrapper
ohmyzsh/ohmyzsh path:plugins/safe-paste
ohmyzsh/ohmyzsh path:plugins/tmux              # ta/tad/ts/tl/tksv/tkss/to
ohmyzsh/ohmyzsh path:plugins/debian            # apt aliases (Linux)
ohmyzsh/ohmyzsh path:plugins/uv                # uvi/uvr/uva/uvs/etc.
z-shell/zsh-lsd                                # ls aliases
willghatch/zsh-saneopt
zsh-users/zsh-completions                      # extra completions
Aloxaf/fzf-tab                                 # fzf-powered tab completion
zsh-users/zsh-autosuggestions               kind:defer
zdharma-continuum/fast-syntax-highlighting  kind:defer
zdharma-continuum/history-search-multi-word kind:defer  # your current Ctrl-R UX
djui/alias-tips                             kind:defer
Valiev/almostontop                          kind:defer
```

`zsh/aliases.zsh` shrunk from a 50-line catch-all to just your personal
git-worktree workflow (`gw`, `gwa`, `gst`, `grbom`, etc.) — no community
equivalent, so it stays.

## Completion verification

Tested via `whence -v _<cmd>` against the proposed setup:

| command | source | status |
|---|---|---|
| `uv` | mise-completions-sync | ✅ |
| `git` | system zsh + OMZ git | ✅ |
| `mise` | mise-completions-sync | ✅ |
| `tmux` | system zsh + OMZ tmux | ✅ |
| `pip` / `npm` | system zsh | ✅ |
| `docker` / `kubectl` | n/a | not installed on this machine |
| `fzf` | n/a | binary not installed yet (install.sh handles this) |

## Where the time goes (zprof of proposed setup)

The single largest cost is `_zsh_terminal_set_256color`, sourced by the
**alien-minimal theme** via its bundled `libs/zsh-256color/` library. Under
`TERM=dumb` (e.g. inside CI / non-tty wrappers) it falls into a slow path
that grep-searches `/etc/terminfo`, `$TERMINFO`, etc., costing ~187 ms.
Under `TERM=xterm-256color` (a real terminal), it short-circuits in <1 ms.
The proposed bench script now sets `TERM=xterm-256color` by default to
match real-world terminal launches.

Remaining cost in the proposed setup, roughly:

| function | time | notes |
|---|---|---|
| `compinit` (×2) | ~17 ms | Two-phase: defines `compdef`, then picks up plugin fpath |
| `_mise_hook` | ~10 ms | mise activation; can't avoid this |
| `compaudit` | ~8 ms | Permissions check during compinit |
| `async_init` | ~3 ms | alien-minimal async prompt setup |
| antidote bundle source | ~1.5 ms | static, fast |

## Findings worth knowing

1. **Two-phase `compinit` is what fixes "autocomplete sometimes flakes
   for uv/git"**. Phase 1 defines `compdef` so plugins that register
   completions during sourcing don't fail with `command not found: compdef`.
   Phase 2 (after the bundle is sourced) picks up `_foo` completion files
   that plugins added to `fpath`. Single-pass setups silently miss one or
   the other.

2. **`mise-completions-sync` provides authoritative `_uv` (and `_mise`) at
   `~/.local/share/mise-completions/zsh/`**. The proposed `.zshrc` puts
   that directory at the *front* of `fpath` and `$ZSH_CACHE_DIR/completions`
   at the *back*, so even when the OMZ `uv` plugin's runtime completion
   generation fails (see #4 below), mise's version wins.

3. **alien-minimal's `zsh-256color` library is the dominant cost in any
   non-tty environment** (e.g. when scripts launch zsh). Inside Terminal.app,
   iTerm, or Ghostty, it short-circuits and is essentially free. The library
   itself is from `chrissicool/zsh-256color` (2014) and is largely obsolete
   for modern terminals — all of yours already advertise 256-color support
   in `TERM`. If you ever want to shave another ~1 ms in real terminals or
   ~190 ms in non-tty envs, deleting that `source` line in
   `alien-minimal.plugin.zsh` is safe.

4. **Pre-existing mise config issue (not introduced by this branch).** Your
   `~/.config/mise.toml` symlink isn't being recognized as the global mise
   config — `mise current uv` returns "Plugin uv does not have a version
   set" even though your tracked `mise.toml` declares `uv = "0.10.10"`.
   That makes the OMZ `uv` plugin emit "No version is set for shim: uv"
   on every shell startup (it tries to call `uv generate-shell-completion`
   to regenerate `_uv`, but the shim fails to resolve). The completion
   still works thanks to `mise-completions-sync`, so the UX is fine — but
   the noise is annoying. Likely fix: change `mise/install.sh` to symlink
   to `~/.config/mise/config.toml` (with subdir), which is the documented
   global location in modern mise. Out of scope for this branch.

## Reproducing

```bash
cd /Users/neil.wadhvana/workspaces/public/dotfiles/.worktrees/fast-zsh
./scripts/zsh-bench.sh --compare -n 20
```

Cleanup of the sandbox:

```bash
rm -rf ~/.cache/zsh-bench-proposed
```
