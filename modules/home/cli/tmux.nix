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

      bind C-a send-prefix
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };
}
