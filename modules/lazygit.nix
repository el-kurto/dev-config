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
        showIcons = true;
      };
      git = {
        pagers = [
          {
            name = "delta";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
