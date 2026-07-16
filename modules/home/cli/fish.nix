{
  pkgs,
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
      hms = "nh home switch";
      hmb = "nh home build";
    };

    functions = {
      mkcd = "mkdir -p $argv[1] && cd $argv[1]";
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

  # Starship Prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 500;
      format = "$directory$git_branch$git_status$nix_shell$fill$cmd_duration$line_break$character";
      right_format = "$time$battery";

      directory.style = "bold #89b4fa";
      git_branch.style = "bold #fab387";
      git_status.style = "bold #f38ba8";

      nix_shell.symbol = "❄️ ";
      nix_shell.style = "bold #89b4fa";

      cmd_duration.min_time = 1500;
      cmd_duration.format = "[$duration](bold #f9e2af) ";

      time.disabled = false;
      time.format = "[$time]($style) ";
      time.style = "bold #6c7086";
      time.time_format = "%R";

      character.success_symbol = "[❯](bold #a6e3a1)";
      character.error_symbol = "[❯](bold #f38ba8)";
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
