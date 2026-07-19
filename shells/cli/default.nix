# ==============================================================================
# ADVANCED CLI DEVSHELL — On-Demand Analytical & Heavy CLI Tooling
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "cli-env";

    packages = with pkgs; [
      # Structural Search & Refactoring
      ast-grep           # AST-based structural code search & refactoring

      # Benchmarking & Watching
      hyperfine          # High-precision command-line benchmarking
      watchexec          # Execute commands when monitored files change

      # Code Analysis & Inspection
      tokei              # Fast codebase statistics & line counters
      hexyl              # Colorful and readable hex viewer
      dasel              # Query and edit JSON/YAML/TOML/XML structures
      grex               # Auto-generate regex patterns from sample text

      # Process & Network Profiling
      procs              # Modern ps alternative with process tree & filtering
      bandwhich          # Real-time per-process and per-connection bandwidth
    ];

    shellHook = ''
      echo -e "\033[1;36m[⚡ CLI Environment Loaded]: \033[1;32mast-grep, hyperfine, tokei, watchexec, bandwhich\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="cli"
    '';
  };
}
