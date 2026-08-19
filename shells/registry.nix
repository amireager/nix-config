# Pure shell registry shared by the flake outputs and the global `dev` launcher.
# Keep names, groups and aliases here so menus and completions cannot drift.
{
  shellDirs = [
    "agent"
    "ai"
    "audit"
    "build"
    "cli"
    "go"
    "media"
    "net"
    "nix"
    "python"
    "rust"
    "web"
  ];

  groups = [
    {
      title = "AI & Autonomous Agents";
      members = ["agent" "ai"];
    }
    {
      title = "Languages, Data & Runtimes";
      members = ["python" "rust" "go" "web"];
    }
    {
      title = "Media & Content";
      members = ["media"];
    }
    {
      title = "System, Build & QA";
      members = ["cli" "build" "nix"];
    }
    {
      title = "Network & Security";
      members = ["net" "audit"];
    }
  ];

  aliases = {
    c = "build";
    data = "python";
    default = "nix";
  };
}
