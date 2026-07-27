{...}: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = false;
      prezto = {
        enable = true;
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
    direnv.enableZshIntegration = true;
  };
}
