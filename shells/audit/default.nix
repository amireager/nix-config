{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# AUDIT — inspect what you already have
# ==============================================================================
# Companion to `box`, and deliberately the opposite activity:
#
#   box    — "run this thing without letting it touch my system"   (runtime)
#   audit  — "is this thing safe, and is my system sound?"         (static)
#
# Nothing here executes untrusted code — every tool reads and reports.
# ==============================================================================
let
  # Scan the running system's closure for known CVEs.
  sysAudit = pkgs.writeShellScriptBin "audit-system" ''
    set -u
    echo -e "\033[1;36m━━━ [1/2] CVEs in the current system closure ━━━\033[0m"
    ${pkgs.vulnix}/bin/vulnix --system || true

    echo
    echo -e "\033[1;36m━━━ [2/2] Insecure packages permitted in config ━━━\033[0m"
    if grep -rn "permittedInsecurePackages" "''${NIX_CONFIG_FLAKE:-/etc/nixos}" 2>/dev/null; then
      echo "  ^ audit these: is the CVE still relevant, or is this stale?"
    else
      echo "  none — clean & secure"
    fi
  '';

  # Secret-leak sweep over a repository, including its history.
  repoAudit = pkgs.writeShellScriptBin "audit-repo" ''
    set -u
    TARGET="''${1:-.}"
    cd "$TARGET" || exit 1

    echo -e "\033[1;36m━━━ [1/2] Secrets in working tree and git history ━━━\033[0m"
    ${pkgs.gitleaks}/bin/gitleaks detect --source . --redact --no-banner || true

    echo
    echo -e "\033[1;36m━━━ [2/2] Known vulnerabilities in lockfiles ━━━\033[0m"
    if ls flake.lock Cargo.lock package-lock.json pnpm-lock.yaml \
          poetry.lock uv.lock go.sum requirements.txt >/dev/null 2>&1; then
      ${pkgs.osv-scanner}/bin/osv-scanner scan source -r . || true
    else
      echo "  no recognised lockfile here"
    fi
  '';

  # Master 1-click audit command
  auditAll = pkgs.writeShellScriptBin "audit-all" ''
    set -u
    echo -e "\033[1;35m════════════════════════════════════════════════════════════\033[0m"
    echo -e "\033[1;35m           🔒 FULL REPO & SYSTEM AUDIT SUITE                \033[0m"
    echo -e "\033[1;35m════════════════════════════════════════════════════════════\033[0m\n"
    ${repoAudit}/bin/audit-repo "''${1:-.}"
    echo
    ${sysAudit}/bin/audit-system
  '';
in
  mkDevShell {
    name = "audit";
    icon = "🔎";
    description = "Check what you already have — CVEs, secrets, hardening";

    packages = with pkgs; [
      # ── Nix-native ──
      vulnix # CVEs in a store closure

      # ── Secrets ──
      gitleaks # Secrets in a git repo, history included
      trufflehog # Verifies whether a found key is still live

      # ── Dependencies & supply chain ──
      osv-scanner # Google OSV database: cargo, npm, pip, go, nix
      grype # Vulnerability scanner for images and filesystems
      syft # SBOM generator, feeds grype
      trivy # Containers, filesystems, IaC, misconfiguration

      # ── System hardening ──
      lynis # Scores the hardening of this machine and suggests fixes

      # ── Containers ──
      dive # Inspect an image layer by layer

      # ── Signing & secrets at rest ──
      cosign # Sign and verify artifacts
      age # Modern file encryption
      sops # Encrypted config files (pairs with agenix already in use)

      # ── Master Helpers ──
      sysAudit
      repoAudit
      auditAll
    ];

    tips = [
      {
        key = "Full Audit";
        cmd = "audit-all       (repo secrets + lockfiles + system CVEs)";
      }
      {
        key = "This repo";
        cmd = "audit-repo     (gitleaks + osv-scanner)";
      }
      {
        key = "This system";
        cmd = "audit-system   (vulnix + insecure pkgs)";
      }
      {
        key = "Hardening";
        cmd = "lynis audit system";
      }
      {
        key = "Container";
        cmd = "trivy image <ref>  /  dive <ref>";
      }
      {
        key = "IaC config";
        cmd = "trivy config .";
      }
      {
        key = "SBOM";
        cmd = "syft dir:. -o json | grype";
      }
    ];

    notes = [
      "Read-only by design: audit inspects, box contains"
      "lynis wants sudo for a full system audit"
    ];
  }
