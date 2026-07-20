# ==============================================================================
# ADVANCED CLI DEVSHELL — On-Demand Analytical & Specialized CLI Tooling
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "cli-env";

    packages = with pkgs; [
      # Structural Search & Code Refactoring
      ast-grep # AST-based structural code search & refactoring
      difftastic # Structural/semantic diff tool
      htop

      # Benchmarking & Execution Watching
      hyperfine # High-precision command-line benchmarking
      watchexec # Execute commands when monitored files change

      # Code Analysis & Inspection
      tokei # Fast codebase statistics & line counters
      hexyl # Colorful and readable hex viewer
      dasel # Query and edit JSON/YAML/TOML/XML structures
      grex # Auto-generate regex patterns from sample text
      erdtree # Modern fast tree and disk usage analyzer

      # Process & Network Profiling
      procs # Modern ps alternative with process tree & filtering
      bandwhich # Real-time per-process and per-connection bandwidth

      # Data & Log Exploration
      fx # Interactive JSON explorer
      jc # Convert command outputs to JSON
      jless # Interactive pager for JSON
      tailspin # Smart log viewer with syntax highlighting
      pueue # Long-running task and background job manager

      # File Transfer & Sync
      rclone # Cloud & server synchronization
      magic-wormhole # Secure P2P file transfer
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;33m⚡ Advanced CLI Tooling Shell (Analytics & Inspection)     \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Profiling & Logs:\033[0m bandwhich / procs / tailspin / hyperfine  \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;32m• Data Processing :\033[0m fx / dasel / jless / jc / ast-grep        \033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"

      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="cli"
    '';
  };
}
