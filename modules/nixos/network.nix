{
  pkgs,
  lib,
  ...
}: {
  # ============================================================
  # NETWORKING — Amir's NixOS
  # ============================================================

  # === NetworkManager ===
  networking.networkmanager = {
    enable = true;
    dns = "none"; # let dnscrypt-proxy handle DNS
  };

  # Disable conflicting DNS managers
  networking.resolvconf.enable = false;
  services.resolved.enable = false;

  # === Firewall ===
  networking.firewall = {
    # dnscrypt-proxy listens on 127.0.0.1:53 only — no external ports needed
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  # === TCP Optimization (BBR) ===
  # BBR = Google's congestion control algorithm
  # Keeps the network pipe full without overflowing it
  # Result: more stable speeds, lower latency, better bandwidth utilization
  boot.kernel.sysctl = {
    # BBR congestion control
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # TCP Fast Open (skip handshake on reconnect — faster first byte)
    "net.ipv4.tcp_fastopen" = 3;

    # Buffer sizes — larger buffers = better throughput on fast connections
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";

    # MTU probing — auto-detect optimal packet size
    "net.ipv4.tcp_mtu_probing" = 1;
  };

  # === Encrypted DNS (dnscrypt-proxy) ===
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = ["127.0.0.1:53"];
      bootstrap_resolvers = ["9.9.9.9:53" "1.1.1.1:53"];
      ignore_system_dns = true;
      netprobe_address = "1.1.1.1:53";
      netprobe_timeout = 30;

      # DNSSEC = digital signatures on DNS responses
      # Prevents man-in-the-middle attacks on DNS (e.g. redirecting bank to phishing)
      require_dnssec = true;

      require_nolog = true;
      require_nofilter = true;
      sources.public-resolvers = {
        urls = [
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
        ];
        cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
      };
      cache = true;
      cache_size = 512;
      cache_min_ttl = 60;
      cache_max_ttl = 3600;

      # IPv6 disabled — not widely usable in Iran
      ipv6_servers = false;
      block_ipv6 = true;
    };
  };

  # Force local DNS resolution through dnscrypt-proxy
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 127.0.0.1
  '';
  networking.nameservers = ["127.0.0.1"];

  # === Proxy Management ===
  # v2raya — web-based proxy manager (http://127.0.0.1:2017)
  services.v2raya.enable = true;

  # === Network System Packages ===
  # Only daemon-capable and system-level tools here.
  # CLI tools (curl, wget, dig, mtr, etc.) are in modules/home/cli/tools.nix
  environment.systemPackages = with pkgs; [
    # --- Core proxy engines ---
    sing-box # modern all-in-one proxy (VLESS, VMess, Trojan, Hysteria, TUIC)
    xray # V2Ray fork with XTLS — fast, stealthy protocols

    # --- DPI bypass (Deep Packet Inspection circumvention) ---
    byedpi # SOCKS proxy with DPI bypass methods (lightweight)
    spoofdpi # fast DPI bypass tool written in Go

    # --- Cloudflare WARP ---
    wgcf # unofficial CLI for Cloudflare WARP (free VPN)
    wireguard-tools # WireGuard VPN tools (wg, wg-quick)

    # --- System networking ---
    iproute2 # ip, ss, bridge — core network config tool

    # --- sys proxy ---
    mihomo
    tor
  ];
}
