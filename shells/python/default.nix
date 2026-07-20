# ==============================================================================
# PYTHON DEV SHELL — Specialized Python Development Environment
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "python-env";

    packages = with pkgs; [
      # Core Python & Packaging
      python3
      python3Packages.pip
      python3Packages.virtualenv
      python3Packages.ipython # Enhanced interactive REPL
      poetry

      # Linters, Formatters & Type Checkers
      ruff
      pyright

      # Dev Utilities
      jq
    ];

    PIP_REQUIRE_VIRTUALENV = "true";
    PYTHONUNBUFFERED = "1";

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;32m🐍 Python Development Shell (Poetry, Ruff, Pyright, REPL)  \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Interactive REPL:\033[0m ipython                                \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Fast Lint/Format:\033[0m ruff check . / ruff format .         \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Package Manager :\033[0m poetry run / poetry add              \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="python"

      # Interactive Virtual Environment Prompt (Ask before creating .venv)
      if [ ! -d .venv ] && [ -t 0 ]; then
        echo -ne "\033[1;33m📦 No .venv detected in $(pwd). Create local virtualenv now? [y/N]: \033[0m"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
          echo -e "\n📦 Initializing local virtualenv inside .venv..."
          python3 -m venv .venv
          source .venv/bin/activate
          echo -e "\033[1;32m✅ Virtualenv created and activated!\033[0m"
        else
          echo -e "\033[1;30m⏭️ Skipping .venv creation. (To create anytime: python3 -m venv .venv && source .venv/bin/activate)\033[0m"
        fi
      elif [ -d .venv ]; then
        source .venv/bin/activate
        echo -e "\033[1;32m✅ Activated existing local virtual environment (.venv)!\033[0m"
      fi
    '';
  };
}
