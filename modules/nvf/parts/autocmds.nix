{lib, ...}: {
  autocmds = [
    {
      event = ["FileType"];
      pattern = ["markdown"];
      desc = "Enable wrap for markdown";
      callback =
        lib.generators.mkLuaInline
        # lua
        ''
          function()
            vim.opt_local.wrap = true
          end
        '';
    }
  ];
}
