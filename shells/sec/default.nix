{mkDevShell, ...}:
# ==============================================================================
# SECURITY SHELL — INTENTIONALLY EMPTY, PENDING REDESIGN
# ==============================================================================
# The previous contents (bubblewrap, firejail, safe-crypt, safe-test) were
# cleared on purpose: the sandboxing story overlaps with the system-level
# `fj` / `fjx` wrappers and with services.firejail, so the tooling is being
# reworked from scratch rather than patched.
#
# The shell is kept registered so that `dev sec` keeps resolving and the
# rewrite can land as a content-only change.
#
# ── Reference: what used to live here ─────────────────────────────────────
#   packages : bubblewrap, firejail, vulnix
#   safe-crypt : gocryptfs volume manager over ~/pub/crypt
#                init | mount | umount | list
#   safe-test  : podman one-shot runner, cwd mounted read-only at /ws
#
# The full previous implementation is in git history:
#   git log --oneline -- shells/sec/default.nix
#   git show <commit>:shells/sec/default.nix
#
# ── Open questions for the redesign ───────────────────────────────────────
#   • Does sandboxing belong in a devShell at all, or only as system wrappers?
#   • bubblewrap vs firejail vs podman — one primary, or all three?
#   • Should vulnix be system-level so CVE scans need no shell entry?
# ==============================================================================
mkDevShell {
  name = "sec";
  icon = "🛡️";
  description = "empty — awaiting redesign";

  packages = [];

  notes = [
    "This shell is deliberately empty. See the file header."
    "System-level sandboxing (fj / fjx) is unaffected."
  ];
}
