# ==============================================================================
# DEVSHELL TEMPLATE — Reference Pattern for Modular On-Demand Environments
# ==============================================================================
# This file serves as a comprehensive reference of all available options and
# techniques for creating specialized devShells (e.g., Python, Rust, Security).
# ==============================================================================

{pkgs, ...}: {
  # mkShell creates a dynamic environment with isolated tools and variables.
  default = pkgs.mkShell {
    # Name displayed during evaluation and in custom terminal prompts.
    name = "example-dev-shell";

    # ──────────────────────────────────────────────────────────────────────────
    # 1. Packages & Tooling
    # Tools strictly available inside this shell session. Upon exiting (`exit`),
    # all these packages disappear from the active PATH.
    # ──────────────────────────────────────────────────────────────────────────
    packages = with pkgs; [
      # Core utilities (examples)
      git
      curl
      jq

      # Custom embedded script available strictly within this shell
      (writeShellScriptBin "hello-dev" ''
        echo "Hello from inside the sandboxed dev environment!"
      '')
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # 2. Environment Variables
    # Variables exported automatically upon entering this shell.
    # ──────────────────────────────────────────────────────────────────────────
    MY_CUSTOM_ENV_VAR = "production";
    PYTHONUNBUFFERED = "1";
    PIP_REQUIRE_VIRTUALENV = "true";

    # ──────────────────────────────────────────────────────────────────────────
    # 3. Shell Hook
    # Shell commands executed immediately upon entering this environment.
    # Common uses: prompt styling, temporary directory initialization, venv setup.
    # ──────────────────────────────────────────────────────────────────────────
    shellHook = ''
      # Prompt greeting and active state flags
      echo -e "\033[1;36m[🚀 DevShell Loaded]: \033[1;32m$name\033[0m"

      # Example: auto-initialize and activate a local Python virtual environment
      # if [ ! -d .venv ]; then
      #   echo "📦 Initializing local virtualenv (.venv)..."
      #   python3 -m venv .venv
      # fi
      # source .venv/bin/activate

      # Set prompt indicator variables for Starship / Fish
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="$name"
    '';

    # ──────────────────────────────────────────────────────────────────────────
    # 4. Build Dependency Inheritance (inputsFrom) [Optional]
    # Inherits all build dependencies (libraries, compilers) needed to build
    # specific derivations (e.g., neovim or the Linux kernel).
    # ──────────────────────────────────────────────────────────────────────────
    # inputsFrom = [ pkgs.neovim ];
  };
}
