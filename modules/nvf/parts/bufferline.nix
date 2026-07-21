_: {
  tabline.nvimBufferline = {
    enable = true;
    mappings = {
      closeCurrent = "<leader>bd";
      cycleNext = null;
      cyclePrevious = null;
      pick = null;
      sortByExtension = null;
      sortByDirectory = null;
      sortById = null;
      moveNext = null;
      movePrevious = null;
    };
    setupOpts.options = {
      separator_style = "thin";
      always_show_bufferline = true;
      show_close_icon = false;
      show_buffer_close_icons = false;
      show_buffer_icons = false;
      numbers = "none";
      diagnostics = false;
      diagnostics_indicator = null;
      modified_icon = "";
      offsets = [
        {
          filetype = "neo-tree";
          text = "File Explorer";
          highlight = "Directory";
          separator = true;
        }
      ];
    };
  };

  keymaps = [
    {
      key = "<leader>bo";
      mode = ["n"];
      action = "<cmd>lua require('bufdelete').bufwipeout(vim.tbl_filter(function(b) return b ~= vim.api.nvim_get_current_buf() end, vim.api.nvim_list_bufs()))<CR>";
      silent = true;
      desc = "Delete other buffers";
    }
    {
      key = "<S-h>";
      mode = ["n"];
      action = "<cmd>BufferLineCyclePrev<CR>";
      silent = true;
      desc = "Previous buffer";
    }
    {
      key = "<S-l>";
      mode = ["n"];
      action = "<cmd>BufferLineCycleNext<CR>";
      silent = true;
      desc = "Next buffer";
    }
  ];

  binds.whichKey.register."<leader>b" = "+buffer";
}
