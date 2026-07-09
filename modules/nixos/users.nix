{pkgs, ...}: {
  users.users.amir = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    shell = pkgs.fish;
  };

  # Fish must be enabled at system level for it to be a valid login shell
  programs.fish.enable = true;
}
