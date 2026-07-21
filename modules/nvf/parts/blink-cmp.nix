_: {
  autocomplete.blink-cmp.enable = true;
  autocomplete.blink-cmp.friendly-snippets.enable = true;
  autocomplete.blink-cmp.sourcePlugins.ripgrep.enable = true;

  autocomplete.blink-cmp.mappings = {
    complete = null;
    confirm = null;
    next = null;
    previous = null;
    close = null;
    scrollDocsUp = null;
    scrollDocsDown = null;
  };

  autocomplete.blink-cmp.setupOpts.keymap = {
    preset = "enter";
    "<C-y>" = ["select_and_accept"];
  };
}
