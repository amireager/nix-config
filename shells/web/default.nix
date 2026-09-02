{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "web";
  icon = "🌐";
  description = "Node.js, Bun, pnpm, TypeScript, Biome, Tailwind";

  packages = with pkgs; [
    # Core runtimes & package managers
    nodejs_24 # Current LTS Node.js runtime
    bun # Ultra-fast JavaScript/TypeScript all-in-one toolchain
    pnpm # Efficient alternative package manager
    yarn # Traditional package manager alternative

    # Ultra-fast Rust-powered Linter & Formatter
    biome # One toolchain to format & lint JS/TS/JSON/CSS with 25x speed

    # Languages & Neovim language servers
    typescript # TypeScript compiler (tsc)
    typescript-language-server # LSP for Neovim TypeScript autocompletion
    vtsls # High-performance alternative TypeScript LSP
    tailwindcss-language-server # Autocomplete & linting for Tailwind classes

    # Traditional Linters & formatters (compatibility)
    eslint # JavaScript/TypeScript pluggable linter
    prettier # Opinionated formatter for web stacks

    # Browser testing & end-to-end debugging. The Node inspector (`node --inspect`)
    # is built into nodejs_24; Playwright covers browser-driven e2e/DAP-style work.
    playwright # Browser automation, e2e tests, and headless debugging
  ];

  tips = [
    {
      key = "Fast Biome QA";
      cmd = "biome check --write .";
    }
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
      key = "Format";
      cmd = "prettier -w .";
    }
  ];

  # Versions are resolved at runtime; running them in the banner data would
  # execute node/bun on every evaluation.
  extraHook = ''
    if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      printf '  \033[1;30mnode %s · bun %s · pnpm %s · biome %s\033[0m\n' \
        "$(node -v 2>/dev/null)" "$(bun --version 2>/dev/null)" "$(pnpm -v 2>/dev/null)" "$(biome --version 2>/dev/null)"
    fi
  '';
}
