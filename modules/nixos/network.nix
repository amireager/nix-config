{
  pkgs,
  lib,
  ...
}: {
  # NetworkManager
  networking.networkmanager = {
    enable = true;
    dns = "none"; # let dnscrypt-proxy handle DNS
  };

  # Disable conflicting DNS managers
  networking.resolvconf.enable = false;
  services.resolved.enable = false;

  # Firewall
  networking.firewall = {
    # Only essential ports — add more per-service as needed
    allowedTCPPorts = [53]; # DNS (dnscrypt-proxy)
    allowedUDPPorts = [53]; # DNS
  };

  # Encrypted DNS (dnscrypt-proxy)
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = ["127.0.0.1:53"];
      bootstrap_resolvers = ["9.9.9.9:53" "1.1.1.1:53"];
      ignore_system_dns = true;
      netprobe_address = "1.1.1.1:53";
      netprobe_timeout = 30;
      require_dnssec = false;
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

  # Force local DNS resolution
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 127.0.0.1
  '';
  networking.nameservers = ["127.0.0.1"];

  # Proxy management
  services.v2raya.enable = true;

  # Network packages
  environment.systemPackages = with pkgs; [
    # === Essential (daily use) ===
    curl           # HTTP client (classic)
    wget           # file downloader
    dnsutils       # dig, nslookup, host
    mtr            # ping + traceroute combo
    nethogs        # bandwidth per process
    tcpdump        # packet capture
    iproute2       # ip, ss, bridge commands
    sing-box       # modern all-in-one proxy (Sing-box)

    # === Specialized (move to devShell if not daily) ===
    nmap           # network scanner
    net-tools      # ifconfig, route (legacy, prefer iproute2)
    aria2          # multi-protocol downloader
    xh             # modern HTTP client

    # === Proxy clients (keep only what you use) ===
    # v2ray         # V2Ray core — uncomment if needed
    # xray          # Xray core — uncomment if needed
    # shadowsocks-libev # SS client — uncomment if needed
    # tor           # Tor client — uncomment if needed
    # proxychains-ng # route any app through proxy — uncomment if needed
  ];
}
