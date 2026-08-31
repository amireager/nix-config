# =============================================================================
# OMP — pinned standalone binary from the oh-my-pi GitHub release
# =============================================================================
# Binary route (decided): the official release asset is self-contained (~100MB,
# bun-compiled, Rust natives bundled), needs no ambient bun and no nix source
# build. Upstream also ships an official nix package + HM module
# (github:can1357/oh-my-pi → nix/package.nix) — deliberately NOT used here:
# that one is a full source build (cargo + bunDeps + cmake/ninja, ~1GB closure
# territory) and the HM module installs globally. This stays light and
# devshell-only. Version bumps = change `version`, refresh the hash, done.
# =============================================================================
{pkgs, ...}: let
  version = "18.0.11";
in
  pkgs.stdenv.mkDerivation {
    pname = "omp";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      # TODO(amir): placeholder — replace with the real hash. One-liner on the
      # laptop (has GitHub access):
      #   nix store prefetch-file --json \
      #     https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64
      hash = pkgs.lib.fakeHash;
    };

    # Bun-compiled binaries are dynamically linked against glibc; let the
    # stdenv hook resolve the interpreter/rpaths into the nix store.
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = [pkgs.stdenv.cc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/omp"
      runHook postInstall
    '';

    # Declarative shell completions: omp generates them from its own live
    # command/flag metadata (`omp completions <shell>`), so they can never
    # drift from the installed binary. The agent shell additionally exposes
    # $out/share via XDG_DATA_DIRS so fish/bash pick the vendor dirs up.
    # Guarded: if the binary refuses to run in the build sandbox, the build
    # still succeeds and the fallback stays `omp completions fish > ...`.
    postInstall = ''
      autoPatchelf "$out/bin/omp"
      export HOME="$TMPDIR"
      if "$out/bin/omp" completions fish >/dev/null 2>&1; then
        install -Dm444 \
          <("$out/bin/omp" completions fish) \
          "$out/share/fish/vendor_completions.d/omp.fish"
        install -Dm444 \
          <("$out/bin/omp" completions bash) \
          "$out/share/bash-completion/completions/omp"
        install -Dm444 \
          <("$out/bin/omp" completions zsh) \
          "$out/share/zsh/site-functions/_omp"
      else
        echo "omp: completion generation skipped (binary not runnable in builder)" >&2
      fi
    '';

    meta = {
      description = "oh-my-pi — keyboard-centric coding agent (fork of Pi)";
      homepage = "https://github.com/can1357/oh-my-pi";
      mainProgram = "omp";
      platforms = ["x86_64-linux"];
    };
  }
