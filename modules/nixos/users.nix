{pkgs, ...}: {
  # Define the amir user at system level
  users.users.amir = {
    isNormalUser = true;
    group = "amir";
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    shell = pkgs.fish;
  };

  # Create user group
  users.groups.amir = {};

  # Enable fish shell globally (required for it to be a valid login shell)
  programs.fish.enable = true;
}
