# ==============================================================================
# USER TEMPLATE — copy this directory to users/<username>/ and customize.
# ==============================================================================
# The NixOS-side user is created via `mkUser` (lib/mkUser.nix). To add a user:
#
#   cp -r users/_template users/<username>
#   # then edit the `name` in the mkUser call below and the module imports in
#   # ./home.nix (which stay under the user's control).
#
# Options for mkUser:
#   isAdmin     -> adds the `wheel` group (sudo-rs execWheelOnly)
#   extraGroups -> list of additional supplementary groups
import ../../lib/mkUser.nix {
  name = "username";
  isAdmin = false;
  # extraGroups = [ "podman" ];
}
