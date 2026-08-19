{
  lib,
  config,
  ...
}: {
  programs.devenv = {
    enable = lib.mkDefault true;
    enableBashIntegration = lib.mkDefault false;
    enableZshIntegration = lib.mkDefault false;
    enableFishIntegration = lib.mkDefault false;
    enableNushellIntegration = lib.mkDefault false;
  };

  programs.direnv.stdlib = lib.mkIf (config.programs.devenv.enable && config.programs.direnv.enable) ''
    eval "$(${lib.getExe config.programs.devenv.package} direnvrc)"
  '';
}
