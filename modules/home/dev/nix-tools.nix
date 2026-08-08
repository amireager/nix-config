{pkgs, ...}: {
  # ============================================================================
  # NIX TOOLING — System Level
  # ============================================================================
  # Only tools that must be available *outside* a project checkout live here.
  # Rule of thumb: if you reach for it while something is already broken,
  # it belongs at system level. Everything else lives in `shells/nix`.
  # ============================================================================

  # ── nix-index-database ──
  # Provides a pre-built file->package index (rebuilt daily upstream), so
  # `comma` and `nix-locate` work instantly instead of requiring a ~10 min
  # local `nix-index` run. The HM module installs `comma-with-db` for us,
  # which is why plain `comma` / `nix-index` are NOT in home.packages below.
  programs.nix-index = {
    enable = true;

    # false — and this is the whole point of the option.
    #
    # The integration is not "nix-index is available in fish". It installs a
    # fish_command_not_found handler, so every typo becomes a database search:
    #
    #     $ caler
    #     (pause while nix-locate walks the index)
    #
    # For a typo that is the wrong answer twice over. It is slow, and it
    # answers a question that was not asked — `clear` was misspelled, no
    # package needs installing. The useful case, "which package provides this
    # binary", is a thing you go and ask for deliberately:
    #
    #     nix-locate --minimal --whole-name bin/rg     which package has it
    #     , rg                                          run it once, no install
    #
    # Both still work. Only the automatic hijack of every failed command is
    # gone, and fish falls back to its own handler: "Unknown command: caler".
    enableFishIntegration = false;

    # The DB is fetched as a flake input; no local indexing, no stale cache.
    symlinkToCacheHome = true;
  };
  programs.nix-index-database.comma.enable = true;

  home.packages = with pkgs; [
    # === Inspection & Debugging (always available on purpose) ===
    nix-tree # Interactive dependency tree explorer
    nix-diff # Explain *why* two derivations differ / why a rebuild happened
    nix-du # Which store paths actually consume disk
    nix-melt # TUI viewer for flake.lock
    nix-output-monitor # Readable build output with progress

    # === Nix code QA — kept at system level by explicit choice ===
    # These are used constantly while editing config, including on files
    # outside this repo, so paying for them globally is the right trade.
    statix # Anti-pattern linter
    deadnix # Dead code detector
    alejandra # Formatter (matches flake.formatter)

    # === Editor integration ===
    nixd # LSP — must work in any .nix file, not just inside a project

    # === Global Dev CLI ===
    # The `dev` launcher and its completions live in ./dev-launcher.nix — it is
    # a hundred lines of shell and does not belong in a package list.
  ];
}
