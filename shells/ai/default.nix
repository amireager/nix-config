{
  mkDevShell,
  pkgs,
  ...
}: let
  aiDoctor = pkgs.writeShellApplication {
    name = "ai-doctor";
    runtimeInputs = with pkgs; [coreutils curl gnugrep gnused pciutils vulkan-tools];
    text = ''
      set -u

      printf '\033[1;36m━━━ Local AI environment ━━━\033[0m\n'
      printf 'API:     http://%s\n' "''${OLLAMA_HOST:-127.0.0.1:11434}"

      if command -v nvidia-smi >/dev/null 2>&1; then
        printf '\n\033[1;35mGPU\033[0m\n'
        nvidia-smi --query-gpu=name,memory.total,memory.used,driver_version \
          --format=csv,noheader 2>/dev/null || nvidia-smi --list-gpus || true
      else
        printf '\n\033[1;33mGPU: nvidia-smi is not available\033[0m\n'
      fi

      if command -v vulkaninfo >/dev/null 2>&1; then
        printf '\n\033[1;35mVulkan devices\033[0m\n'
        vulkaninfo --summary 2>/dev/null \
          | grep -E 'deviceName|driverName|driverInfo' \
          | sed 's/^[[:space:]]*/  /' || true
      fi

      printf '\n\033[1;35mRuntimes\033[0m\n'
      for tool in ollama llama-cli llama-server llama-bench aichat hf oterm \
        open-webui sd whisper-cli piper qdrant nvtop nvitop; do
        if command -v "$tool" >/dev/null 2>&1; then
          printf '  \033[1;32m✓\033[0m %s\n' "$tool"
        else
          printf '  \033[1;30m-\033[0m %s\n' "$tool"
        fi
      done

      printf '\n\033[1;35mOllama service\033[0m\n'
      if curl --silent --show-error --fail --max-time 1 \
        "http://''${OLLAMA_HOST:-127.0.0.1:11434}/api/version" 2>/dev/null; then
        printf '\n  \033[1;32mready\033[0m\n'
      else
        printf '  stopped — start manually with: ollama serve\n'
      fi
    '';
  };

  aiStorage = pkgs.writeShellApplication {
    name = "ai-storage";
    runtimeInputs = with pkgs; [coreutils];
    text = ''
      set -u
      paths=(
        "''${OLLAMA_MODELS:-$HOME/.ollama/models}"
        "''${HF_HOME:-$HOME/.cache/huggingface}"
        "$HOME/.cache/whisper"
      )

      printf '\033[1;36mLocal model storage\033[0m\n'
      for path in "''${paths[@]}"; do
        if [ -e "$path" ]; then
          du -sh "$path"
        else
          printf '%-8s %s\n' 'empty' "$path"
        fi
      done
    '';
  };
in
  mkDevShell {
    name = "ai";
    icon = "🧠";
    description = "Local LLM Lab: Ollama CUDA, llama.cpp, UIs, speech, image & RAG";

    packages = with pkgs; [
      # ── Local text inference ──
      ollama-cuda
      llama-cpp-vulkan
      aichat

      # ── Model acquisition & Python experiments ──
      python3
      uv
      python3Packages.huggingface-hub
      git-lfs
      aria2

      # ── GPU inspection ──
      nvtopPackages.nvidia
      nvitop
      vulkan-tools

      # ── Speech ──
      whisper-cpp-vulkan
      piper-tts
      ffmpeg

      # ── Interactive interfaces ──
      oterm
      open-webui

      # ── Image generation ──
      stable-diffusion-cpp-vulkan

      # ── Embeddings, RAG & data inspection ──
      qdrant
      sqlite
      jq
      curl

      # ── Local helpers; neither starts a service nor downloads a model ──
      aiDoctor
      aiStorage
    ];

    env = {
      OLLAMA_HOST = "127.0.0.1:11434";
      LOCAL_AI_API = "http://127.0.0.1:11434/v1";
      PYTHONUNBUFFERED = "1";
    };

    tips = [
      {
        key = "Health";
        cmd = "ai-doctor                     (GPU, Vulkan, tools, API)";
      }
      {
        key = "Model storage";
        cmd = "ai-storage                    (local model disk usage)";
      }
      {
        key = "Ollama API";
        cmd = "ollama serve                  (manual; no auto-start)";
      }
      {
        key = "GGUF server";
        cmd = "llama-server -m <model.gguf>  (fine-grained local runtime)";
      }
      {
        key = "Benchmark";
        cmd = "llama-bench -m <model.gguf>";
      }
      {
        key = "Terminal UI";
        cmd = "oterm                         (Ollama TUI)";
      }
      {
        key = "Web UI";
        cmd = "open-webui serve              (browser interface)";
      }
      {
        key = "Image CLI";
        cmd = "sd                            (stable-diffusion.cpp Vulkan)";
      }
      {
        key = "GPU monitor";
        cmd = "nvtop / nvitop";
      }
    ];

    notes = [
      "Designed for GTX 1650 4 GiB: prefer 1B–4B GGUF Q4 models and 2K–4K context"
      "7B/8B models need partial CPU/RAM offload; 14B+ is not recommended"
      "No service starts and no model downloads when entering this shell"
      "Use box -g with explicit -s/-S shares when running these tools in the sandbox"
    ];
  }
