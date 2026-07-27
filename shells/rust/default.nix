{mkDevShell, pkgs, ...}:
mkDevShell {
  name = "rust";
  icon = "🦀";
  description = "Cargo, Rust-Analyzer, Clippy";

  packages = with pkgs; [
    # Core Rust toolchain
    cargo
    rustc
    rust-analyzer
    clippy
    rustfmt

    # Standard build dependencies for common crates
    pkg-config
    openssl
  ];

  env.RUST_BACKTRACE = "1";

  tips = [
    {key = "Check & Lint"; cmd = "cargo check / cargo clippy";}
    {key = "Build & Run"; cmd = "cargo build / cargo run";}
    {key = "Format"; cmd = "cargo fmt";}
  ];
}
