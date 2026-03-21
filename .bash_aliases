alias v="nvim"
alias g="git"

alias sc="source ~/.bashrc"
alias vial="nvim ~/.bash_aliases"

alias vnc="nvim ~/nixos-config/hosts/thinkpad-t14/configuration.nix"
alias nrt="sudo nixos-rebuild test --flake ~/nixos-config#thinkpad-t14"
alias nrs="sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-t14"

alias ai-router='~/nixos-config/scripts/ai-router.sh'
alias claude-local='~/nixos-config/scripts/ai-router.sh --local'
alias claude-local-qwen='CLAUDE_LOCAL_MODEL="qwen3:4b" ~/nixos-config/scripts/ai-router.sh --local'
