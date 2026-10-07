{inputs}: rec {
  # Single source of truth for the local proxy contract: a mixed
  # HTTP+SOCKS listener on 127.0.0.1:1881, provided by the user's own
  # sing-box (started manually when needed — see docs/09-rules.md).
  # If the listener ever moves, change `port` here; proxychains, fish,
  # box and session env follow.
  proxy = {
    host = "127.0.0.1";
    port = 1881;
  };

  mkHost = import ./mkHost.nix {inherit inputs proxy;};
  mkDevShellFor = pkgs: import ./mkDevShell.nix {inherit pkgs;};
}
