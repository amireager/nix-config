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
      git lazygit fd ripgrep fzf tmux yazi

      # === Python ===
      pyright        # Python LSP
      ruff           # Python linter & formatter (fast)
      python3Packages.ipython # enhanced Python REPL

      # === Nix ===
      nixd           # Nix LSP
      alejandra      # Nix formatter
      statix         # Nix linter (best practices)
      deadnix        # find unused Nix code

      # === Lua ===
      lua-language-server # Lua LSP
      stylua         # Lua formatter

      # === Shell ===
      bash-language-server   # Bash LSP
      shellcheck       # Bash linter
      shfmt            # Shell formatter

      # === Markup & config ===
      taplo            # TOML LSP & formatter
      yaml-language-server   # YAML LSP
      marksman         # Markdown LSP
      prettier         # web formatter (JS/TS/HTML/CSS/JSON/MD)

      # === JS/TS ===
      typescript-language-server  # TypeScript/JavaScript LSP

      # === HTML/CSS/JSON ===
      vscode-langservers-extracted # HTML/CSS/JSON LSP

      # === Tailwind ===
      tailwindcss-language-server  # Tailwind CSS LSP
      emmet-language-server        # Emmet LSP (HTML expansion)

      # === Go ===
      gopls            # Go LSP

      # === Rust ===
      rust-analyzer    # Rust LSP

    ];

    plugins = with pkgs.vimPlugins; [
      # UI & appearance
      catppuccin-nvim        # Catppuccin theme
      nightfox-nvim          # Nightfox dark theme (with custom #0d131a palette)
      tokyonight-nvim        # Tokyonight theme
      scope-nvim             # Per-tab buffer isolation (fixes bufferline tabs)
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

      # DAP (Debug Adapter Protocol)
      # Commented out — codeberg.org blocked in Iran (TLS error)
      # Uncomment after first build with proxy, or use alternative source
      # nvim-dap               # core debugger
      # nvim-dap-ui            # debugger UI
      # nvim-dap-virtual-text  # inline variable values
      # nvim-dap-python        # Python debug adapter

      # UX Enhancements
      todo-comments-nvim     # TODO/FIXME/HACK highlighting
      trouble-nvim           # diagnostics list
      diffview-nvim          # git diff view
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
      ${builtins.readFile ./lua/dap.lua}
      ${builtins.readFile ./lua/ux.lua}
    '';
  };
}
