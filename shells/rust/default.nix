# ==============================================================================
# RUST DEV SHELL — Specialized Rust Development Environment
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "rust-env";

    packages = with pkgs; [
      # Core Rust Toolchain
      cargo
      rustc
      rust-analyzer
      clippy
      rustfmt

      # Standard build dependencies for Rust crates
      pkg-config
      openssl
    ];

    RUST_BACKTRACE = "1";

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;33m🦀 Rust Development Shell (Cargo, Rust-Analyzer, Clippy)   \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Fast Check & Lint:\033[0m cargo check / cargo clippy            \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Build & Run      :\033[0m cargo build / cargo run               \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Format Code      :\033[0m cargo fmt                             \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="rust"
    '';
  };
}
