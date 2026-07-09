{inputs}: let
  mkHost = import ./mkHost.nix {inherit inputs;};
in {
  inherit mkHost;
}
