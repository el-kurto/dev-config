{claude-code}: {
  pkgs,
  lib,
  config,
  ...
}: let
  claude-status-line = pkgs.writeShellApplication {
    name = "claude-status-line";
    runtimeInputs = [pkgs.jq pkgs.git pkgs.coreutils];
    text = ''
      SEPARATOR=" • "

      segments=()
      add() {
        if [ -n "''${1-}" ]; then segments+=("$1"); fi
      }

      git_in() {
        git -C "$workspace_dir" "$@" 2>/dev/null || true
      }

      fields=()
      while IFS= read -r field; do
        fields+=("$field")
      done < <(jq -r '[
        .model.display_name,
        .workspace.current_dir,
        (.worktree.name // .workspace.git_worktree),
        .effort.level,
        .context_window.used_percentage,
        .rate_limits.five_hour.used_percentage,
        .rate_limits.five_hour.resets_at,
        .rate_limits.seven_day.used_percentage,
        .rate_limits.seven_day.resets_at
      ] | map(. // "" | tostring)[]' 2>/dev/null)

      model=''${fields[0]-}
      workspace_dir=''${fields[1]-}
      worktree=''${fields[2]-}
      effort=''${fields[3]-}
      ctx=''${fields[4]-}
      five_used=''${fields[5]-}
      five_reset=''${fields[6]-}
      week_used=''${fields[7]-}
      week_reset=''${fields[8]-}

      workspace_dir=''${workspace_dir:-$PWD}

      toplevel=$(git_in rev-parse --show-toplevel)
      add "$(basename "''${toplevel:-$workspace_dir}")"

      branch=$(git_in branch --show-current)
      if [ -n "$branch" ]; then
        if [ -n "$(git_in status --porcelain)" ]; then
          branch+="*"
        fi

        behind=0 ahead=0
        read -r behind ahead < <(git_in rev-list --left-right --count '@{upstream}...HEAD') || true
        if [ "''${ahead:-0}" -gt 0 ]; then branch+=" ↑$ahead"; fi
        if [ "''${behind:-0}" -gt 0 ]; then branch+=" ↓$behind"; fi

        if [ -n "$worktree" ]; then branch+=" [$worktree]"; fi
      fi
      add "$branch"

      add "$model"
      add "$effort"

      if [ -n "$ctx" ]; then
        add "$(printf '%.0f%% ctx' "$ctx")"
      fi

      now=$(date +%s)

      if [ -n "$five_used" ]; then
        five=$(printf '%.0f%%/5h' "$five_used")
        if [ -n "$five_reset" ]; then
          five+=" ($(date -d "@$five_reset" +'%-l:%M%P'))"
        fi
        add "$five"
      fi

      if [ -n "$week_used" ]; then
        week=$(printf '%.0f%%/wk' "$week_used")
        if [ -n "$week_reset" ]; then
          days=$(( (week_reset - now + 86399) / 86400 ))
          if [ "$days" -lt 0 ]; then days=0; fi
          week+=" (''${days}d)"
        fi
        add "$week"
      fi

      if [ ''${#segments[@]} -gt 0 ]; then
        line=''${segments[0]}
        for segment in "''${segments[@]:1}"; do
          line+="$SEPARATOR$segment"
        done
        printf '%s\n' "$line"
      fi
    '';
  };

  claudePackage = claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

  claudeWrapped = pkgs.symlinkJoin {
    name = "claude-wrapped";
    inherit (claudePackage) version meta;
    paths = [claudePackage];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set DISABLE_TELEMETRY 1 \
        --set DISABLE_ERROR_REPORTING 1 \
        --set DISABLE_FEEDBACK_COMMAND 1 \
        --set CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY 1 \
        --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
    '';
  };
in {
  programs.codex.enable = lib.mkDefault false;

  programs.claude-code = lib.mkIf config.programs.claude-code.enable {
    package = lib.mkDefault claudeWrapped;

    settings = {
      model = lib.mkDefault "opus";
      includeCoAuthoredBy = lib.mkDefault false;
      alwaysThinkingEnabled = lib.mkDefault false;
      autoCompactEnabled = lib.mkDefault true;
      feedbackSurveyRate = lib.mkDefault 0;
      respectGitignore = lib.mkDefault true;
      statusLine = lib.mkDefault {
        type = "command";
        command = "${lib.getExe claude-status-line}";
      };
      enabledPlugins = {
        "typescript-lsp@claude-plugins-official" = true;
        "csharp-lsp@claude-plugins-official" = true;
      };
      permissions = {
        allow = [
          "Bash(nix eval *)"
          "Bash(nix build *)"
          "Bash(nix flake check *)"
          "Bash(nix flake show *)"
          "Bash(nix flake lock *)"
          "Bash(nix flake update *)"
          "Bash(nix flake metadata *)"
          "Bash(nix flake prefetch *)"
          "Bash(nix fmt *)"
          "Bash(nix hash convert *)"
          "Bash(nix repl *)"
          "Bash(nix-prefetch-url *)"
          "Bash(nix-hash *)"
          "Bash(nh search *)"
          "Bash(fd *)"
          "Bash(tree *)"
          "Bash(find *)"
          "Bash(ls *)"
          "Bash(cp *)"
          "Bash(gh pr list *)"
          "Bash(gh pr view *)"
          "Bash(gh pr diff *)"
          "Bash(gh pr checks *)"
          "Bash(gh pr status *)"
          "Bash(gh pr create *)"
          "Bash(gh issue list *)"
          "Bash(gh issue view *)"
          "Bash(gh issue status *)"
          "Bash(gh api -X GET *)"
          "Bash(gh release list *)"
          "Bash(gh release view *)"
          "Bash(gh repo view *)"
          "Bash(gh search *)"
          "Bash(gh run list *)"
          "Bash(gh run view *)"
          "Bash(gh workflow list *)"
          "Bash(gh workflow view *)"
          "Bash(gh cache list *)"
          "Bash(gh label list *)"
          "Bash(gh gist list *)"
          "Bash(gh gist view *)"
          "Bash(gh auth status *)"
          "Bash(git add *)"
          "Bash(git remote prune *)"
          "Bash(git fetch *)"
          "Bash(git diff *)"
          "Bash(git log *)"
          "Bash(git status *)"
          "Bash(git show *)"
          "Bash(git branch --list *)"
          "Bash(git branch -a *)"
          "Bash(git branch -v *)"
          "Bash(git branch -vv *)"
          "Bash(git remote -v)"
          "Bash(git remote show *)"
          "Bash(git rev-parse *)"
          "Bash(git blame *)"
          "Bash(git stash list *)"
          "Bash(git tag --list *)"
          "Bash(git describe *)"
          "Bash(git shortlog *)"
          "Bash(git check-ignore *)"
          "Bash(git check-attr *)"
          "Bash(git check-ref-format *)"
          "Bash(git check-mailmap *)"
          "Bash(grep *)"
          "Bash(curl *)"
          "Bash(python3 *)"
          "Bash(wc *)"
          "Bash(xargs rg *)"
          "Bash(xargs ls *)"
          "Bash(xargs nix hash convert *)"

          "WebSearch"
          "WebFetch(domain:github.com)"
          "WebFetch(domain:raw.githubusercontent.com)"
          "WebFetch(domain:api.github.com)"
          "WebFetch(domain:gist.github.com)"
          "WebFetch(domain:wiki.nixos.org)"
          "WebFetch(domain:discourse.nixos.org)"
          "WebFetch(domain:search.nixos.org)"
          "WebFetch(domain:mynixos.com)"
          "WebFetch(domain:nix-community.github.io)"
          "WebFetch(domain:wiki.hypr.land)"
          "WebFetch(domain:wiki.archlinux.org)"
          "WebFetch(domain:www.freedesktop.org)"
          "WebFetch(domain:grafana.com)"
          "WebFetch(domain:community.grafana.com)"
          "WebFetch(domain:dokploy.com)"
          "WebFetch(domain:docs.dokploy.com)"
          "WebFetch(domain:zitadel.com)"
          "WebFetch(domain:continuwuity.org)"
          "WebFetch(domain:developers.plane.so)"
          "WebFetch(domain:developer.1password.com)"
          "WebFetch(domain:notashelf.github.io)"
          "WebFetch(domain:nvf.notashelf.dev)"
          "WebFetch(domain:www.openssh.org)"
        ];
        deny = [];
      };
    };

    context = ''
      IMPORTANT: Do not write comments in code unless explicitly requested by the user.

      IMPORTANT: Do not write ad-hoc Python scripts.

      IMPORTANT: Never `brew install` (or otherwise use Homebrew). We manage packages declaratively via nixos/nix-darwin/nixos-wsl everywhere. For one-off tool use where a global install is not appropriate, use `nix run` instead.

      IMPORTANT: Keep responses concise and simple. Prefer bullet points over prose. No preamble, no recap, no verbose explanations. Answer the question directly.
    '';
  };
}
