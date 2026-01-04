# create dot command to manage dotfiles
dot() {
  git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}
