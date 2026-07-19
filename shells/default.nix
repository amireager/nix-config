# ==============================================================================
# DEVSHELLS REGISTRY — Central Hub for Modular On-Demand Environments
# ==============================================================================
{
  inputs,
  pkgs,
  system ? "x86_64-linux",
  ...
}: let
  pythonShell = import ./python {inherit pkgs;};
  nixShell = import ./nix {inherit pkgs;};
  cliShell = import ./cli {inherit pkgs;};
  secShell = import ./sec {inherit pkgs;};
in {
  # Default environment triggered by running `dev` without args or `nix develop`
  default = nixShell.default;

  # Named environments for quick invocation (`dev python`, `dev sec`, etc.)
  python = pythonShell.default;
  nix = nixShell.default;
  cli = cliShell.default;
  sec = secShell.default;
}
