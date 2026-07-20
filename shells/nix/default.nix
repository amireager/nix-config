# ==============================================================================
# NIX DEV SHELL — Specialized Environment for Nix Code Inspection & Debugging
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "nix-env";

    packages = with pkgs; [
      # Linters & Formatters
      statix             # Anti-pattern and syntax checking
      deadnix            # Find unused code and variables
      alejandra          # Official code formatter

      # LSP & Analysis Tools
      nixd               # Neovim & editor LSP server
      nix-tree           # Interactive dependency tree explorer
      nvd                # Generation diff viewer

      # Unified configuration health & syntax check helper
      (writeShellScriptBin "nix-check" ''
        echo -e "\033[1;36m[1/3] 🔍 Running Statix (Syntax & Anti-pattern Check)...\033[0m"
        ${statix}/bin/statix check . || true

        echo -e "\n\033[1;33m[2/3] 💀 Running Deadnix (Unused Code Check)...\033[0m"
        ${deadnix}/bin/deadnix . || true

        echo -e "\n\033[1;35m[3/3] ❄️ Running Flake Evaluation (nix flake check --no-build)...\033[0m"
        nix flake check --no-build "$@"
      '')
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;36m❄️ Nix Development Shell (Statix, Deadnix, Alejandra, Nixd) \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Check Health     :\033[0m nix-check (statix + deadnix + flake) \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Format Code      :\033[0m alejandra .                          \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Inspect Store Tree:\033[0m nix-tree                             \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="nix"
    '';
  };
}
