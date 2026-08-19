# Security Policy

## Scope

This repository contains a personal NixOS workstation configuration, shell scripts, development environments, and security-sensitive wrappers such as Box and proxy helpers.

Reports are especially useful for:

- Box mount or environment escapes;
- unsafe path, argument, profile, or proxy parsing;
- destructive GC-root cleanup behaviour;
- privilege escalation through system service wrappers;
- accidental secret exposure in source or Git history;
- insecure public listeners or firewall assumptions;
- supply-chain issues in CI definitions.

## Reporting

Do not open a public issue containing an exploit, credential, private path, or unredacted system information. Use GitHub's private security advisory feature for the repository owner. If that feature is unavailable, open a minimal public issue asking for a private contact channel without including sensitive details.

Include, when safe:

1. affected file and revision;
2. expected and observed behaviour;
3. a minimal reproduction using dummy data;
4. impact and required privileges;
5. suggested mitigation, if known.

## Secrets

The repository must never contain:

- passwords or password hashes;
- API tokens or cloud credentials;
- SSH, age, WireGuard, TLS, or signing private keys;
- Bitwarden exports;
- private service URLs containing credentials;
- downloaded AI models or private prompts/data.

If a real secret is committed, removing the current file is not enough. Revoke or rotate the secret first, then decide whether Git history must be rewritten.

## Threat model

The configuration targets an ordinary personal laptop. It aims for safe handling of important information and practical containment of untrusted tools, but it is not designed to resist a determined attacker with physical access, a compromised kernel, or a hostile system administrator.

The user intentionally has wheel and Podman privileges. Box reduces filesystem and environment exposure for child processes; it is not a virtual machine or a boundary against kernel vulnerabilities.
