# ============================================================
# AGENIX SECRETS MAPPING — Defines which keys can decrypt secrets
# ============================================================
let
  # Amir's laptop SSH public key
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0awuTenDwfuJfmoDgfRRrpK0XpnQPKIKWCz2BPNjda amir@nixos-laptop";
in {
  "passwords.age".publicKeys = [laptop];
}
