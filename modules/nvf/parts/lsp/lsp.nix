{lib, ...}: {
  lsp.enable = true;
  lsp.otter-nvim.enable = true;
  lsp.formatOnSave = true;
  lsp.lspconfig.enable = true;
  lsp.trouble.enable = true;

  augroups = [
    {
      name = "LspDocumentHighlight";
      clear = true;
    }
  ];

  autocmds = [
    {
      event = ["LspAttach"];
      pattern = ["*"];
      group = "LspDocumentHighlight";
      desc = "Enable LSP document highlight on cursor hold";
      callback =
        lib.generators.mkLuaInline
        # lua
        ''
          function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and client.server_capabilities.documentHighlightProvider then
              vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
                buffer = args.buf,
                callback = function()
                  vim.lsp.buf.document_highlight()
                end,
              })
              vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
                buffer = args.buf,
                callback = function()
                  vim.lsp.buf.clear_references()
                end,
              })
            end
          end
        '';
    }
  ];

  keymaps = [
    {
      key = "<leader>cd";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.open_float({ border = 'rounded' })<CR>";
      silent = true;
      desc = "Line diagnostics";
    }
    {
      key = "<leader>ca";
      mode = ["n" "x"];
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      silent = true;
      desc = "Code action";
    }
    {
      key = "<leader>cr";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      silent = true;
      desc = "Rename symbol";
    }
    {
      key = "<leader>cl";
      mode = ["n"];
      action = "<cmd>LspInfo<CR>";
      silent = true;
      desc = "LSP info";
    }
    {
      key = "gd";
      mode = ["n"];
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      silent = true;
      desc = "Go to definition";
    }
    {
      key = "]d";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.goto_next({ float = { border = 'rounded' } })<CR>";
      silent = true;
      desc = "Next diagnostic";
    }
    {
      key = "[d";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.goto_prev({ float = { border = 'rounded' } })<CR>";
      silent = true;
      desc = "Prev diagnostic";
    }
    {
      key = "]e";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR, float = { border = 'rounded' } })<CR>";
      silent = true;
      desc = "Next error";
    }
    {
      key = "[e";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR, float = { border = 'rounded' } })<CR>";
      silent = true;
      desc = "Prev error";
    }
    {
      key = "<leader>ud";
      mode = ["n"];
      action = "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>";
      silent = true;
      desc = "Toggle diagnostics";
    }
  ];

  binds.whichKey.register."<leader>c" = "+code";
}
