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

    # Binary caches — mirrors for reliable downloads
    substituters = [
      "https://cache.nixos.org"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # IPv6 disabled — not usable in Iran
  networking.enableIPv6 = false;

  # Kernel — latest stable
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "vm.swappiness" = 20;
    "vm.vfs_cache_pressure" = 50;
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
    vazirmatn
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    gh
    pciutils
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

  # Power button & lid switch handling
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
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
