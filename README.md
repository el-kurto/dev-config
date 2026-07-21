# dev-config

Shared, portable dev tooling — OS-agnostic (NixOS, nix-darwin, nixos-wsl) and
theme-agnostic. Bundles [nvf](https://github.com/notashelf/nvf) (neovim), tmux,
lazygit, direnv/nix-direnv, devenv, and a claude-code base.

Each host **extends, merges, or overrides** this common base. Nothing here is
host-, project-, or OS-specific; theming (stylix palette) is host-owned.

## Usage

Add the flake as an input, following the host's `nixpkgs` (and `nvf` /
`claude-code` if the host already pins them):

```nix
# flake.nix inputs
nvf.url = "github:notashelf/nvf";
nvf.inputs.nixpkgs.follows = "nixpkgs";

dev-config.url = "github:el-kurto/dev-config";
dev-config.inputs.nixpkgs.follows = "nixpkgs";
dev-config.inputs.nvf.follows = "nvf";
dev-config.inputs.claude-code.follows = "claude-code";
```

### Dev tooling (home-manager)

Import the aggregate bundle (tmux + lazygit + direnv + claude), or cherry-pick:

```nix
imports = [
  inputs.dev-config.homeManagerModules.default   # tmux + lazygit + direnv + claude
  # or cherry-pick:
  # inputs.dev-config.homeManagerModules.tmux
  # inputs.dev-config.homeManagerModules.lazygit
  # inputs.dev-config.homeManagerModules.direnv
  # inputs.dev-config.homeManagerModules.devenv   # not in default — gate host-side
  # inputs.dev-config.homeManagerModules.claude
];
```

`devenv` is exported separately (not in `default`) so hosts can gate it behind
a `development` trait. Themed bits (tmux status bar / pane colors, delta color
config) are **not** included — layer them host-side from your palette.

### nvf (unchanged API)

```nix
imports = [
  inputs.nvf.nixosModules.default        # or homeManager / darwin
  inputs.dev-config.nvfModules.default
];
```

Theming is host-owned. The nvf module sets no colors or `theme.enable`; layer
those alongside the import via `programs.nvf.settings.vim = lib.mkMerge [ ... ]`.

## Structure

```
flake.nix              # inputs (nixpkgs, nvf, claude-code) + module exports
modules/
  default.nix          # aggregate dev-tooling bundle
  tmux.nix             # theme-free tmux
  lazygit.nix
  direnv.nix           # direnv + nix-direnv
  devenv.nix           # devenv package (cherry-pick, host-gated)
  claude.nix           # wrapped claude-code + permissions/context/settings
  nvf/
    nvf.nix            # enables nvf, merges parts into settings.vim
    parts/             # one file per concern
```
