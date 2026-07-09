{...}: {
  imports = [
    ./cli/git.nix
    ./cli/fish.nix
    ./cli/tmux.nix
    ./cli/tools.nix
    ./gui/terminal.nix
    ./gui/browser.nix
    ./gui/media.nix
    ./gui/wayland.nix
    ./gui/xdg.nix
    ./dev/nix-tools.nix
    ./dev/tools.nix
    ./editor/nvim
    ./theme/gtk.nix
    ./theme/noctalia.nix
    ./theme/niri.nix
  ];
}
