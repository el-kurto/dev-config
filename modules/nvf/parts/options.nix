{pkgs, ...}: {
  viAlias = true;
  vimAlias = true;

  extraPlugins = {
    vim-tmux-navigator = {
      package = pkgs.vimPlugins.vim-tmux-navigator;
      setup = "vim.g.tmux_navigator_no_mappings = 1";
    };
  };

  clipboard.enable = true;
  clipboard.registers = "unnamedplus";

  diagnostics.enable = true;

  options = {
    timeoutlen = 300;
    ttimeoutlen = 0;
    updatetime = 200;

    scrolloff = 4;
    sidescrolloff = 8;

    cursorline = true;
    cursorlineopt = "both";

    shiftwidth = 2;
    tabstop = 2;
    expandtab = true;
    smartindent = false;

    wrap = false;
    number = true;
    relativenumber = true;

    ignorecase = true;
    smartcase = true;

    splitbelow = true;
    splitright = true;

    undofile = true;
    undolevels = 10000;

    signcolumn = "yes";
    colorcolumn = "+1";
    textwidth = 120;

    pumheight = 10;
    pumblend = 0;
    winblend = 0;

    inccommand = "split";

    sessionoptions = "buffers,curdir,tabpages,winsize,winpos";
  };
}
