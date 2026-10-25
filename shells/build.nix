{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "build";
  icon = "🛠️";
  description = "GCC, Clang, CMake, Make, Ninja";

  packages = with pkgs; [
    # C/C++ compilers & build tools
    gcc
    clang
    clang-tools # clangd (Neovim LSP), clang-format, clang-tidy; adds ~200 MiB to this shell only
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

    # Low-level introspection for native debugging/profiling.
    # (Only for headless/native work; the day-to-day nvim flow uses lldb-dap.)
    strace # Syscall tracing
    valgrind # Memory/leak detection & profiling
    gdbgui # Browser-based gdb UI (optional; gdb already present)
  ];

  tips = [
    {
      key = "CMake";
      cmd = "cmake -B build && cmake --build build";
    }
    {
      key = "Make / Cargo";
      cmd = "make / cargo build --release";
    }
    {
      key = "clangd index";
      cmd = "cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ln -sf build/compile_commands.json .";
    }
  ];
}
