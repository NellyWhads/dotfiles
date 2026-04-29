#!/usr/bin/env bash
# Find remaining pyenv / layout python references that could trigger "pyenv shell"
set -e
echo "=== Checking home shell configs ==="
for f in .zshrc .zprofile .zshenv .bash_profile .bashrc .envrc; do
  path="${HOME}/${f}"
  if [[ -f "$path" ]]; then
    if grep -q -E "pyenv|layout python|use python|\.python-version" "$path" 2>/dev/null; then
      echo "FOUND in ${path}:"
      grep -n -E "pyenv|layout python|use python|\.python-version" "$path" || true
    fi
  fi
done
echo ""
echo "=== Checking .envrc files under Repos and workspaces ==="
find "${HOME}/Repos" "${HOME}/workspaces" -name ".envrc" -type f 2>/dev/null | while read -r f; do
  if grep -q -E "pyenv|layout python|use python" "$f" 2>/dev/null; then
    echo "FOUND in ${f}:"
    grep -n -E "pyenv|layout python|use python" "$f" || true
  fi
done
echo ""
echo "=== Checking .python-version files ==="
find "${HOME}/Repos" "${HOME}/workspaces" -name ".python-version" -type f 2>/dev/null
