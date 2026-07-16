# Copy this directory to users/<username>/ and customize.
{pkgs, ...}: {
  users.users.username = {
    isNormalUser = true;
    group = "username";
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    shell = pkgs.fish;
  };

  users.groups.username = {};
  programs.fish.enable = true;
}
