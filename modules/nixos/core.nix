{
  pkgs,
  flakePath,
  ...
}: {
  # ============================================================
  # CORE SYSTEM — NixOS Foundation
  # ============================================================

  # === Nixpkgs ===
  nixpkgs.config.allowUnfree = true;

  # === Nix Settings ===
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];

      # Allow admin users to use trusted Nix features and binary caches.
      trusted-users = ["root" "@wheel"];

      # Binary caches — only signed caches.
      substituters = [
        "https://cache.nixos.org"
        "https://niri.cachix.org"
        "https://noctalia.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  # === Firmware ===
  # AMD microcode and common Wi-Fi/audio/Bluetooth blobs. Non-redistributable
  # extras stay out until a device actually needs them.
  hardware.enableRedistributableFirmware = true;

  # AppImage support and user mounts rely on FUSE independent of the selected
  # kernel/performance policy.
  boot.kernelModules = ["fuse"];

  # === Services ===
  services = {
    journald.extraConfig = ''
      SystemMaxUse=250M
      SystemMaxFileSize=50M
      MaxRetentionSec=1month
    '';

    # Keyboard layout — US + Persian, toggle with Alt+Shift.
    xserver.xkb = {
      layout = "us,ir";
      options = "grp:alt_shift_toggle";
    };
  };

  # === Locale & Timezone ===
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";

  # === Fonts & Typography ===
  fonts = {
    packages = with pkgs; [
      # Latin
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      inter

      # Persian
      # Vazirmatn is the better UI face, Sahel is noticeably heavier and so
      # reads better as terminal fallback — see the note under fontconfig.
      vazirmatn
      sahel-fonts
      samim-fonts

      # Coverage
      noto-fonts
      noto-fonts-cjk-sans
      twitter-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        # No true Persian monospace exists — Vazir Code was discontinued and
        # is not in nixpkgs. Every Persian face here is proportional, so the
        # terminal squeezes it into fixed cells and thin weights come out
        # hollow. Sahel is the heaviest of the maintained families, which is
        # why it leads the monospace fallback rather than Vazirmatn.
        monospace = [
          "JetBrainsMono Nerd Font"
          "Sahel"
          "Vazirmatn"
          "Noto Sans Mono"
        ];
        sansSerif = ["Inter" "Vazirmatn" "Noto Sans"];
        serif = ["Noto Serif" "Vazirmatn"];
        emoji = ["Twitter Color Emoji"];
      };

      # No global matrix scaling here on purpose. An earlier version scaled
      # Sahel 1.15x at the fontconfig level, which applied everywhere — GTK,
      # the browser, the editor — and compounded with the per-font `scale`
      # WezTerm already applies, leaving Latin looking small next to it.
      # Size matching belongs in the terminal config, where the cell grid is.
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Hinting and antialiasing matter more for Persian than Latin:
               the strokes are thinner and the curves tighter. -->
          <match target="font">
            <edit name="antialias" mode="assign"><bool>true</bool></edit>
            <edit name="hinting" mode="assign"><bool>true</bool></edit>
            <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
            <edit name="rgba" mode="assign"><const>rgb</const></edit>
            <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
            <edit name="autohint" mode="assign"><bool>false</bool></edit>
          </match>

          <!-- Persian text should never fall back to a Latin-only face. -->
          <match target="pattern">
            <test name="lang" compare="contains"><string>fa</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sahel</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };

  # === Essential System Packages ===
  environment.systemPackages = with pkgs; [
    vim
    git
    pciutils
    usbutils
    lshw
    dmidecode
    smartmontools
    nvme-cli
    efibootmgr
    lm_sensors
  ];

  # === Programs & CLI Wrappers ===
  programs = {
    # NH — NixOS Management Wrapper
    nh = {
      enable = true;
      flake = flakePath;
      clean = {
        enable = true;
        extraArgs = "--keep-since 10d --keep 10";
      };
    };

    # AppImage Support
    appimage = {
      enable = true;
      binfmt = true;
    };

    # Dynamic Libraries (NixLD)
    nix-ld.enable = true;

    # A typo is a typo
    command-not-found.enable = false;
  };
}
