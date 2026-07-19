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
        echo -e "\033[1;36m💡 Usage: dev <environment> [command...]\033[0m"
        echo -e "\033[1;33m📦 Available centralized environments ($FLAKE_PATH):\033[0m"
        echo "  - dev python   (Poetry, Ruff, Pyright + automatic .venv)"
        echo "  - dev nix      (statix, deadnix, alejandra, nix-check)"
        echo "  - dev cli      (ast-grep, hyperfine, tokei, bandwhich)"
        echo "  - dev sec      (bubblewrap, firejail, safe-run, safe-net-run)"
        exit 0
      fi

      ENV_NAME="$1"
      shift

      if [ $# -eq 0 ]; then
        echo -e "\033[1;32m🚀 Entering On-Demand DevShell: \033[1;36m$ENV_NAME\033[0m"
        exec nix develop "$FLAKE_PATH#$ENV_NAME"
      else
        echo -e "\033[1;32m⚡ Running command inside On-Demand DevShell: \033[1;36m$ENV_NAME\033[0m"
        exec nix develop "$FLAKE_PATH#$ENV_NAME" --command "$@"
      fi
    '')
  ];
}
