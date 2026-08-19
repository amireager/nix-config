# ============================================================
# KEYD — Kernel-level CapsLock tap/hold remapping
# ============================================================
_: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings.main = {
          # Tap = Escape; hold = Meta/Super for Niri's Mod shortcuts.
          capslock = "overload(meta, esc)";
        };
      };
    };
  };
}
