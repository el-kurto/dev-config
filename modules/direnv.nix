{...}: {
  programs.direnv = {
    enable = true;
    silent = true;
    enableBashIntegration = true;
    config.global.load_dotenv = true;
    nix-direnv.enable = true;
  };
}
