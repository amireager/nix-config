{pkgs, ...}: {
  users.users.amir = {
    isNormalUser = true;
    group = "amir";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "podman"];
    shell = pkgs.fish;
    # Keep the login password mutable and manage it explicitly with `passwd`.
  };

  users.groups.amir = {};
  programs.fish.enable = true;
}
