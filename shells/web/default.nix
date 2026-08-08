{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "web";
  icon = "🌐";
  description = "Node.js, Bun, pnpm, TypeScript, Lint";

  packages = with pkgs; [
    # Core runtimes & package managers
    nodejs_22 # Current stable LTS Node.js runtime
    bun # Ultra-fast JavaScript/TypeScript all-in-one toolchain
    pnpm # Efficient alternative package manager
    yarn # Traditional package manager alternative

    # Languages & Neovim language servers
    typescript # TypeScript compiler (tsc)
    typescript-language-server # LSP for Neovim TypeScript autocompletion
    vtsls # High-performance alternative TypeScript LSP
    tailwindcss-language-server # Autocomplete & linting for Tailwind classes

    # Linters, formatters & QA
    eslint # JavaScript/TypeScript pluggable linter
    prettier # Opinionated formatter for web stacks
    # biome  # Rust-powered alternative to ESLint/Prettier
    # vitest # Fast testing framework
  ];

  tips = [
    {
      key = "Install";
      cmd = "pnpm install / bun install";
    }
    {
      key = "Dev server";
      cmd = "pnpm dev / bun run dev";
    }
    {
      key = "Typecheck";
      cmd = "tsc --noEmit";
    }
    {
      key = "Lint & Format";
      cmd = "eslint . / prettier -w .";
    }
  ];

  # Versions are resolved at runtime; running them in the banner data would
  # execute node/bun on every evaluation.
  extraHook = ''
    if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      printf '  \033[1;30mnode %s · bun %s · pnpm %s\033[0m\n' \
        "$(node -v 2>/dev/null)" "$(bun --version 2>/dev/null)" "$(pnpm -v 2>/dev/null)"
    fi
  '';
}
