#!/usr/bin/env bash
# Benchmark zsh interactive startup time.
#
# Modes:
#   --current   bench your existing ~/.zshrc (default)
#   --proposed  bench the proposed setup, isolated under ~/.cache/zsh-bench-proposed/
#               (does NOT modify ~/.zshrc, ~/.antidote, ~/.zsh_plugins.zsh, etc.)
#   --compare   run both modes and print side-by-side stats
#
# Usage:
#   ./scripts/zsh-bench.sh                  # current, 10 samples
#   ./scripts/zsh-bench.sh --compare        # both, 10 samples each
#   ./scripts/zsh-bench.sh --compare -n 20  # both, 20 samples each
#   ./scripts/zsh-bench.sh --proposed -n 20 # only proposed, 20 samples
#
# Cleanup of the sandbox:
#   rm -rf ~/.cache/zsh-bench-proposed

set -eu

# Match a real terminal. With TERM=dumb (osascript / non-tty wrappers),
# some plugins/themes (e.g. alien-minimal's zsh-256color) take a much slower
# path that doesn't reflect real-world startup.
export TERM="${TERM:-xterm-256color}"
case "$TERM" in
    dumb|"") TERM=xterm-256color; export TERM ;;
esac

N=10
MODE="current"

while [ $# -gt 0 ]; do
    case "$1" in
        --current)  MODE="current"; shift ;;
        --proposed) MODE="proposed"; shift ;;
        --compare)  MODE="compare"; shift ;;
        -n)         shift; N="$1"; shift ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            # Allow legacy positional N for backward compat
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                N="$1"; shift
            else
                echo "Unknown arg: $1" 1>&2
                exit 2
            fi
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="${HOME}/.cache/zsh-bench-proposed"

setup_proposed() {
    # Build an isolated ZDOTDIR mirroring the proposed setup. Idempotent.
    # Nothing escapes $SANDBOX — antidote, the bundled plugin file, and the
    # zcompdump all live there, not in your real $HOME.
    mkdir -p "$SANDBOX"

    ln -sfn "$REPO_ROOT/zsh/.zshrc"            "$SANDBOX/.zshrc"
    ln -sfn "$REPO_ROOT/zsh/.zsh_plugins.txt"  "$SANDBOX/.zsh_plugins.txt"
    ln -sfn "$REPO_ROOT/zsh/aliases.zsh"       "$SANDBOX/aliases.zsh"

    # Antidote: prefer system install if available, else clone into sandbox.
    if [ ! -r "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ] \
       && [ ! -r "/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh" ] \
       && [ ! -r "/usr/share/zsh-antidote/antidote.zsh" ] \
       && [ ! -d "$SANDBOX/.antidote/.git" ]; then
        echo "  (first run) cloning antidote into $SANDBOX/.antidote ..." 1>&2
        git clone --quiet --depth=1 https://github.com/mattmc3/antidote.git \
            "$SANDBOX/.antidote"
    fi

    # Warm up: generate ~/.zsh_plugins.zsh in the sandbox + populate zcompdump.
    # Discard timing of this run.
    ZDOTDIR="$SANDBOX" zsh -ic 'true' >/dev/null 2>&1 || true
}

# Run one sample of `zsh -ic exit`. Uses python3 for portable nanosecond timing
# (avoids GNU date dependency on macOS).
sample_one() {
    local zdotdir="${1:-}"
    python3 - "$zdotdir" <<'PY'
import os, subprocess, sys, time
zd = sys.argv[1] if len(sys.argv) > 1 else ""
env = os.environ.copy()
if zd:
    env["ZDOTDIR"] = zd
t0 = time.perf_counter_ns()
subprocess.run(["zsh", "-ic", "exit"], env=env,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
t1 = time.perf_counter_ns()
print((t1 - t0) // 1_000_000)
PY
}

run_samples() {
    local zdotdir="$1"
    local label="$2"
    local i t
    local samples=()

    # Discard the very first sample (warmup, especially noisy on macOS).
    sample_one "$zdotdir" >/dev/null

    for (( i = 0; i < N; i++ )); do
        t=$(sample_one "$zdotdir")
        samples+=("$t")
        printf '  %s run %2d: %s ms\n' "$label" "$((i+1))" "$t"
    done

    # Sort + pick stats. bash 3.2 safe (no negative indexing).
    local sorted
    sorted=($(printf '%s\n' "${samples[@]}" | sort -n))
    local count=${#sorted[@]}
    local min=${sorted[0]}
    local max=${sorted[$((count - 1))]}
    local median=${sorted[$((count / 2))]}

    # Stash for compare summary
    eval "${label}_min=$min"
    eval "${label}_median=$median"
    eval "${label}_max=$max"

    printf '  %-10s  min=%4dms  median=%4dms  max=%4dms\n\n' "$label" "$min" "$median" "$max"
}

case "$MODE" in
    current)
        echo "Sampling CURRENT ~/.zshrc ($N runs, plus 1 warmup)..."
        run_samples "" "current"
        ;;
    proposed)
        setup_proposed
        echo "Sampling PROPOSED setup via $SANDBOX ($N runs, plus 1 warmup)..."
        run_samples "$SANDBOX" "proposed"
        ;;
    compare)
        echo "Sampling CURRENT ~/.zshrc ($N runs)..."
        run_samples "" "current"
        setup_proposed
        echo "Sampling PROPOSED setup via $SANDBOX ($N runs)..."
        run_samples "$SANDBOX" "proposed"
        echo "Summary"
        echo "-------"
        printf '  current   median=%4dms\n' "$current_median"
        printf '  proposed  median=%4dms\n' "$proposed_median"
        if [ "$current_median" -gt 0 ]; then
            speedup=$(awk -v c="$current_median" -v p="$proposed_median" \
                'BEGIN { printf "%.1fx", c / p }')
            saved=$(( current_median - proposed_median ))
            printf '  speedup   %s  (saved ~%dms per shell)\n' "$speedup" "$saved"
        fi
        echo ""
        echo "Sandbox lives at: $SANDBOX"
        echo "To remove it:     rm -rf $SANDBOX"
        ;;
esac
