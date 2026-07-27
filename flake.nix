{
  description = "Shared, portable dev tooling (neovim, tmux, zsh, lazygit, direnv, devenv, claude-code).";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

    claude-code.url = "github:sadjow/claude-code-nix";
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nvf,
    claude-code,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      flake = {
        homeManagerModules.default = import ./modules/default.nix {inherit claude-code;};

        homeManagerModules.tmux = ./modules/tmux.nix;
        homeManagerModules.zsh = ./modules/zsh.nix;
        homeManagerModules.lazygit = ./modules/lazygit.nix;
        homeManagerModules.direnv = ./modules/direnv.nix;
        homeManagerModules.devenv = ./modules/devenv.nix;
        homeManagerModules.claude = import ./modules/claude.nix {inherit claude-code;};

        # nvf config — unchanged API (nixos_config imports nvfModules.default).
        nvfModules.default = ./modules/nvf/nvf.nix;
        nixosModules.nvf = ./modules/nvf/nvf.nix;
        darwinModules.nvf = ./modules/nvf/nvf.nix;
        homeManagerModules.nvf = ./modules/nvf/nvf.nix;
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;

        packages.default =
          (nvf.lib.neovimConfiguration {
            inherit pkgs;
            modules = [
              ({lib, ...}: {
                vim = lib.mkMerge (
                  map (p: import p {inherit lib pkgs;})
                  (import ./modules/nvf/parts/list.nix)
                );
              })
            ];
          }).neovim;
      };
    };
}
