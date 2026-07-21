{claude-code}: {
  pkgs,
  lib,
  ...
}: let
  claude-status-line = pkgs.writeShellApplication {
    name = "claude-status-line";
    runtimeInputs = [pkgs.jq pkgs.git pkgs.bc pkgs.coreutils];
    text = ''
      input=$(cat)

      model=$(echo "$input" | jq -r '.model.display_name')
      workspace_dir=$(echo "$input" | jq -r '.workspace.current_dir')

      toplevel=$(git -C "$workspace_dir" rev-parse --show-toplevel 2>/dev/null || true)
      workspace_name=$(basename "''${toplevel:-$workspace_dir}")
      branch=$(git -C "$workspace_dir" branch --show-current 2>/dev/null || echo 'no-git')

      out="$model | $workspace_name | $branch"

      now=$(date +%s)

      five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
      five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
      if [ -n "$five_used" ]; then
        five_rem=$(printf '%.0f' "$(echo "100 - $five_used" | bc -l)")
        if [ -n "$five_reset" ]; then
          five_at=$(date -d "@$five_reset" +'%-l:%M%P')
          out="$out | ''${five_rem}%/5h ($five_at)"
        else
          out="$out | ''${five_rem}%/5h"
        fi
      fi

      week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
      week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
      if [ -n "$week_used" ]; then
        week_rem=$(printf '%.0f' "$(echo "100 - $week_used" | bc -l)")
        if [ -n "$week_reset" ]; then
          days=$(( (week_reset - now + 86399) / 86400 ))
          [ "$days" -lt 0 ] && days=0
          out="$out | ''${week_rem}%/wk (''${days}d)"
        else
          out="$out | ''${week_rem}%/wk"
        fi
      fi

      echo "$out"
    '';
  };

  claudePackage = claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

  claudeWrapped = pkgs.symlinkJoin {
    name = "claude-wrapped";
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
  programs.codex.enable = false;

  programs.claude-code = {
    enable = true;
    package = claudeWrapped;

    settings = {
      model = "opus";
      includeCoAuthoredBy = false;
      alwaysThinkingEnabled = false;
      autoCompactEnabled = true;
      feedbackSurveyRate = 0;
      respectGitignore = true;
      statusLine = {
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
      IMPORTANT: `sed` and `bash` on MacOS were installed via `nixpkgs` and use the GNU params.

      IMPORTANT: Do not write comments in code unless explicitly requested by the user.

      IMPORTANT: Do not write ad-hoc Python scripts.

      IMPORTANT: Never `brew install` (or otherwise use Homebrew). We manage packages declaratively via nixos/nix-darwin/nixos-wsl everywhere. For one-off tool use where a global install is not appropriate, use `nix run` instead.

      IMPORTANT: Keep responses concise and simple. Prefer bullet points over prose. No preamble, no recap, no verbose explanations. Answer the question directly.
    '';
  };
}
