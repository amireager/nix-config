# ==============================================================================
# PYTHON DEV SHELL — Optimized Python Dev Environment (Poetry + Ruff + Venv)
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "python-env";

    packages = with pkgs; [
      # Core Python & Packaging
      python3
      python3Packages.pip
      python3Packages.virtualenv
      poetry

      # Linters, Formatters & Type Checkers
      ruff
      pyright

      # Useful dev utilities
      jq
    ];

    # Standard environment variables to prevent PIP/Nix store conflicts
    PIP_REQUIRE_VIRTUALENV = "true";
    PYTHONUNBUFFERED = "1";

    shellHook = ''
      echo -e "\033[1;36m[🐍 Python Environment Loaded]: \033[1;32mPoetry, Ruff, Pyright\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="python"

      # Auto-create and activate virtualenv in the current working directory
      if [ ! -d .venv ]; then
        echo -e "\033[1;33m📦 Creating local virtualenv inside .venv...\033[0m"
        python3 -m venv .venv
      fi
      source .venv/bin/activate
    '';
  };
}
