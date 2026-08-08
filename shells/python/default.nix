{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "python";
  icon = "🐍";
  description = "uv, Ruff, Pyright, Data & AI (Polars, Pandas, DuckDB, Marimo)";

  packages = with pkgs; [
    # Core Python runtime & package managers
    python3
    uv # Fast resolver/installer/venv manager (replaces pip + virtualenv)
    poetry # Kept for existing pyproject-based projects
    python3Packages.ipython # Enhanced interactive REPL

    # Data Science, Analysis & Notebooks (Integrated)
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
    UV_PYTHON_DOWNLOADS = "never"; # Use the Nix interpreter, never fetch external ones
  };

  tips = [
    {
      key = "Interactive REPL";
      cmd = "ipython / marimo edit notebook.py";
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
      key = "Fast venv+deps";
      cmd = "uv venv / uv pip install -r requirements.txt";
    }
    {
      key = "Legacy projects";
      cmd = "poetry run / poetry add <pkg>";
    }
  ];

  # Real logic, not decoration: offer to create/activate a local virtualenv.
  extraHook = ''
    if [ -d .venv ]; then
      # shellcheck disable=SC1091
      source .venv/bin/activate
      printf '\033[1;32m✅ Activated existing .venv\033[0m\n'
    elif [ -t 0 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      printf '\033[1;33m📦 No .venv in %s. Create one now? [y/N]: \033[0m' "$(pwd)"
      read -r _ds_reply
      case "$_ds_reply" in
        [yY] | [yY][eE][sS])
          uv venv .venv
          # shellcheck disable=SC1091
          source .venv/bin/activate
          printf '\033[1;32m✅ Virtualenv created and activated\033[0m\n'
          ;;
        *)
          printf '\033[1;30m⏭  Skipped. Create later with: uv venv && source .venv/bin/activate\033[0m\n'
          ;;
      esac
      unset _ds_reply
    fi
  '';
}
