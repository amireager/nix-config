{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# AGENT — Unified Autonomous Agent & AI Runtime Environment
# ==============================================================================
# Provides the full operational toolchain for AI coding agents (pi, omp) and their tooling:
#   • Multi-Language Runtimes (Python3, uv, Node.js 24, Bun)
#   • AST Code Navigation & Manipulation (ast-grep, ripgrep, fd, sd, difftastic)
#   • Instant Self-Correction & QA (ruff, biome, shfmt, shellcheck, taplo)
#   • Web Scraping & Data Extraction (htmlq, jq, yq-go, xh, curl)
#   • Zero-Config Gateway Connection (Auto-wired to 9router at 127.0.0.1:20128)
# ==============================================================================
mkDevShell {
  name = "agent";
  icon = "🤖";
  description = "Autonomous Agent Suite: pi (minimal), omp (batteries) & 9router Gateway";

  packages = with pkgs; [
    # ── Core Multi-Language Runtimes ──
    python3
    uv # Fast Python venv & package runner
    nodejs_24 # Current LTS Node.js runtime
    # bun # Ultra-fast JS/TS runtime & package manager

    # ── Coding Agents ──
    # pi — radical-minimal harness (4 core tools). From nixpkgs.
    pi-coding-agent

    # ── AI CLI & Gateway Tools ──
    aichat # CLI chat & terminal pipe model runner

    # ── Code Intelligence, AST & Navigation ──
    ast-grep # Syntax-tree (AST) search and rewrite engine (sg)
    ripgrep # Ultra-fast text and code search (rg)
    fd # Intuitive, rapid file finder
    sd # Modern, fast find-and-replace tool (safer sed)
    difftastic # Structural, syntax-aware diff tool (difft)
    tokei # Code statistics and line counter by language

    # ── Self-Correction, Linters & Formatters ──
    ruff # Sub-10ms Python linter & formatter
    biome # Sub-10ms Rust-powered JS/TS/JSON/CSS formatter & linter
    pyright # Static type checker and LSP
    shellcheck # Shell script static analysis tool
    shfmt # Shell script formatter
    taplo # TOML schema validator & formatter

    # ── Web Extraction & Data Processing ──
    htmlq # Extract text and CSS selectors from HTML (jq for web)
    jq # Lightweight command-line JSON processor
    yq-go # Feature-rich YAML processor
    xh # Fast, friendly HTTP client for API probes
    curl # Standard HTTP client
    tlrc # Fast official tldr client in Rust

    # ── Benchmarking & Utilities ──
    hyperfine # Command-line benchmarking tool
    tree # Recursive directory visualization
    git # Version control
  ];

  env = {
    PYTHONUNBUFFERED = "1";
    OPENAI_API_BASE = "http://127.0.0.1:20128/v1";
    OPENAI_API_KEY = "local";
    AI_GATEWAY = "http://127.0.0.1:20128";
  };

  tips = [
    {
      key = "AST Search/Edit";
      cmd = "ast-grep --pattern 'fn \$NAME(\$\$\$)'";
    }
    {
      key = "Format / Lint";
      cmd = "ruff check --fix . / biome check --write .";
    }
    {
      key = "Web Scraping";
      cmd = "curl -s <url> | htmlq 'article' --text";
    }
    {
      key = "AI CLI Pipe";
      cmd = "git diff | aichat 'Generate commit message'";
    }
    {
      key = "Fast Replace";
      cmd = "sd 'old_pattern' 'new_pattern' file.py";
    }
  ];

  notes = [
    "Gateway pre-wired: OPENAI_API_BASE=http://127.0.0.1:20128/v1"
    "Run inside sandbox: box python hermes.py  (or box -g with GPU)"
  ];

  extraHook = ''
    # Auto-activate project virtual environment if present
    if [ -d .venv ]; then
      # shellcheck disable=SC1091
      source .venv/bin/activate
      printf '\033[1;32m🤖 Activated project .venv\033[0m\n'
    fi

    if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      printf '  \033[1;30mGateway: http://127.0.0.1:20128/v1 · Runtime: Python %s · Node %s · Bun %s\033[0m\n' \
        "$(python3 -c 'import platform; print(platform.python_version())' 2>/dev/null)" \
        "$(node -v 2>/dev/null)" \
        "$(bun --version 2>/dev/null)"
    fi
  '';
}
