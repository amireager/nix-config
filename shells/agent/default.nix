{
  mkDevShell,
  pkgs,
  ...
}: let
  omp = pkgs.callPackage ./omp.nix {};
in
  # ==============================================================================
  # AGENT STUDIO — the general-purpose workshop for AI coding agents (omp-first)
  # ==============================================================================
  # Not tied to one harness: aliases deep/main/open rotate across ~80 router
  # models, so this shell ships the *arena*, not a favourite player:
  #   • Agent runtime: omp (standalone binary, pinned — lands here via omp.nix)
  #   • Code intelligence & rewrite: ast-grep, rg, fd, sd, difftastic, tokei
  #   • Data & HTTP: jq, yq, htmlq, xh, curl
  #   • Runtimes agents write code in: Python/uv, Node
  #   • QA layer agents self-correct with: ruff, biome, pyright, shellcheck…
  #   • LSP/DAP layer: direnv-vim attaches these inside any project
  #   • Gateway self-discovery: OPENAI_* wired to the local router (127.0.0.1:20128)
  # Deliberately a self-contained kit: this directory can be copied to another
  # machine alone and still be complete. Overlap with global/nvim layers is
  # fine — nix just links the same store paths.
  # ==============================================================================
  mkDevShell {
    name = "agent";
    icon = "🤖";
    description = "Agent studio: omp + code/data toolkit + LSP/DAP layer";

    packages = with pkgs; [
      # ── Agent runtime ──
      # omp: pinned standalone binary (./omp.nix) — replace the placeholder hash
      # there once, after prefetching on the laptop. box carries no packages and
      # inherits the caller's PATH, so both `omp` and sandboxed `box omp` work.
      omp
      opencode # reference harness — kept for side-by-side comparison with omp
      # aichat retired: omp + the local router profile own chat now.

      # ── Code intelligence, AST & navigation ──
      ast-grep # Syntax-tree (AST) search and rewrite engine (sg)
      ripgrep # Ultra-fast text and code search (rg)
      fd # Intuitive, rapid file finder
      sd # Modern, fast find-and-replace tool (safer sed)
      difftastic # Structural, syntax-aware diff tool (difft)
      tokei # Code statistics and line counter by language
      tree # Recursive directory visualization
      hyperfine # Command-line benchmarking tool

      # ── Data processing & HTTP ──
      htmlq # Extract text and CSS selectors from HTML (jq for web)
      jq # Lightweight command-line JSON processor
      yq-go # Feature-rich YAML processor
      xh # Fast, friendly HTTP client for API probes
      curl # Standard HTTP client

      # ── Runtimes agents write code in ──
      python3
      uv # Fast Python venv & package runner
      nodejs_24 # Current LTS Node.js runtime (rename the attr when 26 lands)

      # ── Self-correction: linters, formatters & type checks ──
      ruff # Sub-10ms Python linter & formatter
      biome # Sub-10ms Rust-powered JS/TS/JSON/CSS formatter & linter
      pyright # Static type checker and LSP
      python3Packages.debugpy # DAP adapter for agent-written Python
      shellcheck # Shell script static analysis tool
      shfmt # Shell script formatter
      taplo # TOML schema validator & formatter

      # ── LSP layer (direnv-vim attaches these inside projects) ──
      nixd # Nix LSP
      marksman # Markdown LSP — agents live in .md
      yaml-language-server # YAML LSP — CI, workflows, models.yml
      bash-language-server # Bash LSP

      # ── VCS & GitHub ──
      git # Version control
      gh # PRs, issues, releases — an agent without gh is half an agent

      # ── Docs ──
      tlrc # Fast official tldr client in Rust
    ];

    env = {
      PYTHONUNBUFFERED = "1";
      OPENAI_API_BASE = "http://127.0.0.1:20128/v1";
      OPENAI_BASE_URL = "http://127.0.0.1:20128/v1";
      OPENAI_API_KEY = "local";
      AI_GATEWAY = "http://127.0.0.1:20128";
    };

    tips = [
      {
        key = "Agent session";
        cmd = "omp (models: omp models | grep local/)";
      }
      {
        key = "One-shot agent";
        cmd = "omp -p --model local/main \"task\"";
      }
      {
        key = "AST Search/Edit";
        cmd = "ast-grep --pattern 'fn $NAME($$$)'";
      }
      {
        key = "Format / Lint";
        cmd = "ruff check --fix . / biome check --write .";
      }
      {
        key = "Fast Replace";
        cmd = "sd 'old_pattern' 'new_pattern' file.py";
      }
      {
        key = "GitHub ops";
        cmd = "gh pr status / gh pr create";
      }
    ];

    notes = [
      "Gateway pre-wired: OPENAI_BASE_URL=http://127.0.0.1:20128/v1 (key: local)"
      "Sandbox first-class: box omp — add --net host if the router (127.0.0.1:20128) is unreachable"
    ];

    extraHook = ''
      # Expose omp's generated completions (see ./omp.nix postInstall) to fish
      # and bash: they discover vendor dirs through XDG_DATA_DIRS, not PATH.
      export XDG_DATA_DIRS="${omp}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"

      # Auto-activate project virtual environment if present
      if [ -d .venv ]; then
        # shellcheck disable=SC1091
        source .venv/bin/activate
        printf '\033[1;32m🤖 Activated project .venv\033[0m\n'
      fi

      if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
        printf '  \033[1;30mGateway: http://127.0.0.1:20128/v1 · Python %s · Node %s\033[0m\n' \
          "$(python3 -c 'import platform; print(platform.python_version())' 2>/dev/null)" \
          "$(node -v 2>/dev/null)"
      fi
    '';
  }
