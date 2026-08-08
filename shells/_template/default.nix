{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# DEVSHELL TEMPLATE — copy this directory to create a new environment
# ==============================================================================
#   cp -r shells/_template shells/mynew
# then register it in shells/default.nix (two lines: the import and the attr).
#
# ── Why mkDevShell instead of pkgs.mkShell ────────────────────────────────
# Every shell here used to hand-roll the same banner, the same DEVSHELL_*
# exports and the same `name = "x-env"`. That was roughly 30% of each file,
# duplicated 11 times, and the ASCII box had to be re-aligned by hand every
# time a line of text changed. mkDevShell takes the data and generates the
# rest, measuring the box at runtime so emoji do not break the alignment.
#
# ── Escape hatch ──────────────────────────────────────────────────────────
# Nothing forces you through this builder. A shell may still be a plain
# `pkgs.mkShell { ... }` — the registry in shells/default.nix does not care
# what a directory returns, as long as it is a derivation.
#
# For the original raw-mkShell reference template, see git history:
#
#   git log --oneline -- shells/_template/default.nix
#   git show <commit-before-mkDevShell>:shells/_template/default.nix
#
# ==============================================================================
mkDevShell {
  # ── Required ──────────────────────────────────────────────────────────────
  # Short identifier. Drives `dev <name>`, the derivation name "<name>-env",
  # and $DEVSHELL_NAME inside the shell.
  name = "example";

  # ── Banner ────────────────────────────────────────────────────────────────
  icon = "🚀"; # single glyph shown before the title
  description = "What this environment is for"; # one-line summary

  # Hint rows rendered inside the box. Keys are auto-aligned; the box width
  # is computed from the longest row, so you never count spaces again.
  tips = [
    {
      key = "Run";
      cmd = "hello-dev";
    }
    {
      key = "Docs";
      cmd = "man example";
    }
  ];

  # Free-form lines printed under the box (already outside the frame).
  notes = ["Anything worth saying that is not a command"];

  # ── Contents ──────────────────────────────────────────────────────────────
  # Tools available only inside this shell. On exit they leave $PATH.
  packages = with pkgs; [
    git
    curl
    jq

    # A script that exists only within this environment
    (writeShellScriptBin "hello-dev" ''
      echo "Hello from the sandboxed dev environment!"
    '')
  ];

  # Inherit build dependencies of other derivations, e.g. inputsFrom = [pkgs.neovim];
  # inputsFrom = [];

  # ── Environment ───────────────────────────────────────────────────────────
  # Passed straight through to mkShell as derivation attributes.
  env = {
    MY_CUSTOM_ENV_VAR = "production";
    PYTHONUNBUFFERED = "1";
  };

  # ── Real logic ────────────────────────────────────────────────────────────
  # Runs after the banner. Use this ONLY for behaviour (activating a venv,
  # creating a scratch dir, reporting runtime versions) — never for
  # decoration, which belongs in `tips` and `notes`.
  #
  # Guard anything interactive with `[ -t 0 ]` and respect $DEVSHELL_QUIET so
  # the shell stays usable from direnv, CI and `nix develop --command`.
  extraHook = ''
    # if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
    #   printf '  version: %s\n' "$(git --version)"
    # fi
  '';
}
