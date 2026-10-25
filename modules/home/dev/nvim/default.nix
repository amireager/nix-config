{pkgs, ...}: let
  treesitterGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (p:
    with p; [
      bash
      c
      cpp
      css
      dockerfile
      fish
      git_config
      git_rebase
      gitattributes
      gitcommit
      gitignore
      go
      gomod
      gosum
      gowork
      html
      javascript
      jsdoc
      json
      lua
      luadoc
      make
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
  # Startup order matters: later files override mappings of earlier ones.
  luaFiles = [
    "options"
    "keymaps"
    "autocmds"
    "ui"
    "snacks"
    "completion"
    "lsp"
    "format-lint"
    "git"
    "productivity"
    "navigation"
    "treesitter"
    "run"
    "tasks"
    "markdown"
    "dap"
    "ai"
    "ux"
  ];
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

    # Remote-plugin hosts are separate from language servers and DAP adapters.
    # The current plugin set has no Node/Python remote plugins, so don't build
    # extra provider environments or run their online package checks. Node LSPs,
    # Pyright/Ruff, and debugpy arrive from the matching dev shells instead.
    withNodeJs = false;
    withPython3 = false;
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
      file # MIME/type detection used by image previews
      sqlite # sqlite3 CLI: only satisfies CodeCompanion's optional health probe (Snacks uses the library, see initLua)

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

      # === Debug adapters & language tools ===
      # Python, web, Rust, and Go tools are provided by their matching dev
      # shells. direnv-vim exposes each shell's PATH to LSP/DAP when entering a
      # project, keeping the global Neovim closure independent of those stacks.
      #
      # Debug adapters are likewise on-demand: lldb/gdb via `dev build` or
      # `dev rust`, delve/debugpy via `dev go`/`dev python`. Missing adapters
      # only matter when launching a debug session for that language.

      # === General markup & config (no dedicated shell) ===
      taplo # TOML LSP & formatter
      yaml-language-server # YAML LSP
      marksman # Markdown LSP
      prettier # cross-language formatter, also used for Markdown/JSON/YAML

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
      #   nix_proxy on && nh os switch && nix_proxy off
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
      -- Byte-code cache for every Lua module Neovim loads, plugins included. It cut
      -- startup roughly in half here; the first launch after a rebuild fills it.
      vim.loader.enable()

      -- Store paths that Lua cannot know. Read by snacks.lua; unset outside Nix.
      vim.g.nix_sqlite3_path = "${pkgs.lib.getLib pkgs.sqlite}/lib/libsqlite3.so"

      -- Each file below runs as its own function. Without that, the files form one
      -- big chunk: the `if not ok then return end` guards at the top of snacks.lua,
      -- completion.lua, markdown.lua, dap.lua and ai.lua would end the *whole*
      -- config when a single plugin failed to load (no LSP, no formatting, no git),
      -- one error would skip everything after it, and the chunk-wide limit of 200
      -- locals (116 used) would be a ceiling for every future addition.
      local function section(name, fn)
        local ok, err = pcall(fn)
        if not ok then
          vim.schedule(function()
            vim.notify(("config: %s.lua failed\n%s"):format(name, err), vim.log.levels.ERROR)
          end)
        end
      end

      ${builtins.concatStringsSep "\n" (map (name: ''
          section("${name}", function()
          ${builtins.readFile (./lua + "/${name}.lua")}
          end)
        '')
        luaFiles)}
    '';
  };
}
