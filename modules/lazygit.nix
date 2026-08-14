{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.programs.lazygit.enable {
    programs.lazygit.settings = {
      gui = {
        nerdFontsVersion = "3";
        showFileTree = true;
        showBottomLine = true;
        showRandomTip = false;
        showCommandLog = false;
      };
      git = {
        diffRenderers = [
          {
            name = "delta";
            command = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
