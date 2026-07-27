{inputs}: {
  # Host builder — composes hostModules + users + home-manager into a system.
  mkHost = import ./mkHost.nix {inherit inputs;};

  # DevShell builder — needs `pkgs`, so it is exposed as a function of pkgs
  # and applied inside shells/default.nix where a concrete pkgs exists.
  mkDevShellFor = pkgs: import ./mkDevShell.nix {inherit pkgs;};
}
