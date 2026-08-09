{lib, ...}: {
  # ============================================================
  # STARSHIP PROMPT — High-Performance, Minimal & Informative
  # ============================================================
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false; # no blank line — keeps scrollback dense
      command_timeout = 1000; # 500 was too tight for cold git status on big repos
      scan_timeout = 30;

      # The environment modules are wrapped in a bracketed group so they
      # read as one block rather than a flat run of symbols.
      format = lib.concatStrings [
        "$directory"
        "$git_branch$git_state$git_status"
        "([\\(](#585b70)"
        "\${custom.proxy}"
        "\${custom.box}"
        "$nix_shell$direnv"
        "$python$nodejs$rust$golang$java$lua$package"
        "$container$docker_context"
        "[\\)](#585b70) )"
        "$fill"
        "$jobs$cmd_duration"
        "$line_break"
        "$character"
      ];

      right_format = "$status$time$battery";

      # ── Location ──────────────────────────────────────────────────────
      directory = {
        style = "bold #89b4fa";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " ";
        read_only_style = "bold #f38ba8";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        substitutions = {
          "~/projects" = "󰲋 ";
          "~/Documents" = "󰈙 ";
          "~/Downloads" = "󰇚 ";
        };
      };

      # ── Dynamic Environment Indicators (Proxy, Box Sandbox) ───────────
      custom = {
        proxy = {
          command = "echo \"$ALL_PROXY\" | sed -E 's/.*:([0-9]+)/󰖩 \\1/'";
          when = "test -n \"$ALL_PROXY\"";
          style = "bold #a6e3a1";
          format = "[$output]($style) ";
        };

        box = {
          command = "echo \"📦 box\"";
          when = "test -n \"$BOX_ACTIVE\"";
          style = "bold #f9e2af";
          format = "[$output]($style) ";
        };
      };

      # ── Git ───────────────────────────────────────────────────────────
      git_branch = {
        symbol = " ";
        style = "bold #cba6f7";
        format = "[$symbol$branch]($style) ";
        truncation_length = 20;
        truncation_symbol = "…";
      };

      git_state = {
        format = "[\($state( $progress_current/$progress_total)\)]($style) ";
        style = "bold #f9e2af";
      };

      git_status = {
        style = "bold #f38ba8";
        format = "([$all_status$ahead_behind]($style)) ";
        conflicted = "=$count";
        ahead = "⇡$count";
        behind = "⇣$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        untracked = "?$count";
        stashed = "*$count";
        modified = "!$count";
        staged = "+$count";
        renamed = "»$count";
        deleted = "✘$count";
      };

      # ── DevShell Indicator (Only renders inside actual devShells) ──────
      nix_shell = {
        symbol = "❄️ ";
        style = "bold #89b4fa";
        format = "[$symbol$name]($style) ";
        heuristic = false;
      };

      direnv = {
        disabled = false;
        symbol = "󰌪 ";
        format = "[$symbol$loaded/$allowed]($style) ";
        style = "bold #a6e3a1";
        loaded_msg = "";
        unloaded_msg = "off";
        allowed_msg = "";
        not_allowed_msg = "denied";
      };

      # ── Languages ─────────────────────────────────────────────────────
      python = {
        symbol = " ";
        style = "#f9e2af";
        format = "[\${symbol}(\($virtualenv\) )]($style)[$version](dimmed #f9e2af) ";
        detect_extensions = ["py" "ipynb"];
        detect_files = [
          "requirements.txt"
          "pyproject.toml"
          "setup.py"
          "uv.lock"
          "poetry.lock"
          "Pipfile"
          "tox.ini"
          ".python-version"
        ];
        detect_folders = [".venv" "venv"];
        python_binary = ["python3" "python"];
      };

      nodejs = {
        symbol = " ";
        style = "#a6e3a1";
        format = "[$symbol]($style)[$version](dimmed #a6e3a1) ";
        detect_files = ["package.json" ".nvmrc" "bun.lockb" "pnpm-lock.yaml"];
        detect_folders = ["node_modules"];
      };

      rust = {
        symbol = "󱘗 ";
        style = "#fab387";
        format = "[$symbol$version]($style) ";
      };

      golang = {
        symbol = " ";
        style = "#94e2d5";
        format = "[$symbol$version]($style) ";
      };

      java = {
        symbol = " ";
        style = "#eba0ac";
        format = "[$symbol$version]($style) ";
      };

      lua = {
        symbol = " ";
        style = "#89b4fa";
        format = "[$symbol$version]($style) ";
      };

      package = {
        symbol = "󰏗 ";
        style = "#cba6f7";
        format = "[$symbol$version]($style) ";
        display_private = false;
      };

      # ── Containers ────────────────────────────────────────────────────
      container = {
        symbol = "󰡨 ";
        style = "bold #f9e2af";
        format = "[$symbol\[$name\]]($style) ";
      };

      docker_context = {
        symbol = " ";
        style = "#89b4fa";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      # ── Right side ────────────────────────────────────────────────────
      fill.symbol = " ";

      jobs = {
        symbol = "󰜎 ";
        style = "bold #cba6f7";
        format = "[$symbol$number]($style) ";
        number_threshold = 1;
        symbol_threshold = 1;
      };

      cmd_duration = {
        min_time = 1500;
        style = "bold #f9e2af";
        format = "[󱑈 $duration]($style) ";
        show_milliseconds = false;
      };

      status = {
        disabled = false;
        style = "bold #f38ba8";
        symbol = "✘";
        not_found_symbol = "󰍉";
        not_executable_symbol = "󰌾";
        sigint_symbol = "󰂭";
        signal_symbol = "󱐋";
        format = "[$symbol$common_meaning$signal_name$maybe_int]($style) ";
        map_symbol = true;
        pipestatus = true;
      };

      time = {
        disabled = false;
        style = "#6c7086";
        format = "[$time]($style) ";
        time_format = "%R";
      };

      battery = {
        format = "[$symbol$percentage]($style) ";
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰂃 ";
        unknown_symbol = "󰂑 ";
        empty_symbol = "󰂎 ";
        display = [
          {
            threshold = 15;
            style = "bold #f38ba8";
          }
          {
            threshold = 30;
            style = "bold #fab387";
          }
        ];
      };

      # ── Prompt character ──────────────────────────────────────────────
      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
        vimcmd_symbol = "[❮](bold #cba6f7)";
      };

      # ── Off ───────────────────────────────────────────────────────────
      hostname.ssh_only = true;
      username.show_always = false;
      shell.disabled = true;
      memory_usage.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
    };
  };
}
