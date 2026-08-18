{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "python";
  icon = "🐍";
  description = "Python 3, uv, pip, Ruff, Pyright, IPython";

  packages = with pkgs; [
    # Core Python runtime & package managers
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
    python3Packages.virtualenv
    uv # Ultra-fast Rust package manager & venv runner
    poetry # Legacy pyproject support
    python3Packages.ipython # Interactive REPL

    # Linters, formatters & type checkers
    ruff # Sub-10ms Python linter & formatter
    pyright # Static type checker & LSP

    # Dev & JSON utilities
    jq
  ];

  env = {
    PYTHONUNBUFFERED = "1";
    PIP_DISABLE_PIP_VERSION_CHECK = "1";
  };

  tips = [
    {
      key = "Interactive REPL";
      cmd = "ipython";
    }
    {
      key = "Fast venv + pip";
      cmd = "uv venv --seed .venv && source .venv/bin/activate";
    }
    {
      key = "Install packages";
      cmd = "uv add <pkg>  /  pip install <pkg>";
    }
    {
      key = "Fast scripts";
      cmd = "uv run <script.py> / uvx <tool>";
    }
    {
      key = "Lint & Format";
      cmd = "ruff check . / ruff format .";
    }
  ];

  extraHook = ''
    # Unset PYTHONPATH so global Nix library packages never pollute clean project venvs
    unset PYTHONPATH

    if [ -d .venv ]; then
      # shellcheck disable=SC1091
      source .venv/bin/activate
      printf '\033[1;32m✅ Activated existing .venv (pure & isolated)\033[0m\n'
    elif [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      # Entry hooks stay read-only: creating a project environment is always
      # an explicit user action.
      printf '\033[1;30mNo .venv. Create one when needed: uv venv --seed .venv\033[0m\n'
    fi
  '';
}
