# ==============================================================================
# WEB DEV SHELL — Node.js, Bun, pnpm, TypeScript & Web Toolchains
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "web-env";

    packages = with pkgs; [
      # Core Runtimes & Package Managers
      nodejs_22 # Current stable LTS Node.js runtime
      bun # Ultra-fast JavaScript/TypeScript all-in-one toolchain
      pnpm # Efficient alternative package manager
      yarn # Traditional package manager alternative

      # Languages & NeoVim Language Servers (LSP)
      typescript # TypeScript compiler (tsc)
      typescript-language-server # Essential LSP for Neovim TypeScript autocompletion
      vtsls # High-performance alternative LSP for TypeScript
      tailwindcss-language-server # Autocomplete and linting for Tailwind CSS classes

      # Linters, Formatters & Quality Assurance
      eslint # JavaScript/TypeScript pluggable linter
      prettier # Opinionated code formatter for web stacks
      # biome # Rust-powered ultra-fast alternative to ESLint/Prettier
      # vitest # Next-generation blazing fast testing framework
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;35m🌐 Web Development Shell (Node.js, Bun, pnpm, TS, Lint)    \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Node / PNPM : \033[0m$(node -v) / $(pnpm -v)                    \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Bun Runtime : \033[0m$(bun --version)                           \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="web"
    '';
  };
}
