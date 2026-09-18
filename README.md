# dev-config

Shared, portable dev tooling — OS-agnostic (NixOS, nix-darwin, nixos-wsl) and
theme-agnostic. Bundles [nvf](https://github.com/notashelf/nvf) (neovim), tmux,
zsh, lazygit, direnv/nix-direnv, devenv, codegraph, and a claude-code base.

Importing a module does not enable anything. Each consumer owns the `enable`
decision; these modules only layer shared config on top once a tool is enabled.

## How it works

The tool modules **self-gate on their upstream `enable` option**:

```nix
programs.zsh.enable = true;   # you decide
# dev-config then fills in prezto, pmodules, etc. via `mkIf config.programs.zsh.enable`
```

A single `imports = [ default ]` is therefore safe everywhere — hosts that never
enable these tools get nothing.

Scalar defaults (tmux `prefix`, `historyLimit`, …) use `lib.mkDefault`, so they
can be overridden by plain assignment — no `mkForce`. List/lines/attr options
(permissions, `extraConfig`, prezto `pmodules`, claude `context`) merge with
your additions automatically.

Theming is not included — no colors, no `theme.enable`. Layer it yourself.

## Usage

Add the flake as an input, following your `nixpkgs` (and `nvf` / `claude-code`
if you already pin them):

```nix
# flake.nix inputs
nvf.url = "github:notashelf/nvf";
nvf.inputs.nixpkgs.follows = "nixpkgs";

dev-config.url = "github:OWNER/dev-config";
dev-config.inputs.nixpkgs.follows = "nixpkgs";
dev-config.inputs.nvf.follows = "nvf";
dev-config.inputs.claude-code.follows = "claude-code";
```

### Dev tooling (home-manager)

Import the aggregate bundle, or cherry-pick, then enable what you want:

```nix
imports = [
  inputs.dev-config.homeManagerModules.default   # tmux + zsh + lazygit + direnv + claude
  # or cherry-pick:
  # inputs.dev-config.homeManagerModules.tmux
  # inputs.dev-config.homeManagerModules.zsh
  # inputs.dev-config.homeManagerModules.lazygit
  # inputs.dev-config.homeManagerModules.direnv
  # inputs.dev-config.homeManagerModules.devenv   # not in default
  # inputs.dev-config.homeManagerModules.claude
  # inputs.dev-config.homeManagerModules.codegraph
];

programs = {
  tmux.enable = true;
  zsh.enable = true;
  lazygit.enable = true;
  direnv.enable = true;
  claude-code.enable = true;
  codegraph.enable = true;
};
```

`zsh` also needs a system-level `programs.zsh.enable` (and a login-shell switch)
to be your interactive shell — that is outside this home-manager bundle.

### devenv

Exported separately so it can be gated behind whatever condition you like. It
enables `programs.devenv` and, *when direnv is also enabled*, adds
`devenv direnvrc` to `programs.direnv.stdlib` so `.envrc` files can `use devenv`.

devenv's own shell hooks (`enableZshIntegration` et al.) default to **off** here.
They activate by spawning a nested `devenv shell`, which duplicates direnv's
activation; direnv is the single activation path. To use the subshell workflow
instead, set `programs.devenv.enableZshIntegration = true` and skip direnv.

### nvf

```nix
imports = [
  inputs.nvf.nixosModules.default        # or homeManager / darwin
  inputs.dev-config.nvfModules.default
];
```

The nvf module sets no colors or `theme.enable`; layer those alongside the
import via `programs.nvf.settings.vim = lib.mkMerge [ ... ]`.

### codegraph

`programs.codegraph.enable` installs the CLI wrapped with telemetry and the
bundled daemon off. The home-manager module additionally wires it into Claude
Code's `SessionStart`, `UserPromptSubmit` and `PostToolUse` hooks — indexing a
repo on first open, putting symbol locators in front of the model, and keeping
the graph current as it edits. Set `programs.codegraph.claudeHooks = false` for
the CLI alone.

The hooks are inert without an index: every one of them no-ops unless the
working directory has a `.codegraph/`, and the init hook only creates one inside
a git worktree, so it cannot litter `$HOME` or a scratch directory.

```nix
imports = [
  inputs.dev-config.codegraphModules.system      # CLI on PATH only
  inputs.dev-config.homeManagerModules.codegraph # CLI + Claude Code hooks
];
```

`codegraphModules.system` is also exported as `nixosModules.codegraph` and
`darwinModules.codegraph` — the same file, since it only sets
`environment.systemPackages`. Prefer the neutral name in a config that is shared
between the two.

The system module is only needed for hosts that reach the package outside a
home-manager user (e.g. reading `config.programs.codegraph.package` to build a
service's `PATH`); for a normal workstation the home-manager module is enough.

## Development

This repo uses [devenv](https://devenv.sh). With direnv, `cd` in and the
environment loads (`direnv allow` once). Otherwise run `devenv shell`.

Formatting and lint (alejandra, deadnix, statix) run as git hooks on commit;
`pre-commit run --all-files` runs them manually.

## Structure

```
flake.nix              # inputs (nixpkgs, nvf, claude-code) + module exports
devenv.nix             # dev shell for this repo (git hooks)
modules/
  default.nix          # aggregate dev-tooling bundle
  tmux.nix             # theme-free tmux
  zsh.nix              # prezto base
  lazygit.nix
  direnv.nix           # direnv + nix-direnv
  devenv.nix           # devenv + direnv `use devenv` hook (cherry-pick)
  claude.nix           # wrapped claude-code + permissions/context/settings
  codegraph/
    options.nix        # shared enable/package options
    package.nix        # CLI wrapped with telemetry + daemon off
    home.nix           # CLI + Claude Code hooks
    system.nix         # CLI on PATH (NixOS / darwin)
  nvf/
    nvf.nix            # enables nvf, merges parts into settings.vim
    parts/             # one file per concern
```
