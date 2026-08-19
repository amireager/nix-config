# ==============================================================================
# BOX — Global sandbox launcher
# ==============================================================================
# `box` must be available both outside and inside every devShell so it can
# inherit the caller's exact PATH. Its runtime, packaging and completions live
# together in this directory; the sandbox behaviour remains in ./box.sh.
# ==============================================================================
{
  pkgs,
  proxy,
  ...
}: let
  port = toString proxy.port;
  replacePort = builtins.replaceStrings ["@proxyPort@"] [port];

  box = pkgs.writeShellApplication {
    name = "box";

    runtimeInputs = with pkgs; [
      bubblewrap
      coreutils
      findutils
      gnugrep
      gnused
      lsof
      strace
    ];

    # Tilde-prefix rewriting is deliberate for explicit host share/work paths.
    excludeShellChecks = ["SC2295"];

    text = replacePort (builtins.readFile ./box.sh);
  };

  completions = pkgs.runCommand "box-completions" {} ''
    install -Dm444 ${pkgs.writeText "box.fish" (replacePort (builtins.readFile ./completions/box.fish))} \
      $out/share/fish/vendor_completions.d/box.fish
    install -Dm444 ${./completions/box.bash} \
      $out/share/bash-completion/completions/box
    install -Dm444 ${pkgs.writeText "_box" (replacePort (builtins.readFile ./completions/_box))} \
      $out/share/zsh/site-functions/_box
  '';
in {
  home.packages = [box completions];
}
