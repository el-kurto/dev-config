_: let
  worktreeComponent =
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
  statusline.lualine.sectionSeparator.left = "";
  statusline.lualine.sectionSeparator.right = "";
  statusline.lualine.componentSeparator.left = "";
  statusline.lualine.componentSeparator.right = "";

  # statusline.lualine.activeSection.a = [''"mode"'']; # using defaults
  statusline.lualine.activeSection.b = [''"branch"'' worktreeComponent];
  statusline.lualine.activeSection.c = [''"lsp_status"''];

  statusline.lualine.activeSection.x = [''"encoding"''];
  statusline.lualine.activeSection.y = [''"progress"''];
  statusline.lualine.activeSection.z = [''"%l:%c"''];
}
