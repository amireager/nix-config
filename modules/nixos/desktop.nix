{
  pkgs,
  inputs,
  ...
}: {
  # ============================================================
  # DESKTOP — Wayland / Niri / Noctalia
  # ============================================================

  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri;
    # Niri already ships the GNOME screencast portal. Do not pull Nautilus
    # in solely as a file-chooser backend.
    useNautilus = false;
  };

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
      pulse.enable = true;
    };

    blueman.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  hardware = {
    graphics.enable = true;

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-gtk];
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [thunar-archive-plugin thunar-volman];
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      AVALONIA_PLATFORM = "Wayland";
    };

    systemPackages = with pkgs; [
      wayland-utils
      libva-utils
      glib
      gsettings-desktop-schemas

      (catppuccin-sddm.override {
        flavor = "mocha";
        accent = "mauve";
        font = "JetBrainsMono Nerd Font";
        fontSize = "10";
        loginBackground = true;
      })
    ];
  };
}
