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
    substituters = [
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "vm.swappiness" = 20;
    "vm.vfs_cache_pressure" = 50;
  };

  # ZRAM swap
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Locale
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb = {
    layout = "us,ir";
    options = "grp:alt_shift_toggle";
  };

  # Fonts
  fonts.packages = with pkgs; [
    vazirmatn
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    gh
    pciutils
  ];

  # NH: modern NixOS management
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  # Environment variables
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

  system.stateVersion = "26.05";
}
