{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.programs.zsh.enable {
    programs = {
      zsh = {
        enableCompletion = lib.mkDefault false;
        prezto = {
          enable = lib.mkDefault true;
          pmodules = [
            "environment"
            "terminal"
            "editor"
            "completion"
            "history"
            "directory"
            "utility"
            "syntax-highlighting"
          ];
        };
      };
      direnv.enableZshIntegration = lib.mkDefault true;
    };
  };
}
