{mkDevShell, pkgs, ...}:
mkDevShell {
  name = "build";
  icon = "🛠️";
  description = "GCC, Clang, CMake, Make, Ninja";

  packages = with pkgs; [
    # C/C++ compilers & build tools
    gcc
    clang
    cmake
    gnumake
    ninja
    pkg-config

    # Standard development libraries
    openssl
    zlib
    libiconv

    # Rust & Python helpers for multi-language build scripts
    cargo
    rustc
    python3

    # Debuggers. lldb drags in libclang (~849 MiB together), which is why it
    # lives here rather than beside Neovim — direnv attaches it on entering
    # the project.
    lldb # provides lldb-dap, the adapter nvim talks to
    gdb # fallback where lldb struggles
  ];

  tips = [
    {key = "CMake"; cmd = "cmake -B build && cmake --build build";}
    {key = "Make / Cargo"; cmd = "make / cargo build --release";}
  ];
}
