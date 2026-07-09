{pkgs, ...}: let
  treesitterGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p:
    with p; [
      bash c cpp css dockerfile
      git_config git_rebase gitattributes gitcommit gitignore
      html javascript jsdoc json lua luadoc
      markdown markdown_inline nix python regex
      rust toml tsx typescript vim vimdoc yaml
    ]);
in {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withNodeJs = true;
    withPython3 = true;
    withRuby = false;

    extraPackages = with pkgs; [
      # Core utilities (always needed)
      git fd ripgrep fzf tmux yazi

      # === Python (global — most common language) ===
      pyright        # Python LSP
      ruff           # Python linter & formatter (fast)
      python3Packages.ipython # enhanced Python REPL

      # === Nix (global — NixOS config editing) ===
      nixd           # Nix LSP
      alejandra      # Nix formatter
      statix         # Nix linter (best practices)
      deadnix        # find unused Nix code

      # === Lua (global — for nvim config itself) ===
      lua-language-server # Lua LSP
      stylua         # Lua formatter

      # === Shell (global — system scripts) ===
      bash-language-server   # Bash LSP
      shellcheck       # Bash linter
      shfmt            # Shell formatter

      # === Markup & config (global — always needed) ===
      taplo            # TOML LSP & formatter
      yaml-language-server   # YAML LSP
      marksman         # Markdown LSP
      prettier         # web formatter (JS/TS/HTML/CSS/JSON/MD)

      # === JS/TS (move to devShell if not daily) ===
      typescript-language-server  # TypeScript/JavaScript LSP
      # vscode-langservers-extracted # HTML/CSS/JSON LSP — heavy, use devShell
      # tailwindcss-language-server  # Tailwind LSP — use devShell
      # emmet-language-server        # Emmet LSP — use devShell

      # === Rust (move to devShell — very heavy) ===
      # rust-analyzer  # Rust LSP — use devShell
      # cargo           # Rust package manager — use devShell
      # clippy          # Rust linter — use devShell
      # rustfmt         # Rust formatter — use devShell
    ];

    plugins = with pkgs.vimPlugins; [
      # UI & appearance
      catppuccin-nvim        # color scheme
      nvim-web-devicons      # file icons
      lualine-nvim           # status line
      bufferline-nvim        # tab/buffer line
      which-key-nvim         # keybinding hints
      snacks-nvim            # UI components library

      # Treesitter & syntax
      treesitterGrammars     # syntax highlighting for all languages
      nvim-ts-autotag        # auto close/rename HTML tags

      # Completion & snippets
      blink-cmp              # completion engine
      friendly-snippets      # snippet collection

      # LSP & formatting
      nvim-lspconfig         # LSP client configs
      conform-nvim           # formatter manager

      # Utilities
      mini-nvim              # collection of small plugins
      guess-indent-nvim      # auto-detect indentation
      render-markdown-nvim   # live markdown preview
      gitsigns-nvim          # git change indicators
      vim-slime              # send code to terminal (REPL)
      plenary-nvim           # utility library (required by many)
    ];

    initLua = ''
      ${builtins.readFile ./lua/options.lua}
      ${builtins.readFile ./lua/keymaps.lua}
      ${builtins.readFile ./lua/autocmds.lua}
      ${builtins.readFile ./lua/ui.lua}
      ${builtins.readFile ./lua/snacks.lua}
      ${builtins.readFile ./lua/completion.lua}
      ${builtins.readFile ./lua/lsp.lua}
      ${builtins.readFile ./lua/format-lint.lua}
      ${builtins.readFile ./lua/git.lua}
      ${builtins.readFile ./lua/productivity.lua}
      ${builtins.readFile ./lua/run.lua}
      ${builtins.readFile ./lua/markdown.lua}
    '';
  };
}
