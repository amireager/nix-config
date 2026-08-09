# ==============================================================================
# mkDevShell — the shell equivalent of mkHost
# ==============================================================================
# This builder takes the *data* (name, icon, tips) and generates the rest.
# ==============================================================================
{pkgs}: {
  name,
  icon ? "📦",
  description ? "",
  packages ? [],
  inputsFrom ? [],
  env ? {},
  tips ? [],
  notes ? [],
  extraHook ? "",
}: let
  inherit (pkgs) lib;

  keyWidth = lib.foldl' (acc: t: lib.max acc (lib.stringLength t.key)) 0 tips;
  padTo = w: s: s + lib.concatStrings (lib.genList (_: " ") (w - lib.stringLength s));

  titleText =
    "${icon}  ${name}"
    + lib.optionalString (description != "") "  —  ${description}";

  bashArray = name': items:
    "${name'}=(" + lib.concatMapStringsSep " " (i: lib.escapeShellArg i) items + ")";

  banner = ''
    _ds_banner() {
      [ -n "''${DEVSHELL_QUIET:-}" ] && return 0
      [ -t 1 ] || return 0

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

  reserved = ["name" "packages" "inputsFrom" "shellHook"];
  clashes = lib.intersectLists reserved (lib.attrNames env);
in
  assert lib.assertMsg (clashes == []) ''
    mkDevShell (${name}): `env` may not contain ${lib.concatStringsSep ", " clashes}.
    Use the dedicated argument instead of passing it through `env`.
  '';
    (pkgs.mkShell ({
        name = "${name}";
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
