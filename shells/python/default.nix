{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "python";
  icon = "🐍";
  description = "uv, Poetry, Ruff, Pyright, IPython";

  packages = with pkgs; [
    # Core Python & packaging
    python3
    uv # Resolver/installer/venv manager — replaces pip + virtualenv
    poetry # Kept for existing pyproject-based projects
    python3Packages.ipython # Enhanced interactive REPL

    # Linters, formatters & type checkers
    ruff
    pyright

    # Dev utilities
    jq
  ];

  env = {
    PYTHONUNBUFFERED = "1";
    UV_PYTHON_DOWNLOADS = "never"; # Use the Nix interpreter, never fetch one
  };

  tips = [
    {
      key = "Interactive REPL";
      cmd = "ipython";
    }
    {
      key = "Lint / Format";
      cmd = "ruff check . / ruff format .";
    }
    {
      key = "Fast venv+deps";
      cmd = "uv venv / uv pip install -r req.txt";
    }
    {
      key = "Legacy projects";
      cmd = "poetry run / poetry add";
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
