source $HOME/.bash_aliases
export EDITOR=nvim

# create dot command to manage dotfiles
dot() {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}
