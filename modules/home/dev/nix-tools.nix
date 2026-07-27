{
  pkgs,
  flakePath,
  ...
}: {
  # ============================================================================
  # NIX TOOLING — System Level
  # ============================================================================
  # Only tools that must be available *outside* a project checkout live here.
  # Rule of thumb: if you reach for it while something is already broken,
  # it belongs at system level. Everything else lives in `shells/nix`.
  # ============================================================================

  # ── nix-index-database ──
  # Provides a pre-built file->package index (rebuilt daily upstream), so
  # `comma` and `nix-locate` work instantly instead of requiring a ~10 min
  # local `nix-index` run. The HM module installs `comma-with-db` for us,
  # which is why plain `comma` / `nix-index` are NOT in home.packages below.
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
    # The DB is fetched as a flake input; no local indexing, no stale cache.
    symlinkToCacheHome = true;
  };
  programs.nix-index-database.comma.enable = true;

  home.packages = with pkgs; [
    # === Inspection & Debugging (always available on purpose) ===
    nix-tree # Interactive dependency tree explorer
    nix-diff # Explain *why* two derivations differ / why a rebuild happened
    nix-du # Which store paths actually consume disk
    nix-melt # TUI viewer for flake.lock
    nix-output-monitor # Readable build output with progress

    # === Nix code QA — kept at system level by explicit choice ===
    # These are used constantly while editing config, including on files
    # outside this repo, so paying for them globally is the right trade.
    statix # Anti-pattern linter
    deadnix # Dead code detector
    alejandra # Formatter (matches flake.formatter)

    # === Editor integration ===
    nixd # LSP — must work in any .nix file, not just inside a project

    # === Global Dev CLI — launcher for the centralized on-demand shells ===
    (writeShellScriptBin "dev" ''
      FLAKE_PATH="''${NIX_CONFIG_FLAKE:-${flakePath}}"
      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        for candidate in "$HOME/nix-config" "$HOME/projects/nix-config" "/etc/nixos"; do
          if [ -f "$candidate/flake.nix" ]; then
            FLAKE_PATH="$candidate"
            break
          fi
        done
      fi

      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        echo "dev: no flake.nix found (tried $FLAKE_PATH, ~/nix-config, ~/projects/nix-config, /etc/nixos)" >&2
        echo "dev: set NIX_CONFIG_FLAKE=/path/to/nix-config to override" >&2
        exit 1
      fi

      # Resolve symlinks (/etc/nixos is usually a link to the real checkout).
      # Without this the same repo can be evaluated under two different paths,
      # producing duplicate evaluations and duplicate GC roots.
      FLAKE_PATH="$(cd "$FLAKE_PATH" && pwd -P)"

      if [ $# -eq 0 ]; then
        echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
        echo -e "\033[1;36m│ \033[1;35m🚀 Centralized On-Demand DevShell Manager                \033[1;36m│\033[0m"
        echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
        echo -e "\033[1;36m💡 Usage: dev <environment> [command/task...]\033[0m"
        echo -e "\033[1;33m📦 Available centralized environments ($FLAKE_PATH):\033[0m"
        echo "  [ Languages & Runtimes ]"
        echo "  - dev python   (uv, Poetry, Ruff, Pyright, interactive .venv prompt)"
        echo "  - dev rust     (Cargo, Rustc, Rust-Analyzer, Clippy, Rustfmt)"
        echo "  - dev go       (Go, Gopls, GolangCI-Lint, Delve)"
        echo "  - dev web      (Node.js, Bun, pnpm, TypeScript, ESLint, Prettier)"
        echo ""
        echo "  [ Data & AI ]"
        echo "  - dev data     (Pandas, Polars, DuckDB, Jupyter Lab, SQLite)"
        echo "  - dev ai       (LLM APIs, OpenCode, 9router/Omnirouter, Agentic Runtimes)"
        echo ""
        echo "  [ Media & Content ]"
        echo "  - dev media    (ffmpeg-full, vips, ImageMagick, PDF & image editors)"
        echo ""
        echo "  [ System, Build & QA ]"
        echo "  - dev cli      (Analytics: ast-grep, hyperfine, tokei, bandwhich)"
        echo "  - dev build    (C/C++/Rust: GCC, Clang, CMake, Make, Ninja) [alias: dev c]"
        echo "  - dev sec      (Sandboxing: safe-crypt, safe-test, vulnix)"
        echo "  - dev nix      (Packaging: nurl, nix-init, nix-update, nixpkgs-review)"
        echo "  - dev test     (Composite test runner: Python + Rust combined toolchains)"
        exit 0
      fi

      ENV_NAME="$1"
      shift

      # 1. Asynchronously register dynamic GC profile in background so it never blocks evaluation or hangs
      mkdir -p "$HOME/.local/share/dev-roots"
      (nix print-dev-env "$FLAKE_PATH#$ENV_NAME" --profile "$HOME/.local/share/dev-roots/$ENV_NAME-profile" > /dev/null 2>&1 &)

      # 2. Enter interactive Fish shell or execute specific task/module inside the isolated environment
      if [ $# -eq 0 ]; then
        echo -e "\033[1;32m⏳ Evaluating & launching On-Demand DevShell: \033[1;36m$ENV_NAME \033[1;32m(Default shell: Fish)\033[0m"
        exec nix develop "$FLAKE_PATH#$ENV_NAME" --command fish
      else
        echo -e "\033[1;32m⚡ Executing task inside On-Demand DevShell \033[1;36m$ENV_NAME\033[1;32m: \033[1;33m$*\033[0m"
        exec nix develop "$FLAKE_PATH#$ENV_NAME" --command fish -c "$*"
      fi
    '')
  ];
}
