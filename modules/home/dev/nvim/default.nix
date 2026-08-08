{pkgs, ...}: let
  treesitterGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p:
    with p; [
      bash
      c
      cpp
      css
      dockerfile
      git_config
      git_rebase
      gitattributes
      gitcommit
      gitignore
      html
      javascript
      jsdoc
      json
      lua
      luadoc
      markdown
      markdown_inline
      nix
      python
      regex
      rust
      toml
      tsx
      typescript
      vim
      vimdoc
      yaml
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
      git
      lazygit
      fd
      ripgrep
      fzf
      tmux
      yazi

      # === Python ===
      pyright # Python LSP
      ruff # Python linter & formatter (fast)
      python3Packages.ipython # enhanced Python REPL

      # === Nix ===
      nixd # Nix LSP
      alejandra # Nix formatter
      statix # Nix linter (best practices)
      deadnix # find unused Nix code

      # === Lua ===
      lua-language-server # Lua LSP
      stylua # Lua formatter

      # === Shell ===
      bash-language-server # Bash LSP
      shellcheck # Bash linter
      shfmt # Shell formatter

      # === Debug adapters ===
      # Only Python is global. It is the everyday language here, and debugpy
      # is 21 MiB.
      #
      # The others are deliberately absent, because they are project tools and
      # they are not cheap:
      #   lldb   pulls libclang -> +849 MiB   -> dev build, dev rust
      #   gdb                       +49 MiB   -> dev build
      #   delve                     +30 MiB   -> dev go (already there)
      #
      # direnv-vim attaches them to Neovim on entering the project, the same
      # way rust-analyzer and gopls already work. Nothing breaks without them:
      # dap.lua names the adapter binaries, so a missing one only errors when
      # you start a session for that language.
      python3Packages.debugpy # Python

      # === Markup & config ===
      taplo # TOML LSP & formatter
      yaml-language-server # YAML LSP
      marksman # Markdown LSP
      prettier # web formatter (JS/TS/HTML/CSS/JSON/MD)

      # === JS/TS ===
      typescript-language-server # TypeScript/JavaScript LSP

      # === HTML/CSS/JSON ===
      vscode-langservers-extracted # HTML/CSS/JSON LSP

      # === Tailwind ===
      tailwindcss-language-server # Tailwind CSS LSP
      emmet-language-server # Emmet LSP (HTML expansion)

      # NOTE: Heavy LSP servers (`rust-analyzer` and `gopls`) are decoupled from
      # the global Neovim binary and moved to `shells/rust` (`dev rust`) and `shells/go` (`dev go`).
      # Neovim's `direnv-vim` auto-attaches them instantly when inside a project!
    ];

    plugins = with pkgs.vimPlugins; [
      # UI & appearance
      catppuccin-nvim # Catppuccin theme
      nightfox-nvim # Nightfox dark theme (with custom #0d131a palette)
      tokyonight-nvim # Tokyonight theme
      scope-nvim # Per-tab buffer isolation (fixes bufferline tabs)
      nvim-web-devicons # file icons
      lualine-nvim # status line
      bufferline-nvim # tab/buffer line
      which-key-nvim # keybinding hints
      snacks-nvim # UI components library

      # Treesitter & syntax
      treesitterGrammars # syntax highlighting for all languages
      nvim-ts-autotag # auto close/rename HTML tags
      nvim-treesitter-context # sticky header: which function/class am I in
      nvim-treesitter-textobjects # daf/vic/]f — operate on functions and classes

      # Completion & snippets
      blink-cmp # completion engine
      friendly-snippets # snippet collection
      lazydev-nvim # LuaLS types for the Neovim API itself

      # LSP & formatting
      nvim-lspconfig # LSP client configs
      conform-nvim # formatter manager

      # Utilities & Git
      mini-nvim # collection of small plugins
      guess-indent-nvim # auto-detect indentation
      render-markdown-nvim # live markdown preview
      gitsigns-nvim # git change indicators
      neogit # Magit-style keyboard-centric Git interface
      direnv-vim # Auto-connect Neovim LSPs to direnv/devShell environments
      vim-slime # send code to terminal (REPL)
      plenary-nvim # utility library (required by many)

      # DAP (Debug Adapter Protocol)
      # nvim-dap and nvim-dap-python are fetched from codeberg.org, which is
      # unreachable from here. Build them once behind the proxy:
      #   nix_proxy 1819 && nh os switch && nix_proxy off
      # After that they are in the store and rebuild without it.
      nvim-dap # core debugger
      nvim-dap-ui # panels: scopes, stacks, breakpoints, repl
      nvim-dap-virtual-text # variable values inline, next to the code
      nvim-dap-python # Python adapter (debugpy)
      one-small-step-for-vimkind # Lua adapter — debug this config itself

      # AI — see lua/ai.lua. Inert until a <leader>a key is pressed: nothing
      # connects to anything at startup, and there is no as-you-type
      # completion.
      codecompanion-nvim # chat, inline edits, @{agent} tools
      codecompanion-history-nvim # saved chats, browsable with gh

      # UX Enhancements
      flash-nvim # query-driven jumps (replaces mini.jump2d)
      todo-comments-nvim # TODO/FIXME/HACK highlighting
      trouble-nvim # diagnostics list
      diffview-nvim # git diff view
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
      ${builtins.readFile ./lua/navigation.lua}
      ${builtins.readFile ./lua/run.lua}
      ${builtins.readFile ./lua/markdown.lua}
      ${builtins.readFile ./lua/dap.lua}
      ${builtins.readFile ./lua/ai.lua}
      ${builtins.readFile ./lua/ux.lua}
    '';
  };
}
