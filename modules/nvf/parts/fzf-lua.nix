_: {
  fzf-lua.enable = true;
  fzf-lua.profile = "telescope";
  fzf-lua.setupOpts = {
    winopts = {
      border = "single";
      preview = {
        border = "single";
        scrollbar = false;
      };
    };
  };

  luaConfigRC.fzf-lua-ui-select =
    # lua
    ''
      require('fzf-lua').register_ui_select()
    '';

  keymaps = [
    {
      key = "<leader>/";
      mode = ["n"];
      action = "<cmd>FzfLua live_grep<CR>";
      silent = true;
      desc = "Grep";
    }
    {
      key = "<leader>ff";
      mode = ["n"];
      action = "<cmd>FzfLua files<CR>";
      silent = true;
      desc = "Find files";
    }
    {
      key = "<leader>fr";
      mode = ["n"];
      action = "<cmd>FzfLua oldfiles<CR>";
      silent = true;
      desc = "Recent files";
    }
    {
      key = "<leader>fb";
      mode = ["n"];
      action = "<cmd>FzfLua buffers<CR>";
      silent = true;
      desc = "Buffers";
    }
    {
      key = "<leader>fd";
      mode = ["n"];
      action = "<cmd>FzfLua diagnostics_document<CR>";
      silent = true;
      desc = "Document diagnostics";
    }
    {
      key = "<leader>gs";
      mode = ["n"];
      action = "<cmd>FzfLua git_status<CR>";
      silent = true;
      desc = "Git status";
    }
    {
      key = "<leader>gl";
      mode = ["n"];
      action = "<cmd>FzfLua git_commits<CR>";
      silent = true;
      desc = "Git log";
    }
    {
      key = "<leader>gL";
      mode = ["n"];
      action = "<cmd>FzfLua git_bcommits<CR>";
      silent = true;
      desc = "Git log (buffer)";
    }
  ];

  binds.whichKey.register."<leader>f" = "+find";
}
