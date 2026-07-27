{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.programs.direnv.enable {
    programs.direnv = {
      silent = lib.mkDefault true;
      enableBashIntegration = lib.mkDefault true;
      config.global.load_dotenv = lib.mkDefault true;
      nix-direnv.enable = lib.mkDefault true;
    };
  };
}
