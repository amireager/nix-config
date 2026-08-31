{
  pkgs,
  hostname,
  flakePath,
  proxy,
  ...
}: let
  nixProxyScript =
    builtins.replaceStrings
    ["@PROXY_HOST@" "@PROXY_PORT@"]
    [proxy.host (toString proxy.port)]
    (builtins.readFile ./nix-proxy.sh);
  nixProxy = pkgs.writeShellApplication {
    name = "nix-proxy";
    runtimeInputs = with pkgs; [bash coreutils curl gnugrep gnused systemd];
    text = nixProxyScript;
  };
in {
  home.packages = [nixProxy];

  # ============================================================
  # FISH SHELL — Aliases, Abbrs, Keybindings & Custom Functions
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
      # FZF Integration & Preview
      # ──────────────────────────────────────────────
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      set -gx FZF_PREVIEW_COMMAND 'bat --style=numbers --color=always --line-range :500 {}'
      set -gx FZF_DEFAULT_OPTS '--height 55% --layout=reverse --border rounded --multi --color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8 --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 --color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc'

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
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
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

      # Rebuild trio — one tool (nh), explicit flake + hostname.
      # nh without --hostname auto-detects from /etc/hostname, which lags
      # behind a hostname rename until the first rebuild — explicit flags
      # remove that whole class of "does not provide attribute" failures.
      nrs = "nh os switch ${flakePath} --hostname ${hostname}";
      nrt = "nh os test ${flakePath} --hostname ${hostname}";
      nrb = "nh os build ${flakePath} --hostname ${hostname}";

      # === Proxy Management ===
      myip = "curl ip.me";
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
          set -l port ${toString proxy.port}
          if test (count $argv) -gt 0
            set port $argv[1]
          else if set -q PROXY_PORT; and string match -qr '^[0-9]{1,5}$' -- $PROXY_PORT
            set port $PROXY_PORT
          end
          if not string match -qr '^[0-9]{1,5}$' -- $port; or test $port -lt 1; or test $port -gt 65535
            echo "proxy_on: invalid port: $port" >&2
            return 2
          end

          set -l url "socks5h://${proxy.host}:$port"
          set -l bypass "127.0.0.1,localhost,::1"
          set -gx ALL_PROXY $url
          set -gx HTTP_PROXY $url
          set -gx HTTPS_PROXY $url
          set -gx FTP_PROXY $url
          set -gx all_proxy $url
          set -gx http_proxy $url
          set -gx https_proxy $url
          set -gx ftp_proxy $url
          set -gx NO_PROXY $bypass
          set -gx no_proxy $bypass
          echo -e "\033[1;32m[+] Proxy Enabled in this terminal (${proxy.host}:$port)\033[0m"
        '';
      };

      # === Proxy for nix builds ===
      nix_proxy = {
        description = "Manage the transient nix-daemon proxy safely";
        body = "command nix-proxy $argv";
      };

      proxy_off = {
        description = "Disable proxy for the current shell session";
        body = ''
          for name in ALL_PROXY HTTP_PROXY HTTPS_PROXY FTP_PROXY all_proxy http_proxy https_proxy ftp_proxy NO_PROXY no_proxy
            set -e $name
          end
          echo -e "\033[1;31m[-] Proxy Disabled\033[0m"
        '';
      };

      # === Dynamic Proxychains Wrapper ===
      px = {
        description = "Run one command through proxychains (PROXY_PORT overrides the default)";
        body = ''
          if test (count $argv) -eq 0
            echo "usage: px <command> [args...]" >&2
            return 2
          end

          if not set -q PROXY_PORT
            command proxychains4 -q $argv
            return $status
          end

          if not string match -qr '^[0-9]{1,5}$' -- $PROXY_PORT; or test $PROXY_PORT -lt 1; or test $PROXY_PORT -gt 65535
            echo "px: invalid PROXY_PORT: $PROXY_PORT" >&2
            return 2
          end

          if not grep -Eq '^[[:space:]]*socks5[[:space:]]+[^[:space:]]+[[:space:]]+[0-9]+' /etc/proxychains.conf
            echo "px: configured SOCKS5 entry not found in /etc/proxychains.conf" >&2
            return 1
          end

          set -l tmp_dir /tmp
          set -q TMPDIR; and set tmp_dir $TMPDIR
          set -l tmp_conf (mktemp -p "$tmp_dir" proxychains.XXXXXX.conf)
          or return 1
          chmod 600 $tmp_conf

          if not sed -E "s|^([[:space:]]*socks5[[:space:]]+)[^[:space:]]+([[:space:]]+)[0-9]+|\1${proxy.host}\2$PROXY_PORT|" \
            /etc/proxychains.conf > $tmp_conf
            rm -f -- $tmp_conf
            return 1
          end

          command proxychains4 -q -f $tmp_conf $argv
          set -l command_status $status
          rm -f -- $tmp_conf
          return $command_status
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
}
