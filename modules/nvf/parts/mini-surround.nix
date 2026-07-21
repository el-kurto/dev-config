_: {
  mini.surround.enable = true;
  mini.surround.setupOpts.mappings = {
    add = "gsa";
    delete = "gsd";
    replace = "gsr";
    find = "gsf";
    find_left = "gsF";
    highlight = "gsh";
    update_n_lines = "gsn";
  };

  binds.whichKey.register."gs" = "+surround";
}
