# Dev tools
# NOTE: All CLI/dev tools are consolidated in ../cli/tools.nix
# Add dev-specific packages here only if they don't belong in the general CLI set.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Advanced search and code analysis
    ripgrep-all # Search inside PDFs, archives, documents, and more
    ast-grep # Structural code search and refactoring

    # File tree, binary, and text helpers
    erdtree # Fast tree viewer with disk usage support
    hexyl # Hex viewer
    grex # Regex generator from examples
    dasel # Query and edit JSON, YAML, TOML, XML, and CSV

    # Benchmarking, watching, and project metrics
    hyperfine # Command-line benchmarking
    watchexec # Run commands when files change
    tokei # Code statistics

    # GitHub and command workflow
    gh-dash # GitHub dashboard TUI
    navi # Interactive command cheatsheets

    # Extra network monitoring and diagnostics
    iotop # I/O monitoring
    nethogs # Bandwidth per process
    iftop # Bandwidth per connection
    nload # Realtime network throughput graph
    vnstat # Network traffic history
    iperf3 # Network throughput testing
    bmon # Bandwidth monitor TUI
    gping # Ping with terminal graph
    traceroute # Classic traceroute tool
    websocat # WebSocket client and relay

    # File transfer and cloud sync helpers
    rclone # Cloud and remote storage sync
    magic-wormhole # Simple encrypted file transfer between machines
  ];
}
