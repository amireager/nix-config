# ==============================================================================
# AI & REMOTE AGENTS DEV SHELL — LLM APIs, Routers, and Agentic Runtimes
# ==============================================================================
{pkgs, ...}: {
  default = pkgs.mkShell {
    name = "ai-env";

    packages = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      python3Packages.ipython
      python3Packages.httpx
      python3Packages.rich
      python3Packages.pydantic
      nodejs
      git
      curl
      jq

      # Ai code
      opencode
      qwen-code
      gemini-cli
    ];

    shellHook = ''
      echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
      echo -e "\033[1;36m│ \033[1;35m🤖 AI & Remote Agents DevShell (Hermes, OpenCode, Routers) \033[1;36m│\033[0m"
      echo -e "\033[1;36m├────────────────────────────────────────────────────────────┤\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• Target Stack    : \033[0mOpenCode, Mimo, 9router, Omnirouter      \033[1;36m│\033[0m"
      echo -e "\033[1;36m│ \033[1;33m• API Keys Ready  : \033[0m''${OPENAI_API_KEY:+OpenAI} ''${ANTHROPIC_API_KEY:+Anthropic}\033[1;36m│\033[0m"
      echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
      export DEVSHELL_ACTIVE="true"
      export DEVSHELL_NAME="ai"
    '';
  };
}
