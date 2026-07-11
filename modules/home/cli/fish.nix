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
      # ── STARSHIP INIT (manual — enableFishIntegration ممکنه کار نکنه) ──
      starship init fish | source

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
    '';

    plugins = [
      # نوتیفیکیشن وقتی دستور طولانی تموم میشه
      {name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src;}
      {name = "done"; src = pkgs.fishPlugins.done.src;}

      # fzf integration
      {name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src;}

      # بستن خودکار براکت‌ها: (), [], {}, "", ''
      {name = "autopair"; src = pkgs.fishPlugins.autopair.src;}

      # git interactive با fzf: log, diff, add, reset, stash
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
      cdi = "zi"; # cd هوشمند zoxide

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
  };

  # ──────────────────────────────────────────────
  # STARSHIP PROMPT — Enhanced
  # ──────────────────────────────────────────────
  programs.starship = {
    enable = true;
    # enableFishIntegration — دستی بالا فراخوانی شد
    settings = {
      add_newline = false;
      command_timeout = 500;
      scan_timeout = 10;

      # ── FORMAT ──
      format = "$directory$git_branch$git_status$nix_shell$fill$cmd_duration$line_break$character";
      right_format = "$time$battery";

      # ── DIRECTORY ──
      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        style = "bold #89b4fa";
        format = "[$path]($style) ";
      };

      # ── GIT BRANCH ──
      git_branch = {
        symbol = " ";
        style = "bold #fab387";
      };

      # ── GIT STATUS (symbols) ──
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

      # ── NIX SHELL ──
      nix_shell = {
        symbol = "❄️ ";
        style = "bold #89b4fa";
        format = "[$symbol$state]($style) ";
      };

      # ── CMD DURATION ──
      cmd_duration = {
        min_time = 1500;
        format = "[$duration](bold #f9e2af) ";
      };

      # ── TIME (right) ──
      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "bold #6c7086";
        time_format = "%R";
      };

      # ── BATTERY (right) ──
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

      # ── LANGUAGE VERSIONS (auto-detect) ──
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

      # ── CHARACTER ──
      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
      };

      # ── FILL ──
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
  # FZF: FUZZY FINDER (Enhanced)
  # ──────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

    # Ctrl+T: فایل‌ها
    fileWidget = {
      command = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
      ];
    };

    # Alt+C: پوشه‌ها
    changeDirWidget = {
      command = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";
      options = [
        "--preview 'eza --tree --level=2 --icons --color=always {} | head -50'"
      ];
    };

    # Ctrl+R → atuin (historyWidget خالی)
    historyWidget.command = "";

    defaultOptions = [
      "--height 55%"
      "--layout=reverse"
      "--border rounded"
      "--preview-window=right:65%:wrap"
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

  # ──────────────────────────────────────────────
  # ATUIN: SMART SHELL HISTORY
  # ──────────────────────────────────────────────
  # Ctrl+R = جستجوی تاریخچه
  # Up arrow = دستورات اخیر (chronological)
  # تاریخچه در ~/.local/share/atuin/history.db — مستقل از پکیج‌ها
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      style = "compact";
      inline_height = 25;
      show_preview = true;
      enter_accept = false;
      store_failed = true;
    };
  };
}
