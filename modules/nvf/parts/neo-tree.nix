{lib, ...}: {
  filetree.neo-tree.enable = true;
  filetree.neo-tree.setupOpts.git_status_async = true;
  filetree.neo-tree.setupOpts.filesystem.follow_current_file.enabled = true;

  autocmds = [
    {
      event = ["VimEnter"];
      pattern = ["*"];
      desc = "Open neo-tree on startup when no file args";
      callback =
        lib.generators.mkLuaInline
        # lua
        ''
          function()
            if vim.fn.argc() == 0 then
              vim.cmd("Neotree show")
            end
          end
        '';
    }
  ];

  keymaps = [
    {
      key = "<leader>e";
      mode = ["n"];
      action = "<cmd>Neotree toggle reveal<CR>";
      silent = true;
      desc = "Toggle file explorer";
    }
  ];
}
