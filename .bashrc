source $HOME/.bash_aliases
export EDITOR=nvim

# create dot command to manage dotfiles
dot() {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}

### Apps ###

## Zoxide ##
eval "$(zoxide init bash)"
zq() {
  zoxide query "$@"
}

# Notify when long-running commands finish in tmux panes.
# Direct Ghostty windows are handled natively via notify-on-command-finish in ghostty config.
# Ghostty's shell integration (OSC 133) doesn't pass through tmux, so we use notify-send directly.
_ntfy_cmd_start=
trap '[[ "$BASH_COMMAND" == _ntfy_* || "$BASH_COMMAND" == __ghostty_* ]] || _ntfy_cmd_start=$SECONDS' DEBUG
_ntfy_done() {
  [[ -n "$TMUX" && -n "$_ntfy_cmd_start" ]] || return
  local e=$(( SECONDS - _ntfy_cmd_start ))
  _ntfy_cmd_start=
  (( e >= 10 )) || return
  # Suppress if the user is still looking at this pane:
  # pane_active=1, window_active=1, and Ghostty is the focused app.
  if [[ "$(tmux display-message -p '#{pane_active}#{window_active}' 2>/dev/null)" == "11" ]] \
     && hyprctl activewindow 2>/dev/null | grep -qi 'class: ghostty'; then
    return
  fi
  local win
  win=$(tmux display-message -p '#S:#W' 2>/dev/null) || win="tmux"
  notify-send --app-name="terminal" "Command finished" "Took ${e}s in ${win}"
}
if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
  [[ " ${PROMPT_COMMAND[*]} " != *" _ntfy_done "* ]] && PROMPT_COMMAND+=(_ntfy_done)
elif [[ "${PROMPT_COMMAND:-}" != *_ntfy_done* ]]; then
  PROMPT_COMMAND+=$'\n_ntfy_done'
fi
