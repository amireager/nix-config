{
  pkgs,
  flakePath,
  ...
}: {
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
    enableFishIntegration = true;
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

    # === Global Dev CLI — launcher for the centralized on-demand shells ===
    (writeShellScriptBin "dev" ''
      FLAKE_PATH="''${NIX_CONFIG_FLAKE:-${flakePath}}"
      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        for candidate in "$HOME/nix-config" "$HOME/projects/nix-config" "/etc/nixos"; do
          if [ -f "$candidate/flake.nix" ]; then
            FLAKE_PATH="$candidate"
            break
          fi
        done
      fi

      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        echo "dev: no flake.nix found (tried $FLAKE_PATH, ~/nix-config, ~/projects/nix-config, /etc/nixos)" >&2
        echo "dev: set NIX_CONFIG_FLAKE=/path/to/nix-config to override" >&2
        exit 1
      fi

      # Resolve symlinks (/etc/nixos is usually a link to the real checkout).
      # Without this the same repo can be evaluated under two different paths,
      # producing duplicate evaluations and duplicate GC roots.
      FLAKE_PATH="$(cd "$FLAKE_PATH" && pwd -P)"

      if [ $# -eq 0 ]; then
        echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
        echo -e "\033[1;36m│ \033[1;35m🚀 On-Demand DevShell Manager                            \033[1;36m│\033[0m"
        echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
        echo -e "\033[1;36m💡 Usage: dev <environment> [command/task...]\033[0m"
        echo -e "\033[1;33m📦 Environments in $FLAKE_PATH:\033[0m"
        echo

        # The menu is generated from devShellsMeta, which mkDevShell fills in
        # for every shell. Adding a shell updates this list automatically —
        # the hand-written version went stale every single time (box was
        # missing, sec still advertised tools it no longer had).
        #
        # Nix emits plain JSON here and jq does the formatting: keeping the
        # presentation logic in bash avoids a fragile Nix expression nested
        # inside a shell string inside a Nix string.
        if META="$(nix eval --json \
              "$FLAKE_PATH#devShells.${system}.devShellsMeta" 2>/dev/null)"; then
          printf '%s' "$META" | ${pkgs.jq}/bin/jq -r '
            (.shells + .extra) as $all
            | ( .groups[]
              | "  [ \(.title) ]",
                ( .members[]
                  | select($all[.] != null)
                  | "  \($all[.].icon // "📦")  dev \(. + "            "
                      | .[0:12])  \($all[.].description // "")"
                ),
                ""
              ),
              ( ($all | keys) - ([.groups[].members] | flatten) ) as $rest
              | select(($rest | length) > 0)
              | "  [ Other ]",
                ( $rest[] | "  \($all[.].icon // "📦")  dev \(. + "            " | .[0:12])  \($all[.].description // "")" ),
                ""
          '
          printf '%s' "$META" | ${pkgs.jq}/bin/jq -r '
            "  aliases: " + ([.aliases | to_entries[] | "dev \(.key) → dev \(.value)"] | join(", "))
          '
        else
          # Fallback when metadata cannot be evaluated (older checkout, or an
          # error in the flake): list directories rather than printing nothing.
          echo "  (metadata unavailable — listing shell directories)"
          for d in "$FLAKE_PATH"/shells/*/; do
            n="$(basename "$d")"
            case "$n" in _*) continue ;; esac
            echo "  - dev $n"
          done
        fi
        exit 0
      fi

      ENV_NAME="$1"
      shift

      mkdir -p "$HOME/.local/share/dev-roots"
      ROOT_PROFILE="$HOME/.local/share/dev-roots/$ENV_NAME-profile"

      # The GC root is registered AFTER the shell exits, not concurrently with
      # it. Running `nix print-dev-env` in the background while `nix develop`
      # evaluates makes both processes write to the same eval cache, which
      # produces:
      #   error (ignored): SQLite database '…/eval-cache-v6/….sqlite' is busy
      # Harmless, but it printed on every single `dev` invocation. Sequencing
      # them removes the contention, and by then the evaluation is cached so
      # registering the root is nearly instant.
      _register_root() {
        nix print-dev-env "$FLAKE_PATH#$ENV_NAME" \
          --profile "$ROOT_PROFILE" >/dev/null 2>&1 || true
      }

      if [ $# -eq 0 ]; then
        echo -e "\033[1;32m⏳ Evaluating & launching On-Demand DevShell: \033[1;36m$ENV_NAME \033[1;32m(Default shell: Fish)\033[0m"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command fish
        STATUS=$?
        _register_root
        exit $STATUS
      else
        echo -e "\033[1;32m⚡ Executing task inside On-Demand DevShell \033[1;36m$ENV_NAME\033[1;32m: \033[1;33m$*\033[0m"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command fish -c "$*"
        STATUS=$?
        _register_root
        exit $STATUS
      fi
    '')
  ];
}
