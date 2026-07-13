# Dev media tools — specialized, not for daily use
{pkgs, ...}: {
  home.packages = with pkgs; [
    # ── Note Taking & Knowledge ──
    # trilium-next     # Hierarchical note taking (heavier)

    # ── Lightweight AI Tools ──
    # ollama           # Run LLMs locally (uncomment if you have GPU)
    # llama-cpp        # Lightweight LLM inference
    # whisper-cpp      # Local speech-to-text

    # ── Image Editing ──
    pinta # Simple & fast image editor (Paint-like)
    # gimp               # Full-featured image editor (if needed)
    # inkscape # Vector graphics editor

    # ── PDF & Document Tools ──
    poppler-utils # pdftotext, pdfimages, pdfinfo
    pdfarranger # Merge, split, rotate PDFs (GUI)
    # ocrmypdf         # Add OCR to PDFs (optional)

    # ── Video & Media Advanced ──
    ffmpegthumbnailer # Generate thumbnails for video files
    # handbrake # Advanced video encoder (GUI)
    kooha # Simple & beautiful Wayland screen recorder

    # ── Audio Tools ──
    # audacity # Audio editor
    # helvum           # PipeWire patchbay (if needed)
  ];
}
