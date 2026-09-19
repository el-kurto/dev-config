{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.programs.devenv;

  direnvrc = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/cachix/devenv/v${cfg.package.version}/devenv/direnvrc";
    hash = "sha256-p9dGsc/+ElCjLgTRoTFudKo+vcVNANKdvJMLReyteg8=";
  };
in {
  programs.devenv = {
    enable = lib.mkDefault true;
    enableBashIntegration = lib.mkDefault false;
    enableZshIntegration = lib.mkDefault false;
    enableFishIntegration = lib.mkDefault false;
    enableNushellIntegration = lib.mkDefault false;
  };

  programs.direnv.stdlib = lib.mkIf (cfg.enable && config.programs.direnv.enable) ''
    export DEVENV_BIN=${lib.getExe cfg.package}
  '';

  xdg.configFile."direnv/lib/devenv.sh" = lib.mkIf (cfg.enable && config.programs.direnv.enable) {
    source = direnvrc;
  };
}
