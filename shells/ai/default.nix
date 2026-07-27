{mkDevShell, pkgs, ...}:
mkDevShell {
  name = "ai";
  icon = "🤖";
  description = "LLM APIs, OpenCode, agentic runtimes";

  packages = with pkgs; [
    python3
    uv # Replaces pip + virtualenv here too
    python3Packages.ipython
    python3Packages.httpx
    python3Packages.rich
    python3Packages.pydantic
    nodejs
    git
    curl
    jq

    # AI coding agents
    opencode
    qwen-code
    gemini-cli
  ];

  env.UV_PYTHON_DOWNLOADS = "never";

  tips = [
    {key = "Agents"; cmd = "opencode / qwen-code / gemini-cli";}
    {key = "Scratch env"; cmd = "uv venv && source .venv/bin/activate";}
  ];

  # Key presence is a runtime fact, so it is reported after the banner.
  extraHook = ''
    if [ -t 1 ] && [ -z "''${DEVSHELL_QUIET:-}" ]; then
      _ds_keys=""
      [ -n "''${OPENAI_API_KEY:-}" ] && _ds_keys="$_ds_keys OpenAI"
      [ -n "''${ANTHROPIC_API_KEY:-}" ] && _ds_keys="$_ds_keys Anthropic"
      [ -n "''${GEMINI_API_KEY:-}" ] && _ds_keys="$_ds_keys Gemini"
      if [ -n "$_ds_keys" ]; then
        printf '  \033[1;32m🔑 API keys present:\033[0m%s\n' "$_ds_keys"
      else
        printf '  \033[1;30m🔑 No API keys exported in this environment\033[0m\n'
      fi
      unset _ds_keys
    fi
  '';
}
