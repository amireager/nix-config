{
  pkgs,
  hostname,
  flakePath,
  ...
}: {
  # ============================================================
  # FISH SHELL — Professional Developer Environment
  # ============================================================

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # ── UI & GREETING ──
      set -g fish_greeting

      # ── FISH BEHAVIOR ──
      set -g fish_autosuggestion_enabled true
      set -g fish_key_bindings fish_default_key_bindings

      # ── DEFAULT EDITOR ──
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PAGER "bat --plain"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      # ── FZF PREVIEW ──
      set -gx FZF_PREVIEW_COMMAND 'bat --style=numbers --color=always --line-range :500 {}'

      # ── CATPPUCCIN MOCHA: FISH COLORS ──
      set -g fish_color_normal cdd6f4
      set -g fish_color_command 89b4fa
      set -g fish_color_param f2cdcd
      set -g fish_color_keyword f38ba8
      set -g fish_color_quote a6e3a1
      set -g fish_color_redirection f5c2e7
      set -g fish_color_end fab387
      set -g fish_color_error f38ba8
      set -g fish_color_gray 6c7086
      set -g fish_color_selection --background=313244
      set -g fish_color_search_match --background=313244
      set -g fish_color_option a6e3a1
      set -g fish_color_operator f5c2e7
      set -g fish_color_escape eba0ac
      set -g fish_color_autosuggestion 6c7086
      set -g fish_color_cancel f38ba8

      # ── COMPLETION PAGER THEME (Catppuccin) ──
      set -g fish_pager_color_progress cyan
      set -g fish_pager_color_background --background=1e1e2e
      set -g fish_pager_color_prefix f9e2af --bold
      set -g fish_pager_color_completion cdd6f4
      set -g fish_pager_color_description a6e3a1
      set -g fish_pager_color_selected_background --background=313244
      set -g fish_pager_color_selected_prefix f9e2af --bold
      set -g fish_pager_color_selected_completion cdd6f4 --bold
      set -g fish_pager_color_selected_description 89b4fa

      # ── CUSTOM KEYBINDINGS ──
      # Ctrl+R — fzf native history widget (cleaner than fzf-fish)
      bind ctrl-r fzf-history-widget

      # Ctrl+Space — accept autosuggestion
      bind ctrl-space forward-char

      # Ctrl+Alt+P — kill process (fzf)
      bind ctrl-alt-p 'killp'

      # Ctrl+Alt+G — git log interactive
      bind ctrl-alt-g 'glog'

      # Ctrl+Alt+B — git branch checkout
      bind ctrl-alt-b 'gco_branch'
    '';

    plugins = [
      # Notification when long-running command finishes
      {name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src;}
      {name = "done"; src = pkgs.fishPlugins.done.src;}

      # fzf integration (Ctrl+T, Alt+C, Ctrl+R)
      {name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src;}

      # Auto-close brackets
      {name = "autopair"; src = pkgs.fishPlugins.autopair.src;}

      # git interactive with fzf: log, diff, add, reset, stash
      {name = "forgit"; src = pkgs.fishPlugins.forgit.src;}
    ];

    shellAliases = {
      # ── Eza (modern ls) ──
      ls = "eza --icons --group-directories-first --git";
      ll = "eza -l --icons --group-directories-first --git --header";
      la = "eza -la --icons --group-directories-first --git --header";
      lt = "eza --tree --level=2 --icons --git";
      tree = "eza --tree --icons --git";

      # ── Utilities ──
      cat = "bat --style=plain";
      grep = "rg";
      find = "fd";
      top = "btop";
      cdi = "zi";

      # ── NixOS / Home Manager ──
      ns = "nix shell";
      nd = "nix develop";
      nfu = "nix flake update";
      nfc = "nix flake check";
      nrf = "sudo nixos-rebuild switch --flake ${flakePath}#${hostname}";
      nrs = "nh os switch";
      nrt = "nh os test";
      nrb = "nh os build";
      hms = "nh home switch";
      hmb = "nh home build";

      # ── Git shortcuts ──
      gst = "git status --short --branch";
      gaa = "git add --all";
      gl = "git log --oneline --graph --decorate";
      gd = "git diff";
      gds = "git diff --staged";
      gclean = "git clean -fd";
      gsta = "git stash";
      gstp = "git stash pop";
    };

    shellAbbrs = {
      # ── Git ──
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gco = "git checkout";
      gcb = "git checkout -b";
      gp = "git push";
      gpl = "git pull --rebase";

      # ── Editors ──
      n = "nvim";
      y = "yazi";

      # ── NixOS ──
      sw = "nh os switch";
      tst = "nh os test";
      bld = "nh os build";
    };

    functions = {
      # ── mkcd: Create directory and enter it ──
      mkcd = {
        description = "Create directory and cd into it";
        body = ''
          mkdir -p $argv[1] && cd $argv[1]
        '';
      };

      # ── extract: Extract any archive format ──
      extract = {
        description = "Extract any archive format";
        body = ''
          if test (count $argv) -eq 0
            echo "Usage: extract <file>"
            return 1
          end
          for file in $argv
            switch $file
              case "*.tar.bz2"
                tar xjf $file
              case "*.tar.gz"
                tar xzf $file
              case "*.tar.xz"
                tar xJf $file
              case "*.tar.zst"
                tar --zstd -xf $file
              case "*.bz2"
                bunzip2 $file
              case "*.rar"
                unrar x $file
              case "*.gz"
                gunzip $file
              case "*.tar"
                tar xf $file
              case "*.tbz2"
                tar xjf $file
              case "*.tgz"
                tar xzf $file
              case "*.zip"
                unzip $file
              case "*.Z"
                uncompress $file
              case "*.7z"
                7z x $file
              case "*.zst"
                unzstd $file
              case "*"
                echo "extract: unknown format: $file"
            end
          end
        '';
      };

      # ── backup: Quick file backup with timestamp ──
      backup = {
        description = "Backup file with timestamp";
        body = ''
          if test (count $argv) -eq 0
            echo "Usage: backup <file>"
            return 1
          end
          for file in $argv
            if test -e $file
              cp -r $file "$file.bak."(date +%Y%m%d%H%M%S)
              echo "Backed up: $file"
            else
              echo "backup: $file not found"
            end
          end
        '';
      };

      # ── killp: Kill process with fzf ──
      killp = {
        description = "Kill process selected with fzf";
        body = ''
          set -l pid (ps aux | fzf --height=40% --layout=reverse --header="Select process to kill" | awk "{print \$2}")
          if test -n "$pid"
            echo "Kill PID $pid? (y/N)"
            read -n 1 confirm
            if test "$confirm" = "y"
              kill -9 $pid
              echo "Killed $pid"
            end
          end
        '';
      };

      # ── glog: Interactive git log with fzf ──
      glog = {
        description = "Interactive git log with fzf";
        body = ''
          set -l commit (git log --oneline --graph --decorate --color=always | fzf --height=60% --layout=reverse --no-sort --ansi --header="Select commit" | awk "{print \$2}")
          if test -n "$commit"
            git show $commit
          end
        '';
      };

      # ── gco_branch: Interactive git branch checkout ──
      gco_branch = {
        description = "Interactive git branch checkout";
        body = ''
          set -l branch (git branch --all --color=always --format=%(refname:short) | fzf --height=40% --layout=reverse --ansi --header="Select branch")
          if test -n "$branch"
            git checkout $branch
          end
        '';
      };
    };
  };

  # ──────────────────────────────────────────────
  # STARSHIP PROMPT
  # ──────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 500;
      scan_timeout = 10;

      format = "$directory$git_branch$git_status$nix_shell$fill$cmd_duration$line_break$character";
      right_format = "$time$battery";

      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        style = "bold #89b4fa";
        format = "[$path]($style) ";
      };

      git_branch = {
        symbol = " ";
        style = "bold #fab387";
      };

      git_status = {
        style = "bold #f38ba8";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "=";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        up_to_date = "";
        untracked = "?";
        stashed = "$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      nix_shell = {
        symbol = "❄️ ";
        style = "bold #89b4fa";
        format = "[$symbol$state]($style) ";
      };

      cmd_duration = {
        min_time = 1500;
        format = "[$duration](bold #f9e2af) ";
      };

      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "bold #6c7086";
        time_format = "%R";
      };

      battery = {
        full_symbol = " ";
        charging_symbol = " ";
        discharging_symbol = " ";
        unknown_symbol = " ";
        empty_symbol = " ";
        display = [
          { threshold = 100; style = "bold #a6e3a1"; }
          { threshold = 60; style = "bold #f9e2af"; }
          { threshold = 30; style = "bold #fab387"; }
          { threshold = 15; style = "bold #f38ba8"; }
        ];
      };

      nodejs = {
        symbol = " ";
        style = "bold #a6e3a1";
        format = "via [$symbol($version)]($style) ";
      };

      python = {
        symbol = " ";
        style = "bold #f9e2af";
        format = "via [$symbol($version)(\\($virtualenv\\))]($style) ";
      };

      rust = {
        symbol = " ";
        style = "bold #fab387";
        format = "via [$symbol($version)]($style) ";
      };

      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
      };

      fill = { symbol = " "; };
    };
  };

  # ──────────────────────────────────────────────
  # ZOXIDE: SMART CD
  # ──────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd" "z"];
  };

  # ──────────────────────────────────────────────
  # DIRENV: PROJECT ENVIRONMENT LOADING
  # ──────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    silent = true;
  };

  # ──────────────────────────────────────────────
  # FZF: FUZZY FINDER
  # Ctrl+T = files, Alt+C = dirs, Ctrl+R = history
  # ──────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

    fileWidget = {
      command = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
        "--multi"
      ];
    };

    changeDirWidget = {
      command = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
      options = [
        "--preview 'eza --tree --level=2 --icons --color=always {} | head -50'"
      ];
    };

    # Ctrl+R = history search via fzf (no atuin)
    historyWidget.options = [
      "--preview 'echo {}'"
      "--preview-window down:3:wrap"
    ];

    defaultOptions = [
      "--height 55%"
      "--layout=reverse"
      "--border rounded"
      "--preview-window=right:65%:wrap"
      "--multi"
      # Catppuccin Mocha
      "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8"
      "--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8"
      "--color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,spinner:#f5e0dc,header:#f38ba8"
    ];
  };

  # ──────────────────────────────────────────────
  # CARAPACE: EXTRA COMPLETIONS
  # ──────────────────────────────────────────────
  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };
}
