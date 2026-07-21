{claude-code}: {...}: {
  imports = [
    ./tmux.nix
    ./lazygit.nix
    ./direnv.nix
    (import ./claude.nix {inherit claude-code;})
  ];
}
