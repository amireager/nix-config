# ==============================================================================
# SECURITY SHELL — ابزارهای منحصربه‌فرد (تکرار fj/fjx نمی‌کنه)
# ==============================================================================
# safe-crypt  gocryptfs volume manager (~/pub/crypt/)
# safe-test   podman container برای تست اسکریپت ناشناس
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "sec-env";

    packages = with pkgs; [
      bubblewrap
      firejail

      # ── 1. safe-crypt: gocryptfs volume manager ──
      (pkgs.writeShellScriptBin "safe-crypt" ''
        set -eu
        C="$HOME/pub/crypt"
        _h() { echo "Usage: safe-crypt init|mount|umount|list <name>"; exit 0; }
        [ $# -ge 1 ] || _h
        a="$1"; n="''${2:-}"
        case "$a" in
          init)  mkdir -p "$C/$n" "$C/$n.open" && ${pkgs.gocryptfs}/bin/gocryptfs -init "$C/$n" ;;
          mount) mkdir -p "$C/$n.open" && ${pkgs.gocryptfs}/bin/gocryptfs "$C/$n" "$C/$n.open" ;;
          umount) fusermount -u "$C/$n.open" 2>/dev/null || sudo umount "$C/$n.open" ;;
          list)  for d in "$C"/*/; do
                   [ -f "$d/gocryptfs.conf" ] || continue
                   n="$(basename "$d")"
                   mountpoint -q "$C/$n.open" && echo "  🔓 $n" || echo "  🔒 $n"
                 done ;;
          *) _h ;;
        esac
      '')

      # ── 2. safe-test: podman یکبار مصرف ──
      (pkgs.writeShellScriptBin "safe-test" ''
        set -eu
        [ $# -gt 0 ] || { echo "Usage: safe-test [--image img] <cmd>"; exit 1; }
        IMG="docker.io/library/alpine:latest"
        [ "''${1}" = "--image" ] && { IMG="''${2}"; shift 2; }
        ${pkgs.podman}/bin/podman run --rm -v "$(pwd)":/ws:ro -w /ws --name "st-$$" "$IMG" "$@"
      '')
    ];

    shellHook = ''
      echo -e "\033[1;36m╭──────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;32m🛡️  Security Shell            \033[1;36m│\033[0m"
      echo -e "\033[1;36m├──────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33msafe-crypt\033[0m  gocryptfs      \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33msafe-test\033[0m   podman         \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰──────────────────────────────╯\033[0m"
      echo -e "💡 For sandbox: \033[1;33mfj\033[0m <cmd>  or  \033[1;33mfjx\033[0m <cmd>"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="sec"
    '';
  };
}
