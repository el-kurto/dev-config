{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.codegraph;

  hookPackage = import ./hook.nix {
    inherit pkgs lib;
    codegraph = cfg.package;
  };

  hook = {
    hooks = [
      {
        type = "command";
        command = lib.getExe hookPackage;
        timeout = 10;
      }
    ];
  };
in {
  options.programs.codegraph =
    import ./options.nix {inherit pkgs lib;}
    // {
      claudeHooks = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Wire codegraph into Claude Code's hooks: index a repo (or worktree,
          seeded from a sibling's index) the first time the session touches it,
          keep the graph current through edits, shell commands and HEAD moves,
          and put locators in front of both the model and the subagents it
          spawns. codegraph's own MCP server and CLAUDE.md blurb both leave it
          to the model to decide to call it; these do not.
        '';
      };
    };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    programs.claude-code.settings.permissions.allow = ["Bash(codegraph:*)"];

    programs.claude-code.settings.hooks = lib.mkIf cfg.claudeHooks {
      SessionStart = [hook];
      CwdChanged = [hook];
      DirectoryAdded = [hook];
      FileChanged = [hook];
      UserPromptSubmit = [hook];
      PreToolUse = [(hook // {matcher = "Agent|Task";})];
      PostToolUse = [(hook // {matcher = "Write|Edit|MultiEdit|NotebookEdit|Bash";})];
    };
  };
}
