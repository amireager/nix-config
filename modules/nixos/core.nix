{
  pkgs,
  inputs,
  flakePath,
  ...
}: {
  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    # Binary caches for niri and noctalia
    substituters = [
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Kernel — latest stable
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "vm.swappiness" = 20;          # prefer RAM over swap
    "vm.vfs_cache_pressure" = 50;  # keep filesystem metadata longer
  };

  # ZRAM — compressed swap in RAM
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Locale & timezone
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb = {
    layout = "us,ir";
    options = "grp:alt_shift_toggle";
  };

  # Fonts
  fonts.packages = with pkgs; [
    vazirmatn              # Persian font
    nerd-fonts.jetbrains-mono  # dev font with icons
    nerd-fonts.fira-code       # dev font with ligatures
  ];

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim          # terminal text editor
    git          # version control
    gh           # GitHub CLI
    pciutils     # lspci — hardware info
  ];

  # NH — modern NixOS management wrapper
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  # Wayland environment variables
  environment.sessionVariables = {
    AVALONIA_PLATFORM = "Wayland";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  boot.kernelModules = ["fuse"];

  # ⚠️ Set to your ACTUAL installed NixOS version — do NOT change after install
  system.stateVersion = "26.05";
}
