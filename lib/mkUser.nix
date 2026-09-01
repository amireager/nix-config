# ==============================================================================
# mkUser — lightweight factory for NixOS user accounts (the NixOS side only).
# ==============================================================================
# Builds the `users.users.<name>` / `users.groups.<name>` / `programs.fish`
# module for a user. Keep it small on purpose:
#
#   * Only the NixOS-side user definition lives here.
#   * Home-manager modules are NOT touched — the user picks those in their own
#     `home.nix` so they keep full control (user-driven). This file is about
#     de-duplicating `users.users.*` boilerplate, not about choosing software.
#
# It carries no host/server/architecture assumptions, so it is safe to use for
# the current laptop and for any user added later.
#
# Usage (in a user's `default.nix`):
#
#   import ../../lib/mkUser.nix {
#     name = "amir";
#     isAdmin = true;               # adds `wheel` (sudo-rs execWheelOnly)
#     extraGroups = [ "podman" ];  # additional supplementary groups
#   }
{
  name,
  isAdmin ? false,
  extraGroups ? [],
  ...
}: {
  pkgs,
  lib,
  ...
}: let
  # Safe, conventional base groups for a normal desktop user.
  baseGroups = ["networkmanager" "video" "audio"];
  adminGroups = lib.optionals isAdmin ["wheel"];
in {
  users.users.${name} = {
    isNormalUser = true;
    group = name;
    extraGroups = baseGroups ++ adminGroups ++ extraGroups;
    shell = pkgs.fish;
    # Keep the login password mutable and manage it explicitly with `passwd`.
  };

  users.groups.${name} = {};
  programs.fish.enable = true;
}
