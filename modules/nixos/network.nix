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
    dns = "none"; # dnscrypt-proxy handles DNS
  };

  networking.resolvconf.enable = false;
  services.resolved.enable = false;

  # === TCP Optimization (BBR) ===
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.ip_forward" = 1; # Required for tun2proxy / sing-box TUN interfaces
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
      ipv6_servers = false;
      block_ipv6 = true;
    };
  };

  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 127.0.0.1
  '';
  networking.nameservers = ["127.0.0.1"];

  # === Proxychains Configuration ===
  # Allows proxying specific commands that don't respect HTTP_PROXY
  programs.proxychains = {
    enable = true;
    proxies = {
      default = {
        enable = true;
        type = "socks5";
        host = "127.0.0.1";
        port = 1819; # Default Aether port. Use custom config in ~/.config/proxychains for others.
      };
    };
  };

  # === Network System Packages ===
  environment.systemPackages = with pkgs; [
    sing-box
    tun2proxy
    proxychains-ng
    byedpi
    xray # Modern core for v2rayA (Vless/Reality)
    v2rayn # Desktop alternative
    wireguard-tools
    iproute2
    tor
  ];
}
