# ============================================================
# KEYD — Kernel-level Key Remapper Daemon (CapsLock Navigation)
# ============================================================
{...}: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            # Tap = Escape, Hold = Navigation Layer (Vim motion & scrolling)
            capslock = "overload(navigation, esc)";
          };

          navigation = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            u = "pageup";
            d = "pagedown";
          };
        };
      };
    };
  };
}
