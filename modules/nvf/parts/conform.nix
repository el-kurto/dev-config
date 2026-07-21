_: {
  formatter.conform-nvim.enable = true;

  keymaps = [
    {
      key = "<leader>cf";
      mode = ["n" "x"];
      action = "<cmd>lua vim.lsp.buf.format({ async = true })<CR>";
      silent = true;
      desc = "Format code";
    }
    {
      key = "<leader>uf";
      mode = ["n"];
      action = "<cmd>lua vim.g.autoformat = not vim.g.autoformat; print('Autoformat (global): ' .. tostring(vim.g.autoformat))<CR>";
      silent = true;
      desc = "Toggle auto format (global)";
    }
    {
      key = "<leader>uF";
      mode = ["n"];
      action = "<cmd>lua vim.b.autoformat = not vim.b.autoformat; print('Autoformat (buffer): ' .. tostring(vim.b.autoformat))<CR>";
      silent = true;
      desc = "Toggle auto format (buffer)";
    }
  ];
}
