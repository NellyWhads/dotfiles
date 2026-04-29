# Pure-zsh preexec hints: daily nudges and Markdown-aware reminders.
# Config: command-hints.conf (or DOTFILES_COMMAND_HINTS_CONF). State: XDG cache.

autoload -Uz add-zsh-hook

typeset -g _DOTFILES_HINT_STATE_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles/command-hints.state"
typeset -gi _DOTFILES_HINT_STATE_LOADED=0
typeset -gA _DOTFILES_HINT_LAST_DAY
typeset -ga _DOTFILES_HINT_RULES
typeset -gA _DOTFILES_HINT_WATCH_CMD

_dotfiles_hints_default_rules() {
  _DOTFILES_HINT_RULES=(
    'daily|cat|bat'
    'md|cat|glow'
  )
}

_dotfiles_hints_load_config() {
  _DOTFILES_HINT_RULES=()
  local conf="${DOTFILES_COMMAND_HINTS_CONF:-${ZSH_DOTFILES}/command-hints.conf}"
  if [[ -r "$conf" ]]; then
    source "$conf"
  fi
  if [[ ${#_DOTFILES_HINT_RULES[@]} -eq 0 ]]; then
    _dotfiles_hints_default_rules
  fi
}

_dotfiles_hints_build_watch() {
  _DOTFILES_HINT_WATCH_CMD=()
  local r trig rest
  for r in "${_DOTFILES_HINT_RULES[@]}"; do
    [[ "$r" == \#* || -z "$r" ]] && continue
    rest="${r#*|}"
    trig="${rest%%|*}"
    [[ -n "$trig" ]] && _DOTFILES_HINT_WATCH_CMD[$trig]=1
  done
}

_dotfiles_hints_load_state() {
  (( _DOTFILES_HINT_STATE_LOADED )) && return
  _DOTFILES_HINT_STATE_LOADED=1
  _DOTFILES_HINT_LAST_DAY=()
  [[ -r "${_DOTFILES_HINT_STATE_FILE}" ]] || return
  local key day
  while IFS=$'\t' read -r key day; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    [[ -n "$day" ]] && _DOTFILES_HINT_LAST_DAY[$key]="$day"
  done <"${_DOTFILES_HINT_STATE_FILE}"
}

_dotfiles_hints_save_state() {
  if ! command mkdir -p "${_DOTFILES_HINT_STATE_FILE:h}" 2>/dev/null; then
    return 1
  fi
  local k tmp="${_DOTFILES_HINT_STATE_FILE}.new.$$"
  : >|"${tmp}"
  for k in ${(ko)_DOTFILES_HINT_LAST_DAY}; do
    print -r -- "$k	${_DOTFILES_HINT_LAST_DAY[$k]}"
  done >|"${tmp}"
  command mv -f "${tmp}" "${_DOTFILES_HINT_STATE_FILE}"
}

# Args: words without the command (positions 2..end).
_dotfiles_hints_line_has_md() {
  local w
  for w in "$@"; do
    [[ "$w" == -* ]] && continue
    [[ "$w" == *.([mM][dD]) ]] && return 0
  done
  return 1
}

_dotfiles_hints_print() {
  # Match alias-tips palette (blue / bold suggestion).
  print -r -- $'\e[94mCommand hint: \e[1;94m'"${1}"$'\e[0m' >&2
}

_dotfiles_command_hints_preexec() {
  local line="$1"
  [[ -z "$line" ]] && return
  local -a words
  if ! words=(${(z)line}) 2>/dev/null; then
    return 0
  fi
  (( ${#words} )) || return 0
  local cmd="${words[1]}"
  (( ${+_DOTFILES_HINT_WATCH_CMD[$cmd]} )) || return 0

  local today
  today="$(command date +%Y-%m-%d)" || return 0

  local r mode trig bin rest
  for r in "${_DOTFILES_HINT_RULES[@]}"; do
    [[ "$r" == \#* || -z "$r" ]] && continue
    mode="${r%%|*}"
    rest="${r#*|}"
    trig="${rest%%|*}"
    bin="${rest#*|}"
    [[ "$trig" == "$cmd" ]] || continue
    command -v "$bin" >/dev/null 2>&1 || continue

    if [[ "$mode" == "md" ]]; then
      if _dotfiles_hints_line_has_md "${words[@]:1}"; then
        _dotfiles_hints_print "use ${bin} for Markdown in the terminal (e.g. ${bin} <file.md>)"
      fi
    elif [[ "$mode" == "daily" ]]; then
      if _dotfiles_hints_line_has_md "${words[@]:1}"; then
        continue
      fi
      local key="daily|${cmd}|${bin}"
      _dotfiles_hints_load_state
      if [[ "${_DOTFILES_HINT_LAST_DAY[$key]}" == "$today" ]]; then
        continue
      fi
      _dotfiles_hints_print "prefer ${bin} over ${cmd} (richer output)"
      _DOTFILES_HINT_LAST_DAY[$key]="$today"
      _dotfiles_hints_save_state
    fi
  done
}

_dotfiles_hints_load_config
_dotfiles_hints_build_watch
add-zsh-hook preexec _dotfiles_command_hints_preexec
