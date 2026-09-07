{claude-code}: {...}: {
  imports = [
    ./tmux.nix
    ./zsh.nix
    ./lazygit.nix
    ./git.nix
    ./direnv.nix
    (import ./claude.nix {inherit claude-code;})
  ];
}
