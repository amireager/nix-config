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

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

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
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    AVALONIA_PLATFORM = "Wayland";
  };

  environment.systemPackages = with pkgs; [
    wayland-utils
    glib
    gsettings-desktop-schemas
  ];
}
