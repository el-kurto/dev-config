{pkgs, ...}: {
  treesitter.enable = true;
  treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
    comment
    csv
    diff
    gitattributes
    gitignore
    ini
    regex
    sql
    ssh_config
  ];

  languages = {
    enableTreesitter = true;
    enableFormat = true;
    enableExtraDiagnostics = true;

    bash.enable = true;
    css.enable = true;
    docker.enable = true;
    go.enable = true;
    go.lsp.enable = true;
    json.enable = true;
    lua.enable = true;
    markdown.enable = true;
    markdown.format.type = ["prettierd"];
    markdown.extensions.markview-nvim.enable = true;
    nix.enable = true;
    sql.enable = true;
    toml.enable = true;
    typescript.enable = true;
    xml.enable = true;
    yaml.enable = true;

    hcl.enable = true;
    terraform.enable = true;

    html.enable = true;
    html.treesitter.autotagHtml = true;
  };
}
