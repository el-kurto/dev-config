{...}: {
  programs.lazygit = {
    enable = true;
    settings = {
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
