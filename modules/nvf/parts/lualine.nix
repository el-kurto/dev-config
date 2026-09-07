{lib, ...}: let
  inherit (lib.generators) mkLuaInline;

  worktreeComponent =
    mkLuaInline
    # lua
    ''
      function()
        local git_dir = vim.fn.finddir(".git", ".;")
        local git_file = vim.fn.findfile(".git", ".;")
        if git_file ~= "" and git_dir == "" then
          local f = io.open(git_file, "r")
          if f then
            local content = f:read("*a")
            f:close()
            local wt = content:match("gitdir: .*/worktrees/([^%s]+)")
            if wt then return " " .. wt end
          end
        end
        return ""
      end
    '';
in {
  statusline.lualine.enable = true;
  statusline.lualine.setupOpts.options = {
    section_separators = {
      left = "";
      right = "";
    };
    component_separators = {
      left = "";
      right = "";
    };
  };

  # sections.lualine_a = ["mode"]; # using defaults
  statusline.lualine.setupOpts.sections = {
    lualine_b = ["branch" worktreeComponent];
    lualine_c = ["lsp_status"];

    lualine_x = ["encoding"];
    lualine_y = ["progress"];
    lualine_z = ["%l:%c"];
  };
}
