{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "cli";
  icon = "⚡";
  description = "Analytics, profiling & inspection tooling";

  packages = with pkgs; [
    # Structural search & refactoring
    ast-grep # AST-based structural code search & refactoring
    difftastic # Structural/semantic diff

    # Benchmarking & execution watching
    hyperfine # High-precision command-line benchmarking
    watchexec # Run commands when files change

    # Code analysis & inspection
    tokei # Fast codebase statistics
    hexyl # Colorful hex viewer
    dasel # Query/edit JSON, YAML, TOML, XML
    grex # Generate regex from examples
    erdtree # Modern tree + disk usage analyzer

    # Process & network profiling
    procs # Modern ps with tree & filtering
    bandwhich # Per-process bandwidth in real time

    # Data & log exploration
    fx # Interactive JSON explorer
    jc # Convert command output to JSON
    jless # Interactive JSON pager
    tailspin # Log viewer with syntax highlighting
    pueue # Background job manager

    # Git & GitHub workflows
    gh-dash # GitHub PR/issue dashboard (TUI)

    # File management
    superfile # TUI file manager (yazi stays at system level)

    # Transfer & sync
    rclone # Cloud & remote sync
    magic-wormhole # Secure P2P file transfer

    nvtopPackages.full
    ncdu
  ];

  tips = [
    {
      key = "Profiling";
      cmd = "hyperfine / bandwhich / procs";
    }
    {
      key = "Data";
      cmd = "fx / dasel / jless / jc";
    }
    {
      key = "Code search";
      cmd = "ast-grep / tokei / difft";
    }
  ];
}
