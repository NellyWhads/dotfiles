# Dotfiles speed-up proposal

Worktree branch: `shell-speedup` (based on `update_configs`)
Goal: cut `zsh` startup, reduce management overhead, keep cross-platform support
(macOS, modern Ubuntu, Arch).

The actual scaffolded changes on this branch implement **Option A (antidote +
cross-cutting wins)**. The Sheldon variant is sketched at the bottom; if you
prefer it I can swap the branch over.

---

## 1. Why your current setup is slow

Your `zsh/.zshrc` runs `antigen` against `oh-my-zsh` plus 14 plugins. The pain
breaks down into four buckets:

1. **antigen overhead.** Antigen sources `oh-my-zsh.sh` on every shell, then
   sources every plugin individually, then runs `compinit`. Even with its
   bundle-cache it does git timestamp checks. It is the single largest source
   of latency for your config and is also unmaintained (last release 2019).
2. **`unixorn/autoupdate-antigen.zshplugin`.** Periodically network-pings
   plugin remotes during shell init. When the network is slow, your prompt
   blocks.
3. **`lukechilds/zsh-nvm` + nvm.** nvm is the slowest commonly-used dotfile
   dependency on the planet (sources \~700 lines of bash). You already use
   `mise` for tooling — node should live there too.
4. **No `compinit` cache strategy.** `compinit -C` (or the dump-once-a-day
   pattern) typically saves 50–200ms per shell on its own.

Smaller contributors: `zsh-lsd` (replaceable by `alias ls=lsd`),
`history-search-multi-word` (replaceable by `fzf` Ctrl-R), the OMZ `git`,
`common-aliases`, `mise`, `uv` plugins (which are mostly aliases plus, for
`mise`, the hidden `mise activate zsh` call you currently rely on without
realizing it).

Typical numbers people report when migrating from antigen+OMZ to a modern
manager with the cleanups below: **\~600–1200 ms → \~80–200 ms** on macOS,
similar on Linux.

---

## 2. Three options

### Option A — antidote (recommended) ✅

[antidote](https://getantidote.github.io) is the spiritual successor to
antigen/antibody by the same author who maintained antibody. It reads a
`.zsh_plugins.txt` file with one plugin per line (same syntax you already
use), bundles them into a single static script, and `source`s that. No git
checks at runtime. No oh-my-zsh framework load — but OMZ plugins still work
because antidote knows how to fetch the relevant subdirectories on demand.

Why this fits you:

- **Migration is mechanical.** Your current `antigen bundle ...` lines map
  almost 1:1 to lines in `.zsh_plugins.txt`.
- **Available everywhere you target:** `brew install antidote` (macOS),
  `apt install zsh-antidote` (Ubuntu 24.04+; otherwise install via git
  clone, one liner), `pacman -S zsh-antidote` from AUR.
- **No Rust toolchain required.** Pure zsh, MIT licensed, actively
  maintained.
- Supports lazy loading via `kind:defer` annotations, which we use for
  syntax highlighting + autosuggestions.

Tradeoff: it is still a plugin manager — there is one moving piece beyond
zsh itself.

### Option B — sheldon (Rust, TOML)

[sheldon](https://sheldon.cli.rs) is a Rust binary that reads a TOML config
and emits a fully-resolved zsh init script you `eval` (cached on disk). The
philosophy mirrors your `mise.toml` setup.

Why this could fit:

- **Declarative TOML matches your `mise.toml` style.** You can pin plugin
  refs and templates explicitly.
- **Very fast** — comparable to antidote, sometimes faster because the
  generated script is the most minimal of the bunch.
- **Cross-platform binaries:** `brew install sheldon`,
  `cargo install sheldon-cli` on Linux (no apt package on Ubuntu LTS
  outside snaps), AUR has `sheldon`.

Tradeoffs: bigger conceptual change from antigen, an extra Rust binary in
the install path, and OMZ plugins need a two-line template to source the
right files.

### Option C — handcrafted (no plugin manager)

Drop the manager entirely. Clone 4–5 plugins as git submodules under
`zsh/plugins/`, source them directly from `.zshrc`, lazy-load the heavy
ones with [`zsh-defer`](https://github.com/romkatv/zsh-defer).

Why this could fit:

- **Fastest possible startup** (\~50–100 ms is realistic).
- **Zero external tools** beyond zsh + `git`.
- You drop \~80% of your plugin list because most OMZ bundles you use are
  small enough to inline as aliases/functions.

Tradeoffs: highest one-time effort. Plugin updates are manual
(`git submodule update --remote`). You give up the OMZ `git` plugin's full
alias set unless you copy it in.

---

## 3. Cross-cutting wins (apply to any of A/B/C)

These together usually beat the choice of plugin manager. The
`shell-speedup` branch already implements all of them.

### 3.1 Move `node` from zsh-nvm to mise

Replace the `lukechilds/zsh-nvm` bundle entirely. Add to `mise/mise.toml`:

```toml
[tools]
node = "lts"
```

`mise` shims node and gives you `.tool-versions` / `.mise.toml`-per-project
switching, and the activation cost is one Rust binary call vs nvm's bash
sourcing.

### 3.2 Make the `mise activate zsh` hook explicit

Today you rely on the OMZ `mise` plugin to run `eval "$(mise activate zsh)"`
silently. When you drop OMZ, add it to `.zshrc` directly. Equivalent and
not slower:

```zsh
eval "$(mise activate zsh)"
```

(If you prefer zero shell-hook overhead, `mise activate zsh --shims` swaps
hooks for a `~/.local/share/mise/shims` PATH entry. Slightly slower per
command, faster per shell init.)

### 3.3 Cache `compinit`

Standard pattern, saves 50–200ms per shell:

```zsh
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-${HOME}}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
```

### 3.4 Defer the heavy plugins

`zsh-autosuggestions` and `fast-syntax-highlighting` together account for
the majority of post-source latency. Antidote, sheldon, and `zsh-defer`
all support deferring them until after the first prompt draws. The user
sees a prompt instantly; suggestions/highlights flash in <50ms later.

### 3.5 Drop `unixorn/autoupdate-antigen.zshplugin`

It only existed to update antigen. We're not using antigen anymore.
Updates happen via `brew upgrade` / `apt upgrade` / `pacman -Syu`.

### 3.6 Replace `history-search-multi-word` with fzf

`fzf` is one binary, every package manager has it, and Ctrl-R fuzzy
history is qualitatively better. Add to `mise.toml` or system pkg
manager. The `.zshrc` snippet is two lines:

```zsh
[[ -r /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
```

### 3.7 Inline the small OMZ plugins

`common-aliases`, `cp`, `safe-paste`, `tmux`, `uv`, `mise`, `debian` — the
parts you actually use are a dozen lines of aliases. We copy the ones you
use into a `zsh/aliases.zsh` and stop pulling the framework.

Specifically `cp` (interactive cp/mv/rm), `safe-paste` (bracketed paste
mode), and `command-not-found` ship with modern zsh / package managers
already.

### 3.8 `zcompile` your rcfile

`.zshrc` and the bundled plugin file are good candidates. One-liner in
the install script:

```zsh
zsh -c 'zcompile ~/.zshrc'
```

Saves \~10–30ms but is essentially free.

### 3.9 Drop the `z-shell/zsh-lsd` plugin

It's a 5-line shim. Replace with one alias in `aliases.zsh`:

```zsh
command -v lsd >/dev/null && alias ls='lsd'
```

### 3.10 Theme: keep `alien-minimal`, or move to Starship

`alien-minimal` is light enough that the win from migrating is small. If
you want one config file that works in zsh / bash / fish / nu / pwsh,
[Starship](https://starship.rs) is the move (`brew install starship`,
`pacman -S starship`, `cargo install starship`). The branch keeps your
existing theme by default.

---

## 4. Recommended path: A + all of §3

Estimated work: 30–45 minutes one-time, including testing on macOS.

What it looks like in this branch:

```
zsh/.zshrc                ← thin, no antigen
zsh/.zsh_plugins.txt      ← antidote bundle list
zsh/aliases.zsh           ← inlined OMZ aliases you actually use
zsh/install.sh            ← installs antidote + fzf + lsd cross-platform
mise/mise.toml            ← adds node = "lts" and fzf via aspect-build
README.md                 ← updated install instructions
```

Skim the diff with:

```bash
git diff update_configs..shell-speedup -- zsh/ mise/ README.md
```

---

## 5. Sheldon variant (Option B), for reference

If you'd rather go declarative-TOML:

`zsh/plugins.toml`:

```toml
shell = "zsh"

[plugins.zsh-completions]
github = "zsh-users/zsh-completions"

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]

[plugins.fast-syntax-highlighting]
github = "zdharma-continuum/fast-syntax-highlighting"
apply = ["defer"]

[plugins.alien-minimal]
github = "nellywhads/alien-minimal"

[plugins.omz-git]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/git"

[templates]
defer = "{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}"
```

`zsh/.zshrc` snippet:

```zsh
eval "$(sheldon source)"
```

Same cross-cutting wins, different plugin layer.

---

## 6. Things I deliberately left out

- **zsh4humans (z4h)** — too opinionated, replaces too much of your
  config (tmux integration, ssh wrapper, etc.). You'd be migrating to
  someone else's setup, not speeding up your own.
- **zinit** — fastest possible with turbo mode, but the config language
  is its own learning curve and the original maintainer's domain
  takedown (`zdharma`) created a community fork (`zdharma-continuum`)
  that you're already using for some plugins. Adds complexity without
  much marginal win over antidote here.
- **zplug, zgen, zgenom, znap** — all fine, none clearly better than
  antidote for your workload.
- **Migrating off tmux/TPM** — TPM is fine. The only thing worth
  considering is `set -g default-terminal "tmux-256color"` and
  `set -ga terminal-overrides ",xterm-256color:Tc"` to match your
  ghostty workaround. Easy to add later.

---

## 7. Open questions for you

1. **Theme:** keep `alien-minimal`, or move to Starship?
2. **node management:** OK to drop `zsh-nvm` and let mise handle node?
   (Any project still pinning a `.nvmrc` you can't change?)
3. **`unixorn/autoupdate-antigen.zshplugin`:** confirmed dropping?
4. **Sheldon over antidote:** any preference for declarative TOML?

Tell me which of A/B/C you want me to fully build out, and which open
questions to flip, and I'll finalize the branch.
