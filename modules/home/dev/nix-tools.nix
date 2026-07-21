{pkgs, ...}: {
  home.packages = with pkgs; [
    # === Nix LSP & Inspection Tools ===
    nixd # Nix LSP for editor integration
    nix-tree # Explore Nix store dependency tree
    nvd # Diff between NixOS generations
    nix-search-tv # Interactive nixpkgs search (TUI)
    comma # Run any command without installing
    nix-index # Locate packages providing a file
    nix-output-monitor # Beautiful build output with progress

    # === Global Dev CLI — Quick launcher for centralized isolated environments ===
    (writeShellScriptBin "dev" ''
      FLAKE_PATH="''${NIX_CONFIG_FLAKE:-/home/$USER/projects/nix-config}"
      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        if [ -f "$HOME/nix-config/flake.nix" ]; then
          FLAKE_PATH="$HOME/nix-config"
        elif [ -f "/etc/nixos/flake.nix" ]; then
          FLAKE_PATH="/etc/nixos"
        fi
      fi

      if [ $# -eq 0 ]; then
        echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
        echo -e "\033[1;36m│ \033[1;35m🚀 Centralized On-Demand DevShell Manager                \033[1;36m│\033[0m"
        echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
        echo -e "\033[1;36m💡 Usage: dev <environment> [command/task...]\033[0m"
        echo -e "\033[1;33m📦 Available centralized environments ($FLAKE_PATH):\033[0m"
        echo "  [ Languages & Runtimes ]"
        echo "  - dev python   (Poetry, Ruff, Pyright, interactive .venv prompt)"
        echo "  - dev rust     (Cargo, Rustc, Rust-Analyzer, Clippy, Rustfmt)"
        echo "  - dev go       (Go, Gopls, GolangCI-Lint, Delve)"
        echo "  - dev web      (Node.js, Bun, pnpm, TypeScript, ESLint, Prettier)"
        echo ""
        echo "  [ Data & AI ]"
        echo "  - dev data     (Pandas, Polars, DuckDB, Jupyter Lab, SQLite)"
        echo "  - dev ai       (LLM APIs, OpenCode, 9router/Omnirouter, Agentic Runtimes)"
        echo ""
        echo "  [ System, Build & QA ]"
        echo "  - dev cli      (Analytics: ast-grep, hyperfine, tokei, bandwhich)"
        echo "  - dev build    (C/C++/Rust: GCC, Clang, CMake, Make, Ninja) [alias: dev c]"
        echo "  - dev sec      (Sandboxing: safe-run offline, safe-net-run online)"
        echo "  - dev nix      (Nix tools: statix, deadnix, alejandra, nix-check)"
        echo "  - dev test     (Composite test runner: Python + Rust combined toolchains)"
        exit 0
      fi

      ENV_NAME="$1"
      shift

      # 1. Asynchronously register dynamic GC profile in background so it never blocks evaluation or hangs
      mkdir -p "$HOME/.local/share/dev-roots"
      (nix print-dev-env "path:$FLAKE_PATH#$ENV_NAME" --profile "$HOME/.local/share/dev-roots/$ENV_NAME-profile" > /dev/null 2>&1 &)

      # 2. Enter interactive Fish shell or execute specific task/module inside the isolated environment
      if [ $# -eq 0 ]; then
        echo -e "\033[1;32m⏳ Evaluating & launching On-Demand DevShell: \033[1;36m$ENV_NAME \033[1;32m(Default shell: Fish)\033[0m"
        exec nix develop "path:$FLAKE_PATH#$ENV_NAME" --command fish
      else
        echo -e "\033[1;32m⚡ Executing task inside On-Demand DevShell \033[1;36m$ENV_NAME\033[1;32m: \033[1;33m$*\033[0m"
        exec nix develop "path:$FLAKE_PATH#$ENV_NAME" --command fish -c "$*"
      fi
    '')
  ];
}
