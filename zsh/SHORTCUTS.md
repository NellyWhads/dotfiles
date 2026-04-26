# Shortcuts cheat sheet

Everything new (and many old favorites) wired up by this dotfiles setup.
Open this file with `bat …/SHORTCUTS.md` for syntax highlighting, or
`glow …/SHORTCUTS.md` for a rendered Markdown view in the terminal.

---

## History search

The default Ctrl-R is **history-search-multi-word (HSM)** — your existing
multi-word fuzzy UI. Atuin records everything in parallel and is reachable
via additional keys.

| Key | Action |
|---|---|
| `Ctrl-R` | HSM — fuzzy multi-word search, full-screen list. Replaces buffer on accept. |
| `Ctrl-X Ctrl-R` | Atuin TUI — full-screen, with metadata. Replaces buffer on accept. |
| `Ctrl-Shift-R` | Same as `Ctrl-X Ctrl-R` (works in ghostty/kitty/wezterm/CSI-u terminals). |
| `Ctrl-X Ctrl-Y` | **Chain mode (atuin)** — picks a command from atuin and *inserts at cursor*. Lets you compose multi-command chains from history hits. |
| `Ctrl-X Y` | **Chain mode (zsh history)** — same as above but uses `~/.zsh_history` via fzf instead of atuin's database. |

### HSM keys *inside* the Ctrl-R UI

| Key | Action |
|---|---|
| `Ctrl-K` | Toggle context (more/less surrounding history) |
| `Ctrl-J` | "Bump" — drop a result and show the next |
| `Esc` / `Ctrl-G` | Cancel |

### Atuin keys *inside* its TUI

| Key | Action |
|---|---|
| `Ctrl-R` | **Cycle filter mode**: directory ↔ global ↔ host ↔ session ↔ workspace |
| `Ctrl-S` | **Cycle search mode**: fuzzy ↔ prefix ↔ fulltext ↔ skim |
| `Ctrl-O` | Inspect overlay for the selected command (cwd, exit code, duration, etc.) |
| `Tab` | Edit the selected command (puts it on the input line for editing) |
| `Enter` | Run the selected command immediately |
| `↑` / `↓` (or `Ctrl-N` / `Ctrl-P`) | Navigate the result list |
| `Esc` / `Ctrl-C` / `Ctrl-G` / `Ctrl-D` | Cancel and exit |

### Atuin from the CLI (no TUI)

```bash
atuin search "docker compose"        # print matching commands
atuin search --cwd "$PWD"            # only commands run in this directory
atuin stats                          # top commands, longest sessions, etc.
```

---

## Editing the current command

| Key | Action |
|---|---|
| `Ctrl-X Ctrl-E` | **Edit current line in `$EDITOR`** — opens vim/etc., save+quit runs it. Best for chains, heredocs, anything multi-line. |
| `Alt-Backspace` / `Ctrl-Backspace` | Delete previous word (alnum-only boundaries — stops at `/`, `.`, `-`) |
| `Ctrl-W` | Kill previous word (whitespace boundaries) |
| `Alt-F` / `Alt-B` | Jump forward / backward by word |
| `Ctrl-A` / `Ctrl-E` | Beginning / end of line |
| `Ctrl-K` / `Ctrl-U` | Kill to end / start of line |
| `Alt-.` | Yank last argument of previous command (chain it: keeps cycling further back) |

> **macOS gotcha:** Option-key chords (`Alt-F`, `Alt-B`, `Alt-.`) only work if your terminal sends `Esc+letter` instead of inserting the special character. For ghostty: `macos-option-as-alt = true` in `~/.config/ghostty/config`.

---

## Tab completion (fzf-tab)

| Key | Action |
|---|---|
| `Tab` (after a command) | fzf-powered fuzzy completion menu with preview pane |
| `Tab` / `Shift-Tab` (inside menu) | Navigate down / up |
| `Enter` (inside menu) | Accept selected completion |
| `Esc` | Cancel |

Try: `git checkout <Tab>`, `kill <Tab>`, `cd <Tab>`, `ssh <Tab>`.

**Git aliases (`glog`, `gco`, …):** if Tab offered only files, your shell was completing the alias *name* instead of `git`. This repo sources `git-alias-completion.zsh` (`setopt complete_aliases` + `compdef _git …=git-*`) so OMZ-style `g*` aliases get branch/tag/commit completion like `git …`.

---

## Directory navigation (zoxide)

| Command | Action |
|---|---|
| `z foo` | Jump to most-frecent directory matching "foo" |
| `zi` | Interactive fzf picker over your visited dirs |
| `z -` | Previous directory |
| `cd -` | Same; stock zsh |
| `z foo bar` | Jump to dir matching both terms |

---

## Typo correction (pay-respects)

| Action | How |
|---|---|
| Just typed something dumb | Hit `f` Enter — replays the corrected version |

Examples that get fixed: `git statys → git status`, `cd /usr/loca/bin → cd /usr/local/bin`, `pyhon → python`.

---

## Quick-look info (tealdeer / `tldr`)

```bash
tldr ffmpeg       # 5-line cheat sheet of what people actually use
tldr tar          # not the man page wall
tldr --update     # refresh page cache (auto-runs every 30 days)
```

---

## Files / search shortcuts (fd, ripgrep, bat, glow)

| Alias | Expands to | Use |
|---|---|---|
| `ff foo` | `fd foo` | Find files matching pattern (substring/regex) |
| `ffd build` | `fd -t d build` | Directories only |
| `ffe py` | `fd -e py` | By extension (no dot, no glob) |
| `ffi readme` | `fd -i readme` | Case-insensitive |
| `ffh dotfile` | `fd -H dotfile` | Include hidden / dotfiles |
| `ffa pattern` | `fd -HI pattern` | Include hidden AND `.gitignored` |
| `rg "pat"` | (rg) | Fast grep alternative |
| `bat file.py` | (bat) | `cat` with syntax highlighting + line numbers |
| `glow file.md` | (glow) | Render Markdown in the terminal (pager, styles) |
| `tldr <cmd>` | (tealdeer) | Cheat sheet |

### Command hints (optional nudges)

If `DOTFILES_COMMAND_HINTS` is not `0`, the first `cat` of each day (without a `.md` argument) can print a one-line hint to prefer `bat` when it is installed; each `cat` of a `*.md` file can hint at `glow`. Rules live in `zsh/command-hints.conf`; state is under `${XDG_CACHE_HOME:-~/.cache}/dotfiles/command-hints.state`.

For predicates fd doesn't have (`-newer`, `-mtime`, `-prune`, complex `-exec`), `find` is still at `/usr/bin/find` — untouched.

---

## Git workflow

### Aliases (your personal flow)

| Alias | Expands to |
|---|---|
| `gw` | `git worktree` |
| `gwl` | `git worktree list` |
| `gwa` | `git worktree add` |
| `gwac` | `git worktree add --checkout` |
| `gwr` | `git worktree remove` |
| `gwp` | `git worktree prune` |
| `gwd` | `git rev-parse --show-toplevel` (print repo root) |
| `gst` | Worktree-aware status (prune, list trees, branches, status, stashes) |
| `glogb` | `git log --oneline --decorate --graph --branches` |
| `grbom` | `git fetch origin <main> && git rebase origin/<main>` |
| `grbiom` | Same as above, interactive rebase |

Plus everything from OMZ's `git` plugin (`gst`, `gp`, `gpsup`, `gco`, `gd`, etc.).

### fzf-git.sh — fuzzy pickers (inside any git repo)

Press the prefix `Ctrl-G` then a letter:

| Key | Action |
|---|---|
| `Ctrl-G B` | Branches — with live diff/log preview |
| `Ctrl-G T` | Tags |
| `Ctrl-G H` | Commit hashes — with diff preview |
| `Ctrl-G R` | Remotes |
| `Ctrl-G S` | Status (modified files) |
| `Ctrl-G W` | Worktrees |
| `Ctrl-G E` | Each (each commit, ranged) |

Works as command-line input — selected refs/hashes get pasted into your buffer at cursor.

### delta (git diff viewer)

`git diff`, `git show`, `git log -p` automatically render via delta — side-by-side, syntax-highlighted, with `n`/`N` to jump between hunks.

---

## Process management

| Command / Key | Action |
|---|---|
| `fkill` | fzf process picker — Tab to multi-select, Enter to SIGTERM |
| `fkill 9` | Same, but sends SIGKILL |
| `pkill <name>` | Kill by name (system) |

---

## Prompt (Starship)

The prompt itself isn't really keyboard-driven, but here's what it shows:

| Element | Meaning |
|---|---|
| `@hostname` (yellow) | Hostname (always shown). Container ID when inside Docker. |
| `⬢ [Docker]` (red) | **You are inside a container.** Auto-detected via `/.dockerenv`. |
| `dir/` (cyan) | Current dir, truncated at 4 segments / repo root |
| `on branch [≡↑1]` (purple) | Git branch + status (`!` modified, `+` staged, `?` untracked, `↑` ahead, `↓` behind, `≡` stashed) |
| ` 3.12.9` etc. | Active language version (uv venv, node, rust, go) |
| `took 12s` | Last command's duration (only if > 2s) |
| `❯` | Prompt char (green = success, red = previous command failed) |

---

## tmux (after `prefix` = `Ctrl-B`)

### Built-in / pain-control

| Key | Action |
|---|---|
| `prefix h/j/k/l` | Switch panes (vim-direction) |
| `prefix H/J/K/L` | Resize panes |
| `prefix \|` / `prefix -` | Split horizontal / vertical |
| `prefix x` | Kill pane |
| `prefix &` | Kill window |
| `prefix c` | Create window |
| `prefix 1-9` | Switch to window N (windows now start at 1) |
| `prefix r` | Reload `~/.tmux.conf` |
| `prefix d` | Detach session |
| `prefix m` / `prefix M` | Toggle mouse on / off |

### tmux-fzf — `prefix F`

Opens fzf picker over: sessions, windows, panes, commands, key bindings, clipboard buffers. Massive UX win for daily tmux usage.

### extrakto — `prefix Tab`

Fuzzy-grab any text on the *current pane* — URLs, file paths, hashes, IDs, anything visible — into the system clipboard. Brilliant for "I need that container ID three lines up".

### tmux-yank (clipboard)

Copy-mode (`prefix [`) → highlight → `y` to yank to system clipboard. Works on macOS, Linux, WSL.

### tmux-resurrect / tmux-continuum

| Key | Action |
|---|---|
| `prefix Ctrl-S` | Save session manually (rarely needed) |
| `prefix Ctrl-R` | Restore last saved session |

(Continuum is on, so sessions auto-save every 15 min and auto-restore on tmux start.)

---

## Quick reference — when to reach for what

| I want to… | Use |
|---|---|
| Re-run a recent command | `Ctrl-R` (HSM) |
| Search history with metadata (where, when, exit code) | `Ctrl-X Ctrl-R` (atuin TUI) |
| See history scoped to *this directory* | `Ctrl-X Ctrl-R`, then `Ctrl-R` (atuin) to cycle to Directory mode |
| Compose a chain from multiple history hits | `Ctrl-X Ctrl-Y` (insert at cursor, atuin) |
| Edit the current long command | `Ctrl-X Ctrl-E` (open in `$EDITOR`) |
| Fix the typo I just hit Enter on | `f` |
| Jump to a project I've been in before | `z <name>` |
| Find files matching a pattern | `ff` / `ffe ext` / `ffd` |
| Search file contents | `rg "pattern"` |
| Quick command cheat sheet | `tldr <command>` |
| Pick a branch / commit / file via fuzzy match | `Ctrl-G B` / `H` / `S` |
| Kill a process I see in `ps` | `fkill` |
| Multi-pick text from a tmux pane | `prefix Tab` (extrakto) |
| Jump between tmux sessions | `prefix F` (tmux-fzf) |

---

## When you forget a key

- For atuin TUI internals: `Ctrl-O` opens an inspect overlay (sometimes shows hints), or check this file.
- For tmux: `prefix ?` lists every binding currently active.
- For zsh keybindings: `bindkey` (no args) prints every bound key in the current keymap.
- For any tool's flags: `tldr <tool>`.

---

*Generated for the dotfiles `shell-speedup` overhaul. Update this file when you add new bindings.*
