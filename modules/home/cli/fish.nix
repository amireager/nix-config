{
  pkgs,
  lib,
  hostname,
  flakePath,
  ...
}: {
  # ============================================================
  # FISH SHELL
  # ============================================================
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # ──────────────────────────────────────────────
      # General Settings
      # ──────────────────────────────────────────────
      set -g fish_greeting
      set -g fish_autosuggestion_enabled true
      set -g fish_key_bindings fish_default_key_bindings

      # ──────────────────────────────────────────────
      # Environment Variables
      # ──────────────────────────────────────────────
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PAGER "bat --plain"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      # ──────────────────────────────────────────────
      # FZF Preview Command
      # ──────────────────────────────────────────────
      set -gx FZF_PREVIEW_COMMAND 'bat --style=numbers --color=always --line-range :500 {}'

      # ──────────────────────────────────────────────
      # Catppuccin Mocha Theme Colors
      # ──────────────────────────────────────────────
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

      # Pager Colors
      set -g fish_pager_color_progress cyan
      set -g fish_pager_color_background --background=1e1e2e
      set -g fish_pager_color_prefix f9e2af --bold
      set -g fish_pager_color_completion cdd6f4
      set -g fish_pager_color_description a6e3a1
      set -g fish_pager_color_selected_background --background=313244
      set -g fish_pager_color_selected_prefix f9e2af --bold
      set -g fish_pager_color_selected_completion cdd6f4 --bold
      set -g fish_pager_color_selected_description 89b4fa

      # ──────────────────────────────────────────────
      # Custom Key Bindings
      # ──────────────────────────────────────────────
      # Ctrl+Space — accept autosuggestion
      bind ctrl-space forward-char
    '';

    plugins = [
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
    ];

    shellAliases = {
      ls = "eza --icons --group-directories-first --git";
      ll = "eza -l --icons --group-directories-first --git --header";
      la = "eza -la --icons --group-directories-first --git --header";
      lt = "eza --tree --level=2 --icons --git";
      tree = "eza --tree --icons --git";
      cat = "bat --style=plain";
      top = "btop";
    };

    shellAbbrs = {
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gco = "git checkout";
      gcb = "git checkout -b";
      gp = "git push";
      gpl = "git pull --rebase";
      gsw = "git switch";

      n = "nvim";

      sw = "nh os switch";
      tst = "nh os test";
      bld = "nh os build";
      nrf = "sudo nixos-rebuild switch --flake ${flakePath}#${hostname}";
      nrs = "nh os switch";
      nrt = "nh os test";
      nrb = "nh os build";

      # No hms/hmb here on purpose. Home Manager is wired as a NixOS module
      # (see lib/mkHost.nix), so the flake exposes no `homeConfigurations`
      # output and `nh home switch` fails with:
      #   error: flake ... does not provide attribute
      #   'packages.x86_64-linux.homeConfigurations' ...
      # `sw` / `nrs` rebuild the home directory along with the system.

      # === Proxy Management ===
      myip = "curl ip.me";

      # === Sandbox (Firejail) ===
      fj  = "firejail --private=. --whitelist=$(pwd)";
      fjx = "firejail --private=. --net=none --whitelist=$(pwd)";
    };

    functions = {
      # === A typo is a typo ===
      # Defining this by name is the only reliable way to stop it.
      #
      # Disabling the two Nix-side integrations was not enough, and the
      # reason is in fish's own fish_command_not_found.fish: it is a chain
      # of `else if` probes run at startup, and NixOS is one of several
      # branches it can land on:
      #
      #     else if test -f /run/current-system/sw/bin/command-not-found
      #     else if type -q command-not-found        # <- anything on PATH
      #     else if type -q pkgfile
      #
      # So every switch only removes one branch and lets fish fall to the
      # next. Any `command-not-found` binary reachable on PATH — from a
      # devShell, a stray profile, a leftover generation — puts the pause
      # straight back. That file's own first line says the supported way
      # out is to define the function, which short-circuits the whole
      # chain before a single probe runs.
      #
      # The message is fish's own wording, not the "$cmd: command not
      # found" printed by nix-index's handler. That difference is how you
      # tell which one answered.
      #
      # Deliberate lookups are untouched:
      #     nix-locate --minimal --whole-name bin/rg
      #     , rg
      fish_command_not_found = {
        description = "Report a typo and stop — no package database search";
        body = ''
          printf "fish: Unknown command: %s\n" (string escape -- $argv[1]) >&2
          return 127
        '';
      };

      mkcd = "mkdir -p $argv[1] && cd $argv[1]";

      # === On-Demand Dynamic Proxy (Per Terminal Tab) ===
      proxy_on = {
        description = "Enable proxy for the current shell session";
        body = ''
          set -l port 1819
          if test (count $argv) -gt 0
            set port $argv[1]
          end
          set -gx ALL_PROXY "socks5h://127.0.0.1:$port"
          set -gx HTTP_PROXY "socks5h://127.0.0.1:$port"
          set -gx HTTPS_PROXY "socks5h://127.0.0.1:$port"
          echo -e "\033[1;32m[+] Proxy Enabled in this terminal (127.0.0.1:$port)\033[0m"
        '';
      };

      # === Proxy for nix builds ===
      # Separate from proxy_on because it solves a different problem.
      # proxy_on sets variables in this shell; `nix build` does not download
      # anything in this shell. It asks nix-daemon, a system service that
      # cannot see the shell environment, so the proxy has to go on the
      # daemon's unit.
      #
      # This is not in the NixOS configuration on purpose. Any port written
      # there is stale the moment the proxy moves, and changing it would need
      # a rebuild — which itself needs the proxy. Passing the port as an
      # argument keeps it current.
      #
      # Safe for source fetches: every download in Nix is a fixed-output
      # derivation whose hash is in the package definition, so tampered
      # content fails the build rather than being trusted.
      nix_proxy = {
        description = "Route nix-daemon downloads through a local proxy (until reboot)";
        body = ''
          set -l dir /run/systemd/system/nix-daemon.service.d
          set -l conf $dir/zz-nix-proxy.conf

          switch "$argv[1]"
            case off
              sudo rm -f $conf
              sudo rmdir --ignore-fail-on-non-empty $dir 2>/dev/null
              sudo systemctl daemon-reload
              sudo systemctl restart nix-daemon
              echo -e "\033[1;31m[-] nix-daemon: direct\033[0m"

            case status ""
              if test -f $conf
                echo -e "\033[1;32m[+] nix-daemon: proxied\033[0m"
                grep -o 'all_proxy=[^"]*' $conf | sed 's/^/    /'
              else
                echo -e "\033[1;30m[-] nix-daemon: direct\033[0m"
              end
              echo "    usage: nix_proxy <port> | nix_proxy off | nix_proxy status"

            case '*'
              set -l port $argv[1]
              if not string match -qr '^[0-9]+$' -- $port
                echo -e "\033[1;31mnix_proxy: '$port' is not a port number\033[0m" >&2
                echo "    usage: nix_proxy <port> | nix_proxy off | nix_proxy status" >&2
                return 1
              end
              set -l url "socks5h://127.0.0.1:$port"

              # /run rather than /etc: a forgotten proxy cannot survive a
              # reboot. cache.nixos.org bypasses it — the binary cache is not
              # blocked and is CDN-served, so proxying it only adds latency.
              sudo mkdir -p $dir
              printf '%s\n' \
                "[Service]" \
                "Environment=\"http_proxy=$url\"" \
                "Environment=\"https_proxy=$url\"" \
                "Environment=\"all_proxy=$url\"" \
                "Environment=\"no_proxy=127.0.0.1,localhost,::1,cache.nixos.org\"" \
                | sudo tee $conf >/dev/null

              sudo systemctl daemon-reload
              sudo systemctl restart nix-daemon
              echo -e "\033[1;32m[+] nix-daemon proxied via $url\033[0m"
              echo -e "\033[1;30m    until reboot, or: nix_proxy off\033[0m"
          end
        '';
      };

      proxy_off = {
        description = "Disable proxy for the current shell session";
        body = ''
          set -e ALL_PROXY HTTP_PROXY HTTPS_PROXY
          echo -e "\033[1;31m[-] Proxy Disabled\033[0m"
        '';
      };

      # === Dynamic Proxychains Wrapper ===
      px = {
        description = "Run a command with proxychains, ignoring hardcoded port if PROXY_PORT is set";
        body = ''
          if set -q PROXY_PORT
            # Temporarily rewrite proxychains config in tmp using the dynamic port
            set tmp_conf "/tmp/proxychains_dynamic.conf"
            cat /etc/proxychains.conf | sed -E "s/socks5 \+127.0.0.1 \+[0-9]+/socks5  127.0.0.1  $PROXY_PORT/" > $tmp_conf
            proxychains4 -f $tmp_conf $argv
          else
            proxychains4 -q $argv
          end
        '';
      };

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
    };
  };

  # ============================================================
  # STARSHIP PROMPT
  # ============================================================
  # Layout:
  #   ~/p/nix-config  main !2  ❄️ dev:python  .venv  py 3.13    1.2s
  #   ❯
  #
  # Left  — where am I, and what context am I in
  # Right — how long did that take, what time is it, battery
  #
  # Language modules only appear inside a matching project, so the prompt
  # stays short in an ordinary directory.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false; # no blank line — keeps scrollback dense
      command_timeout = 1000; # 500 was too tight for cold git status on big repos
      scan_timeout = 30;

      # The environment modules are wrapped in a bracketed group so they
      # read as one block rather than a flat run of symbols. The group
      # collapses entirely when nothing matches, so an ordinary directory
      # still gets a short prompt.
      format = lib.concatStrings [
        "$directory"
        "$git_branch$git_state$git_status"
        "([\\(](#585b70)"
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

      # ── Git ───────────────────────────────────────────────────────────
      git_branch = {
        symbol = " ";
        style = "bold #fab387";
        format = "[$symbol$branch]($style) ";
        truncation_length = 24;
        truncation_symbol = "…";
      };

      # Shows what git is in the middle of: rebase, merge, cherry-pick.
      # Easy to lose track of an interrupted rebase without this.
      git_state = {
        style = "bold #f5c2e7";
        format = "([$state( $progress_current/$progress_total)]($style)) ";
        rebase = "REBASE";
        merge = "MERGE";
        revert = "REVERT";
        cherry_pick = "PICK";
        bisect = "BISECT";
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

      # ── Nix ───────────────────────────────────────────────────────────
      # heuristic catches `nix shell` and `nix develop`, not just nix-shell.
      # $state (pure/impure) is left out of the format: every shell here is
      # entered through `dev`, so the answer is always the same and the word
      # only costs width. The shell name is the useful part.
      nix_shell = {
        symbol = "❄️ ";
        style = "bold #89b4fa";
        format = "[$symbol( $name)]($style) ";
        heuristic = true;
      };

      direnv = {
        disabled = false;
        symbol = "󰚩 ";
        style = "#a6adc8";
        format = "[$symbol$loaded/$allowed]($style) ";
        allowed_msg = "";
        not_allowed_msg = "!";
        denied_msg = "✘";
        loaded_msg = "";
        unloaded_msg = "○";
      };

      # ── Languages ─────────────────────────────────────────────────────
      # The venv name matters far more than the interpreter version, so it
      # is shown first and the version is dimmed.
      python = {
        symbol = " ";
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
        symbol = " ";
        style = "#a6e3a1";
        format = "[$symbol]($style)[$version](dimmed #a6e3a1) ";
        detect_files = ["package.json" ".nvmrc" "bun.lockb" "pnpm-lock.yaml"];
        detect_folders = ["node_modules"];
      };

      rust = {
        symbol = " ";
        style = "#fab387";
        format = "[$symbol]($style)[$version](dimmed #fab387) ";
      };

      golang = {
        symbol = " ";
        style = "#94e2d5";
        format = "[$symbol]($style)[$version](dimmed #94e2d5) ";
      };

      java = {
        symbol = " ";
        style = "#eba0ac";
        format = "[$symbol]($style)[$version](dimmed #eba0ac) ";
      };

      lua = {
        symbol = " ";
        style = "#89b4fa";
        format = "[$symbol]($style)[$version](dimmed #89b4fa) ";
      };

      # Project version from package.json/Cargo.toml — useful before a release.
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
        symbol = " ";
        style = "#89b4fa";
        format = "[$symbol$context]($style) ";
        only_with_files = true;
      };

      # ── Right side ────────────────────────────────────────────────────
      fill.symbol = " ";

      # Background jobs are easy to forget about.
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

      # Only renders on failure, so successful commands stay quiet.
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
      # Hostname and username belong on servers, not on a laptop where the
      # answer never changes.
      hostname.ssh_only = true;
      username.show_always = false;
      shell.disabled = true;
      memory_usage.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
    };
  };

  # Additional Tools
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd" "z"];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    silent = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 55%"
      "--layout=reverse"
      "--border rounded"
      "--multi"
      "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8"
      "--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8"
      "--color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc"
    ];
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };
}
