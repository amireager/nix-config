{
  pkgs,
  lib,
  hostname,
  flakePath,
  ...
}: {
  # ============================================================
  # FISH SHELL & STARSHIP PROMPT
  # ============================================================
  programs = {
    fish = {
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

        # === Proxy Management ===
        myip = "curl ip.me";

        # === Sandbox (Firejail) ===
        fj = "firejail --private=. --whitelist=$(pwd)";
        fjx = "firejail --private=. --net=none --whitelist=$(pwd)";
      };

      functions = {
        # === A typo is a typo ===
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
            echo -e "\033[1;31m[-] Proxy Disabled in this terminal\033[0m"
          '';
        };
      };
    };

    # ============================================================
    # STARSHIP PROMPT
    # ============================================================
    starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        add_newline = false;
        command_timeout = 1000;
        scan_timeout = 30;

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
          format = "([$all_status$ahead_behind]($style) )";
          style = "bold #fab387";
          conflicted = "=";
          ahead = "⇡\${count}";
          behind = "⇣\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          untracked = "?";
          stashed = "\\$";
          modified = "!";
          staged = "+";
          renamed = "»";
          deleted = "✘";
        };

        nix_shell = {
          symbol = "󱄅 ";
          format = "[$symbol$state]($style) ";
          style = "bold #74c7ec";
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

        python = {
          symbol = " ";
          format = "[$symbol$version(\\($virtualenv\\))]($style) ";
          style = "bold #f9e2af";
        };

        rust = {
          symbol = "󱘗 ";
          format = "[$symbol$version]($style) ";
          style = "bold #f38ba8";
        };

        golang = {
          symbol = " ";
          format = "[$symbol$version]($style) ";
          style = "bold #89dceb";
        };

        nodejs = {
          symbol = " ";
          format = "[$symbol$version]($style) ";
          style = "bold #a6e3a1";
        };

        container = {
          symbol = "󰏖 ";
          format = "[$symbol$name]($style) ";
          style = "dimmed white";
        };

        fill = {
          symbol = " ";
        };

        cmd_duration = {
          min_time = 2000;
          format = "[$duration]($style) ";
          style = "bold #fab387";
          show_milliseconds = false;
        };

        time = {
          disabled = false;
          format = "[$time]($style)";
          style = "dimmed #6c7086";
          time_format = "%R";
        };

        battery = {
          full_symbol = "󰁹 ";
          charging_symbol = "󰂄 ";
          discharging_symbol = "󰂃 ";
          unknown_symbol = "󰁽 ";
          empty_symbol = "󰂎 ";
          format = " [$symbol$percentage]($style)";
          display = [
            {
              threshold = 20;
              style = "bold #f38ba8";
            }
            {
              threshold = 50;
              style = "bold #f9e2af";
            }
          ];
        };

        character = {
          success_symbol = "[❯](bold #a6e3a1)";
          error_symbol = "[❯](bold #f38ba8)";
          vimcmd_symbol = "[❮](bold #89b4fa)";
        };
      };
    };
  };
}
