# ==============================================================================
# SECURITY & SANDBOX SHELL — Isolated Sandboxing for Untrusted Binaries & Scripts
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "sec-env";

    packages = with pkgs; [
      # Sandboxing Engines
      bubblewrap         # Lightweight, powerful user-space sandboxing tool
      firejail           # Application sandboxing with prebuilt security profiles

      # One-click isolated sandbox wrapper (Network Disabled & Restricted Home)
      (writeShellScriptBin "safe-run" ''
        if [ $# -eq 0 ]; then
          echo -e "\033[1;31mUsage: safe-run <untrusted-binary> [args...]\033[0m"
          echo "Runs the executable inside a Bubblewrap sandbox (Network disabled | Read-only system access)."
          exit 1
        fi

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
      '')

      (writeShellScriptBin "safe-net-run" ''
        if [ $# -eq 0 ]; then
          echo -e "\033[1;31mUsage: safe-net-run <untrusted-binary> [args...]\033[0m"
          exit 1
        fi
        echo -e "\033[1;33m🌐 Launching inside Bubblewrap Sandbox (Network ENABLED | Home Restricted to Current Dir)...\033[0m"
        exec ${bubblewrap}/bin/bwrap \
          --ro-bind /usr /usr \
          --ro-bind /nix /nix \
          --ro-bind /etc /etc \
          --proc /proc \
          --dev /dev \
          --bind . /home/$USER \
          "$@"
      '')
    ];

    shellHook = ''
      echo -e "\033[1;36m[🛡️ Security Sandbox Loaded]: \033[1;32mbubblewrap, firejail, safe-run, safe-net-run\033[0m"
      echo -e "\033[1;33m💡 Command 'safe-run ./executable' runs untrusted apps without network or personal file access.\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="sec"
    '';
  };
}
