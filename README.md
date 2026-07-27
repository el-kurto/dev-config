# dev-config

Shared, portable dev tooling — OS-agnostic (NixOS, nix-darwin, nixos-wsl) and
theme-agnostic. Bundles [nvf](https://github.com/notashelf/nvf) (neovim), tmux,
zsh, lazygit, direnv/nix-direnv, devenv, and a claude-code base.

Each host **owns the `enable` decision and extends, merges, or overrides** this
common base. Nothing here is host-, project-, or OS-specific; theming (stylix
palette) is host-owned.

## How it works

The tool modules **self-gate on their upstream `enable` option**. Importing a
module (or the bundle) does **not** turn anything on — it only layers the shared
base config *when the host has enabled that tool*:

```nix
# host-side
programs.zsh.enable = true;   # host decides
# dev-config then fills in prezto, pmodules, etc. via `mkIf config.programs.zsh.enable`
```

This keeps the bundle inert until opted into, so a single `imports = [ default ]`
is safe everywhere — headless hosts that never enable these tools get nothing.

Opinionated scalar defaults (tmux `prefix`, `historyLimit`, …) are set with
`lib.mkDefault`, so a host can override them by plain assignment — no `mkForce`.
List/lines/attr options (permissions, `extraConfig`, prezto `pmodules`, claude
`context`) **merge** with host additions automatically.

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

Import the aggregate bundle (tmux + zsh + lazygit + direnv + claude), or
cherry-pick, then **enable the tools you want host-side**:

```nix
imports = [
  inputs.dev-config.homeManagerModules.default   # tmux + zsh + lazygit + direnv + claude
  # or cherry-pick:
  # inputs.dev-config.homeManagerModules.tmux
  # inputs.dev-config.homeManagerModules.zsh
  # inputs.dev-config.homeManagerModules.lazygit
  # inputs.dev-config.homeManagerModules.direnv
  # inputs.dev-config.homeManagerModules.devenv   # not in default — gate host-side
  # inputs.dev-config.homeManagerModules.claude
];

programs = {
  tmux.enable = true;
  zsh.enable = true;
  lazygit.enable = true;
  direnv.enable = true;
  claude-code.enable = true;
};
```

`zsh` needs a system-level `programs.zsh.enable` too (and a login-shell switch)
if you want it as the interactive shell — that's a host concern, not part of
this home-manager bundle.

`devenv` is exported separately (not in `default`) so hosts can gate it behind a
`development` trait. Themed bits (tmux status bar / pane colors, delta color
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
  zsh.nix              # prezto base
  lazygit.nix
  direnv.nix           # direnv + nix-direnv
  devenv.nix           # devenv package (cherry-pick, host-gated)
  claude.nix           # wrapped claude-code + permissions/context/settings
  nvf/
    nvf.nix            # enables nvf, merges parts into settings.vim
    parts/             # one file per concern
```
