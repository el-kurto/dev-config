{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
    terminal = "tmux-256color";
    sensibleOnTop = true;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      tmux-which-key
      tmux-fzf
    ];

    extraConfig = ''
      set -ga terminal-overrides ",*:Tc"
      set -ga terminal-overrides ",*:RGB"

      # Extended keys (kitty/CSI-u) so terminals can distinguish C-S-j from C-j, etc.
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'

      set -gq allow-passthrough on

      set -g renumber-windows on

      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      unbind '|'
      unbind '-'

      bind C-s choose-tree -Zs

      bind c new-window -c "#{pane_current_path}"

      bind-key -T copy-mode-vi v send-keys -X begin-selection

      bind r source-file ~/.config/tmux/tmux.conf \; display "reloaded"

      # tmux-fzf (default binding: prefix + F)
      TMUX_FZF_LAUNCH_KEY="F"

      # Pane borders + labels (colors layered host-side)
      set -g pane-border-status top

      # Pane-number overlay (prefix+q) — 2s flash
      set -g display-panes-time 2000
    '';
  };
}
