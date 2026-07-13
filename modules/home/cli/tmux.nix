{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";

    # === Plugins ===
    plugins = with pkgs.tmuxPlugins; [
      sensible
      catppuccin
      yank
      better-mouse-mode

      # Session saving (commented for now)
      # resurrect     # Save and restore tmux sessions
      # continuum     # Auto save every 15 minutes
    ];

    extraConfig = ''
      # General settings
      set -ga terminal-overrides ",*256col*:Tc"
      set -g renumber-windows on
      set -g detach-on-destroy off
      set -g focus-events on
      set -g set-clipboard on
      setw -g pane-base-index 1
      setw -g automatic-rename on
      set -g automatic-rename-format '#{b:pane_current_path}'

      # Catppuccin Theme
      set -g @catppuccin_flavor "mocha"
      set -g @catppuccin_window_status_style "basic"
      set -g @catppuccin_status_background "theme"
      set -g @catppuccin_date_time_format "%H:%M"
      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_current_text "#W"

      # Key bindings
      bind C-a send-prefix
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R

      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Yank configuration
      set -g @yank_selection_mouse "clipboard"
      set -g @yank_action "copy-paste"
    '';
  };
}
