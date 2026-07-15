# lib/default.nix - Main entry point for library functions
{inputs}:
let
  mkHost = import ./mkHost.nix {inherit inputs;};
  mkUser = import ./mkUser.nix {inherit inputs;};
  helpers = import ./helpers.nix {lib = inputs.nixpkgs.lib;};
in
{
  inherit mkHost mkUser helpers;
}
