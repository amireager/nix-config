{...}: {
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"
      set -g renumber-windows on
      set -g detach-on-destroy off
      set -g focus-events on
      set -g set-clipboard on
      setw -g pane-base-index 1
      setw -g automatic-rename on

      # Status line — minimal Catppuccin
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g status-left "#[fg=#89b4fa,bold] #S "
      set -g status-right "#[fg=#6c7086] %H:%M "
      set -g status-left-length 20
      set -g status-right-length 20

      # Pane borders
      set -g pane-border-style "fg=#313244"
      set -g pane-active-border-style "fg=#89b4fa"

      # Window status
      setw -g window-status-current-format "#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W "
      setw -g window-status-format "#[fg=#6c7086] #I:#W "

      # Bell and activity
      set -g monitor-activity on
      set -g visual-activity off

      bind C-a send-prefix
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Resize panes (5 steps)
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Window navigation with Shift+Arrow
      bind -n S-Left  previous-window
      bind -n S-Right next-window
    '';
  };
}
