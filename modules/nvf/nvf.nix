{
  lib,
  pkgs,
  config,
  ...
}: {
  programs.nvf.settings.vim =
    lib.mkMerge (map (p: import p {inherit lib pkgs config;}) (import ./parts/list.nix));
}
