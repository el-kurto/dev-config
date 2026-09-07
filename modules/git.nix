{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.programs.git.enable {
    programs.git.ignores = [
      "*.vimrc"
      ".direnv"
      "**/.claude/settings.local.json"
      ".devenv*"
      "devenv.local.nix"
      "devenv.local.yaml"
    ];

    programs.git.settings = {
      core.autocrlf = "input";

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      branch = {
        autoSetupMerge = "simple";
        sort = "-committerdate";
      };

      fetch = {
        prune = true;
        pruneTags = true;
        fsckObjects = true;
      };

      pull.ff = "only";

      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };

      merge.conflictStyle = "zdiff3";

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        mnemonicPrefix = true;
        renames = true;
      };

      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      init.defaultBranch = "main";
      column.ui = "auto";
      help.autocorrect = "prompt";
      transfer.fsckObjects = true;
      receive.fsckObjects = true;
      log.date = "iso";
    };
  };
}
