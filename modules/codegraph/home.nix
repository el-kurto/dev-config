{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.codegraph;
  cg = lib.getExe cfg.package;

  hook = name: text:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.jq];
      inherit text;
    };

  # `query`, not `explore`: explore inlines full source (~4k tokens for two
  # files) and this is fresh full-price input on every turn. Locators let the
  # model pull only the spans it wants.
  contextHook =
    hook "codegraph-context-hook"
    # bash
    ''
      input=$(cat)
      prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')
      cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

      [ -d "$cwd/.codegraph" ] || exit 0
      [ "''${#prompt}" -ge 12 ] || exit 0

      hits=$(cd "$cwd" && ${cg} query --json --limit 5 "$prompt" 2>/dev/null) || exit 0
      [ -n "$hits" ] || exit 0

      # Three filters, because a prompt with no code in it still matches
      # something. Scores are absolute rather than normalised, so a floor is
      # meaningful — but a floor alone is not enough: one stopword against a
      # variable literally named `right` scored 76 while the rest sat at 18.
      #
      # The names are what actually separate noise from signal. Every false
      # positive so far matched a short English word that happens to be an
      # identifier — `for` (the Prometheus alert attribute, five times over),
      # `Is`, `right`. Real hits are `mkChecks`, `filter`, `description`. Four
      # characters is the cut, and repetition is deliberately not penalised:
      # `mkChecks` five times across parts/checks is the answer to "what does
      # mkChecks do", not noise.
      context=$(printf '%s' "$hits" | jq -r '
        [ .[]
          | select(.score >= 35)
          | .node
          | select(.filePath != null)
          | select((.name | length) >= 4)
          | "- \(.kind) \(.qualifiedName // .name) — \(.filePath):\(.startLine)"
        ]
        | if length < 2 then empty else
            "[codegraph] possibly relevant symbols — pull the source with `codegraph explore \"<what you need>\"`, trace impact with `codegraph impact <symbol>`:\n" + join("\n")
          end
      ') || exit 0

      [ -n "$context" ] || exit 0

      jq -cn --arg ctx "$context" \
        '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
    '';

  # Incremental and ~100ms, which is why the bundled daemon stays off.
  syncHook =
    hook "codegraph-sync-hook"
    # bash
    ''
      input=$(cat)
      cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
      [ -d "$cwd/.codegraph" ] || exit 0
      (cd "$cwd" && ${cg} sync --quiet >/dev/null 2>&1) || true
    '';

  # Without this the index has to be created by hand in every repo, and the
  # context hook stays silent until someone remembers. ~600ms on a cold repo of
  # 300 files. Gated on a git worktree so it cannot litter $HOME or a scratch
  # directory, and backgrounded so a large repo does not stall session start.
  initHook =
    hook "codegraph-init-hook"
    # bash
    ''
      input=$(cat)
      cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')
      [ -n "$cwd" ] || exit 0
      ! [ -d "$cwd/.codegraph" ] || exit 0
      ${lib.getExe pkgs.git} -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1 || exit 0
      (cd "$cwd" && ${cg} init --yes >/dev/null 2>&1 &) || true
    '';

  cmd = h: {
    hooks = [
      {
        type = "command";
        command = lib.getExe h;
        timeout = 10000;
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
          Wire codegraph into Claude Code's SessionStart, UserPromptSubmit and
          PostToolUse hooks: index a repo on first open, put locators in front
          of the model, and keep the graph current as it edits. codegraph's own
          MCP server and CLAUDE.md blurb both leave it to the model to decide to
          call it; these do not.
        '';
      };
    };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    programs.claude-code.settings.hooks = lib.mkIf cfg.claudeHooks {
      SessionStart = [(cmd initHook)];
      UserPromptSubmit = [(cmd contextHook)];
      PostToolUse = [((cmd syncHook) // {matcher = "Write|Edit|MultiEdit";})];
    };
  };
}
