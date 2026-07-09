{pkgs, ...}: {
  # Thunar needs system D-Bus for mounting/trash — can't be purely HM-managed
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [thunar-archive-plugin thunar-volman];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;
}
