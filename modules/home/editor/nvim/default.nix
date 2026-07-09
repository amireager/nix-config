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
      git fd ripgrep fzf tmux yazi
      pyright ruff python3Packages.ipython
      typescript-language-server prettier
      vscode-langservers-extracted tailwindcss-language-server emmet-language-server
      rust-analyzer cargo clippy rustfmt
      nixd alejandra statix deadnix
      lua-language-server stylua
      fish bash-language-server shellcheck shfmt
      taplo yaml-language-server marksman
    ];

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim nvim-web-devicons lualine-nvim bufferline-nvim which-key-nvim snacks-nvim
      treesitterGrammars nvim-ts-autotag
      blink-cmp friendly-snippets
      nvim-lspconfig conform-nvim
      mini-nvim guess-indent-nvim
      render-markdown-nvim
      gitsigns-nvim vim-slime
      plenary-nvim
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
