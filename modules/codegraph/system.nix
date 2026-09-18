{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.codegraph;
in {
  options.programs.codegraph = import ./options.nix {inherit pkgs lib;};

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
