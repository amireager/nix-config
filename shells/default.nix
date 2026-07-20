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
  rustShell = import ./rust {inherit pkgs;};
  goShell = import ./go {inherit pkgs;};
  cliShell = import ./cli {inherit pkgs;};
  buildShell = import ./build {inherit pkgs;};
  secShell = import ./sec {inherit pkgs;};
  nixShell = import ./nix {inherit pkgs;};
in {
  # Default environment triggered by running `dev` without args or `nix develop`
  default = nixShell.default;

  # Named environments for quick invocation (`dev python`, `dev rust`, `dev sec`, etc.)
  python = pythonShell.default;
  rust = rustShell.default;
  go = goShell.default;
  cli = cliShell.default;
  build = buildShell.default;
  c = buildShell.default; # Alias `dev c` -> `dev build`
  sec = secShell.default;
  nix = nixShell.default;

  # Composite multi-environment shell (`dev py-rust`) containing both Python and Rust
  py-rust = pkgs.mkShell {
    name = "py-rust-env";
    inputsFrom = [pythonShell.default rustShell.default];
    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;35m🚀 Composite DevShell Loaded: Python + Rust Toolchains     \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="py-rust"
    '';
  };
}
