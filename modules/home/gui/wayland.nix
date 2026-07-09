{pkgs, ...}: {
  home.packages = with pkgs; [
    grim
    slurp
    wl-screenrec
    brightnessctl
    pamixer
    bluetui
    wl-clipboard
  ];
}
