# ==============================================================================
# SECURITY & SANDBOX SHELL — Isolated Sandboxing for Untrusted Binaries & Scripts
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "sec-env";

    packages = with pkgs; [
      # Sandboxing Engines
      bubblewrap         # Lightweight user-space namespace sandboxing
      firejail           # Security profile sandboxing

      # 1. Isolated Sandbox WITHOUT Internet (Safe Execution / Interactive Shell)
      (writeShellScriptBin "safe-run" ''
        if [ $# -eq 0 ]; then
          echo -e "\033[1;33m🛡️ Entering Interactive Sandbox (Network Disabled | Home Restricted to $(pwd))...\033[0m"
          exec ${bubblewrap}/bin/bwrap \
            --ro-bind /usr /usr \
            --ro-bind /nix /nix \
            --ro-bind /etc /etc \
            --proc /proc \
            --dev /dev \
            --bind . /home/$USER \
            --unshare-net \
            "$SHELL"
        else
          echo -e "\033[1;33m🛡️ Launching inside Bubblewrap Sandbox (Network Disabled | Home Restricted to Current Dir)...\033[0m"
          exec ${bubblewrap}/bin/bwrap \
            --ro-bind /usr /usr \
            --ro-bind /nix /nix \
            --ro-bind /etc /etc \
            --proc /proc \
            --dev /dev \
            --bind . /home/$USER \
            --unshare-net \
            "$@"
        fi
      '')

      # 2. Isolated Sandbox WITH Internet (For Online Installers & GitHub Tools)
      (writeShellScriptBin "safe-net-run" ''
        if [ $# -eq 0 ]; then
          echo -e "\033[1;33m🌐 Entering Interactive Sandbox (Network ENABLED | Home Restricted to $(pwd))...\033[0m"
          exec ${bubblewrap}/bin/bwrap \
            --ro-bind /usr /usr \
            --ro-bind /nix /nix \
            --ro-bind /etc /etc \
            --proc /proc \
            --dev /dev \
            --bind . /home/$USER \
            "$SHELL"
        else
          echo -e "\033[1;33m🌐 Launching inside Bubblewrap Sandbox (Network ENABLED | Home Restricted to Current Dir)...\033[0m"
          exec ${bubblewrap}/bin/bwrap \
            --ro-bind /usr /usr \
            --ro-bind /nix /nix \
            --ro-bind /etc /etc \
            --proc /proc \
            --dev /dev \
            --bind . /home/$USER \
            "$@"
        fi
      '')
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;32m🛡️ Security & Sandboxing Shell (Bubblewrap, Firejail)       \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• safe-run [bin]    :\033[0m Run offline sandbox (no internet | restricted home)\033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• safe-net-run [bin]:\033[0m Run online sandbox  (with internet | restricted home)\033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="sec"
    '';
  };
}
