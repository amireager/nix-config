{inputs}: rec {
  # Single source of truth for the local SOCKS proxy.
  # Change `port` here; proxychains, fish, box and session env follow.
  proxy = {
    host = "127.0.0.1";
    port = 1819;
  };

  mkHost = import ./mkHost.nix {inherit inputs proxy;};
  mkDevShellFor = pkgs: import ./mkDevShell.nix {inherit pkgs;};
}
