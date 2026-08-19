{...}: {
  # ============================================================
  # VIRTUALISATION — Container Runtime Policy
  # ============================================================

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # The user module intentionally grants supplementary `podman` membership for
  # rootful/system Podman access. Rootless Podman does not require that group;
  # treat membership as privileged access to the system API.
}
