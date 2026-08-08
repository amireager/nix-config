{
  pkgs,
  inputs,
  ...
}: {
  # ============================================================
  # DESKTOP — Wayland / Niri / Noctalia
  # ============================================================

  # Niri compositor
  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri;
  };

  # Services: Display Manager, Audio, Bluetooth, GVFS
  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "catppuccin-mocha-mauve";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    blueman.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  # Graphics & Hardware Video Acceleration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva
        libva-utils
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        libva
      ];
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # XDG Portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Thunar
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [thunar-archive-plugin thunar-volman];
  };

  # Wayland environment variables
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland";
      AVALONIA_PLATFORM = "Wayland";
    };

    systemPackages = with pkgs; [
      wayland-utils
      glib
      gsettings-desktop-schemas

      # Catppuccin SDDM dark theme — matches system Catppuccin Mocha
      (pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        accent = "mauve";
        font = "JetBrainsMono Nerd Font";
        fontSize = "10";
        # background = "${../../backgrounds/sddm-dark.png}";
        loginBackground = true;
      })
    ];
  };
}
