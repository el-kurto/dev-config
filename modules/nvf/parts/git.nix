_: {
  git.gitsigns.enable = true;
  git.git-conflict.enable = true;
  utility.diffview-nvim.enable = true;

  keymaps = [
    {
      key = "<leader>gb";
      mode = ["n"];
      action = "<cmd>lua require('gitsigns').blame_line({full=true})<CR>";
      silent = true;
      desc = "Git blame line";
    }
    {
      key = "<leader>gd";
      mode = ["n"];
      action = "<cmd>DiffviewOpen<CR>";
      silent = true;
      desc = "Diff uncommitted changes";
    }
    {
      key = "<leader>gD";
      mode = ["n"];
      action = "<cmd>DiffviewOpen main...HEAD<CR>";
      silent = true;
      desc = "Diff branch vs main";
    }
    {
      key = "<leader>gh";
      mode = ["n"];
      action = "<cmd>DiffviewFileHistory %<CR>";
      silent = true;
      desc = "File history";
    }
    {
      key = "<leader>gH";
      mode = ["n"];
      action = "<cmd>DiffviewFileHistory<CR>";
      silent = true;
      desc = "Repo history";
    }
    {
      key = "<leader>gc";
      mode = ["n"];
      action = "<cmd>DiffviewClose<CR>";
      silent = true;
      desc = "Close diffview";
    }
  ];

  binds.whichKey.register."<leader>g" = "+git";
}
