# ==============================================================================
# BUILD & COMPILATION SHELL — Specialized Environment for Testing & Compiling Repos
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "build-env";

    packages = with pkgs; [
      # C/C++ Compilers & Build Tools
      gcc
      clang
      cmake
      gnumake
      ninja
      pkg-config

      # Standard Development Libraries
      openssl
      zlib
      libiconv

      # Rust & Python Helpers (for multi-language build scripts)
      cargo
      rustc
      python3
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;35m🛠️ Build & Compile Shell (GCC, Clang, CMake, Make, Ninja)  \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• CMake Build:\033[0m mkdir build && cd build && cmake .. && make  \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Make/Cargo :\033[0m make / cargo build --release                 \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="build"
    '';
  };
}
