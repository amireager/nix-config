{pkgs, ...}: {
  users.users.amir = {
    isNormalUser = true;
    group = "amir";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "podman"];
    shell = pkgs.fish;
    # Set a password via `passwd` after first install, or use sops-nix here later.
  };

  users.groups.amir = {};
  programs.fish.enable = true;
}
