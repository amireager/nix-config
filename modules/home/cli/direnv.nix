_: {
  # ============================================================
  # DIRENV — Automatic Shell Environment Switcher
  # ============================================================
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    silent = true;
  };
}
