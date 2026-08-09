{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "python";
  icon = "🐍";
  description = "Python3, pip, uv, Ruff, Pyright, Polars, DuckDB, Jupyter";

  packages = with pkgs; [
    # Core Python runtime, pip & package managers
    python3
    python3Packages.pip # Full pip support
    python3Packages.setuptools # Build dependencies for packages
    python3Packages.wheel # Wheel builder
    python3Packages.virtualenv # Virtualenv creator
    uv # Ultra-fast resolver/installer (replaces pip + virtualenv)
    poetry # Kept for existing pyproject-based projects
    python3Packages.ipython # Enhanced interactive REPL

    # Data Science, Analysis & Notebooks
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.polars # High-performance multi-threaded DataFrame engine (Rust)
    marimo # Next-generation reactive Python notebook
    python3Packages.jupyterlab # Classical interactive lab environment
    duckdb # In-process SQL OLAP database
    sqlite # Local relational database

    # Linters, formatters & type checkers
    ruff # Extremely fast Python linter and code formatter (Rust)
    pyright # Static type checker and LSP

    # Dev & JSON utilities
    jq
  ];

  env = {
    PYTHONUNBUFFERED = "1";
    # Allow uv to work with both system Python and seeded virtual environments
    PIP_DISABLE_PIP_VERSION_CHECK = "1";
  };

  tips = [
    {
      key = "Interactive REPL";
      cmd = "ipython / marimo edit notebook.py";
    }
    {
      key = "Package Install";
      cmd = "pip install <pkg>  /  uv pip install <pkg>";
    }
    {
      key = "Data & SQL";
      cmd = "duckdb / jupyter lab";
    }
    {
      key = "Lint / Format";
      cmd = "ruff check . / ruff format .";
    }
    {
      key = "Legacy projects";
      cmd = "poetry run / poetry add <pkg>";
    }
  ];

  # Real logic: offer to create/activate a seeded local virtualenv.
  extraHook = ''
    if [ -d .venv ]; then
      # shellcheck disable=SC1091
      source .venv/bin/activate
      printf '\033[1;32m✅ Activated existing .venv (pip & python active)\033[0m\n'
    elif [ -t 0 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      printf '\033[1;33m📦 No .venv in %s. Create one with pip now? [y/N]: \033[0m' "$(pwd)"
      read -r _ds_reply
      case "$_ds_reply" in
        [yY] | [yY][eE][sS])
          uv venv --seed .venv
          # shellcheck disable=SC1091
          source .venv/bin/activate
          printf '\033[1;32m✅ Virtualenv created with pip & activated\033[0m\n'
          ;;
        *)
          printf '\033[1;30m⏭  Skipped. Create later with: uv venv --seed .venv && source .venv/bin/activate\033[0m\n'
          ;;
      esac
      unset _ds_reply
    fi
  '';
}
