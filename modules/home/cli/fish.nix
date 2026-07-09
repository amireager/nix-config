{
  pkgs,
  hostname,
  flakePath,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
      set -g fish_autosuggestion_enabled 1
      set -g fish_key_bindings fish_default_key_bindings
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PAGER "bat --plain"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      # Catppuccin Mocha colors
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
    '';
    plugins = [
      {name = "colored-man-pages"; src = pkgs.fishPlugins.colored-man-pages.src;}
      {name = "done"; src = pkgs.fishPlugins.done.src;}
      {name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src;}
    ];
    shellAliases = {
      ls = "eza --icons --group-directories-first --git";
      ll = "eza -l --icons --group-directories-first --git --header";
      la = "eza -la --icons --group-directories-first --git --header";
      lt = "eza --tree --level=2 --icons --git";
      tree = "eza --tree --icons --git";
      cat = "bat --style=plain";
      grep = "rg";
      find = "fd";
      top = "btop";
      ns = "nix shell";
      nd = "nix develop";
      nfu = "nix flake update";
      nfc = "nix flake check";
      nrs = "nh os switch";
      nrt = "nh os test";
      nrb = "nh os build";
      hms = "nh home switch";
      gst = "git status --short --branch";
      gaa = "git add --all";
      gl = "git log --oneline --graph --decorate";
    };
    shellAbbrs = {
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      gco = "git checkout";
      gcb = "git checkout -b";
      gp = "git push";
      gpl = "git pull --rebase";
      n = "nvim";
      y = "yazi";
      sw = "nh os switch";
      tst = "nh os test";
      bld = "nh os build";
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      command_timeout = 500;
      format = "$username$hostname$directory$git_branch$git_status$nix_shell$fill$cmd_duration$line_break$character";
      directory = {
        truncation_length = 4;
        truncate_to_repo = true;
        style = "bold #89b4fa";
        format = "[$path]($style) ";
      };
      git_branch.symbol = " ";
      git_branch.style = "bold #fab387";
      git_status.style = "bold #f38ba8";
      nix_shell.symbol = "❄️ ";
      nix_shell.style = "bold #89b4fa";
      character.success_symbol = "[❯](bold #a6e3a1)";
      character.error_symbol = "[❯](bold #f38ba8)";
      fill.symbol = " ";
    };
  };

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
    historyWidget.command = "";
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 55%"
      "--layout=reverse"
      "--border rounded"
      "--preview-window=right:65%:wrap"
      "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8"
    ];
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      style = "compact";
      inline_height = 25;
      show_preview = true;
      enter_accept = false;
    };
  };
}
