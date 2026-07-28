# ==============================================================================
# mkDevShell — the shell equivalent of mkHost
# ==============================================================================
# Every devShell in this repo used to hand-roll the same three things:
#   1. `name = "<x>-env"`
#   2. a box-drawing banner built from raw ANSI escapes
#   3. `export DEVSHELL_ACTIVE` / `DEVSHELL_NAME`
# That was ~30% of every shell file, duplicated 11 times, and the box had to
# be re-aligned by hand whenever a line of text changed.
#
# This builder takes the *data* (name, icon, tips) and generates the rest.
#
# ── Usage ─────────────────────────────────────────────────────────────────
#   mkDevShell {
#     name        = "rust";
#     icon        = "🦀";
#     description = "Cargo, Rust-Analyzer, Clippy";
#     packages    = with pkgs; [ cargo rustc ];
#     env.RUST_BACKTRACE = "1";
#     tips = [
#       { key = "Check & Lint"; cmd = "cargo clippy"; }
#     ];
#     extraHook = ''...'';   # only when real logic is needed
#   }
#
# ── Escape hatch ──────────────────────────────────────────────────────────
# Nothing forces you through this builder. A shell may still be a plain
# `pkgs.mkShell { ... }`; the registry in shells/default.nix does not care.
# See the header of shells/_template/default.nix for the raw pattern.
# ==============================================================================
{pkgs}: {
  # Short identifier. Becomes `dev <name>` and the derivation name "<name>-env".
  name,
  # Emoji or short glyph shown at the start of the banner title.
  icon ? "📦",
  # One-line summary shown next to the icon.
  description ? "",
  # Packages available inside the shell.
  packages ? [],
  # Extra build inputs inherited from other derivations.
  inputsFrom ? [],
  # Environment variables, e.g. { RUST_BACKTRACE = "1"; }
  env ? {},
  # Banner hint rows: [ { key = "Build"; cmd = "cargo build"; } ]
  tips ? [],
  # Footer notes printed under the box, one per line.
  notes ? [],
  # Arbitrary shell code appended after the banner. Use only for real logic
  # (e.g. activating a virtualenv), never for decoration.
  extraHook ? "",
}: let
  inherit (pkgs) lib;

  # ── Tip alignment ─────────────────────────────────────────────────────────
  # Keys are ASCII, so stringLength is a safe proxy for display width here.
  keyWidth = lib.foldl' (acc: t: lib.max acc (lib.stringLength t.key)) 0 tips;
  padTo = w: s: s + lib.concatStrings (lib.genList (_: " ") (w - lib.stringLength s));

  titleText =
    "${icon}  ${name}"
    + lib.optionalString (description != "") "  —  ${description}";

  bashArray = name': items:
    "${name'}=(" + lib.concatMapStringsSep " " (i: lib.escapeShellArg i) items + ")";

  # ── Banner ────────────────────────────────────────────────────────────────
  # Deliberately NOT a closed box.
  #
  # The previous design drew ╭──╮ / │ … │ / ╰──╯ and had to pad every line to
  # an identical display width. That is not solvable in a portable way:
  #   • builtins.stringLength counts UTF-8 bytes, so "🦀" scores 4;
  #   • printf '%*s' also pads by bytes;
  #   • `wc -L` needs a UTF-8 locale and still disagrees with real terminals
  #     about emoji carrying a variation selector (🛡️ measures 1, renders 2).
  # Any of those being off by one leaves a visibly crooked frame.
  #
  # An open left-rule layout carries the same information, cannot go crooked,
  # and survives narrow terminals and line wrapping.
  banner = ''
    _ds_banner() {
      # Stay silent when asked, or when stdout is not a terminal — that covers
      # direnv, CI and `nix develop --command <one-shot>`.
      [ -n "''${DEVSHELL_QUIET:-}" ] && return 0
      [ -t 1 ] || return 0

      # Colours via printf rather than bash ANSI-C quoting: that syntax puts
      # two single quotes side by side, which Nix reads as the end of this
      # indented string.
      local ESC C T K D R
      ESC=$(printf "\033")
      C="$ESC[1;36m" # frame
      T="$ESC[1;35m" # title
      K="$ESC[1;33m" # keys
      D="$ESC[1;30m" # dim
      R="$ESC[0m"

      local title=${lib.escapeShellArg titleText}
      ${bashArray "local keys" (map (t: padTo keyWidth t.key) tips)}
      ${bashArray "local cmds" (map (t: t.cmd) tips)}
      ${bashArray "local notes" notes}

      local i
      printf '%s┌─%s %s%s\n' "$C" "$R" "$T$title" "$R"
      for i in "''${!keys[@]}"; do
        printf '%s│%s  %s%s%s  %s\n' "$C" "$R" "$K" "''${keys[$i]}" "$R" "''${cmds[$i]}"
      done
      printf '%s└─%s\n' "$C" "$R"
      for i in "''${!notes[@]}"; do printf '   %b%b%b\n' "$D" "''${notes[$i]}" "$R"; done
    }

    _ds_banner
    unset -f _ds_banner
  '';
  # `env` is merged with //, so a stray key would silently clobber the
  # builder's own attributes and produce a confusing failure far from here.
  reserved = ["name" "packages" "inputsFrom" "shellHook"];
  clashes = lib.intersectLists reserved (lib.attrNames env);
in
  assert lib.assertMsg (clashes == []) ''
    mkDevShell (${name}): `env` may not contain ${lib.concatStringsSep ", " clashes}.
    Use the dedicated argument instead of passing it through `env`.
  '';
  # passthru carries the description out of the derivation so that the `dev`
  # launcher can build its menu from the shells themselves. Without this the
  # menu is a hand-written list that silently goes stale every time a shell is
  # added or renamed — which is exactly what happened to `box` and `sec`.
    (pkgs.mkShell ({
        name = "${name}-env";
        inherit packages inputsFrom;

        shellHook = ''
          export DEVSHELL_ACTIVE="true"
          export DEVSHELL_NAME=${lib.escapeShellArg name}

          ${banner}
          ${extraHook}
        '';
      }
      // env))
    .overrideAttrs (old: {
      passthru =
        (old.passthru or {})
        // {
          devShellMeta = {inherit name icon description;};
        };
    })
