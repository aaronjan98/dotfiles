alias v="nvim"
alias g="git"

alias sc="source ~/.bashrc"
alias vial="nvim ~/.bash_aliases"

# Map system hostname → flake attribute name.
# ThinkPad uses the NixOS default hostname "nixos"; Framework matches directly.
_nix_host() {
    case "$(hostname)" in
        nixos) echo "thinkpad-t14" ;;
        *)     echo "$(hostname)" ;;
    esac
}

vinc() { nvim ~/nixos-config/hosts/"$(_nix_host)"/configuration.nix; }
nrt()  { sudo nixos-rebuild test   --flake ~/nixos-config#"$(_nix_host)"; }
nrs()  { sudo nixos-rebuild switch --flake ~/nixos-config#"$(_nix_host)"; }

alias ai-router='~/nixos-config/scripts/ai-router.sh'
alias claude-local='~/nixos-config/scripts/ai-router.sh --local'
alias claude-local-qwen='CLAUDE_LOCAL_MODEL="qwen3:4b" ~/nixos-config/scripts/ai-router.sh --local'

# Receiver / desk speakers — controlled via HA Matter (see scripts/speakers.sh)
alias speakers='~/nixos-config/scripts/speakers.sh'

# Manual triggers for the hourly systemd sync timers (push only → NAS)
alias sync-documents='systemctl --user start sync-documents.service'
alias sync-pictures='systemctl --user start sync-pictures.service'

# Multi-machine sync — run when arriving at or leaving this machine
alias sync-arrive='bash ~/nixos-config/scripts/sync-machine.sh --arrive'
alias sync-leave='bash ~/nixos-config/scripts/sync-machine.sh --leave'
