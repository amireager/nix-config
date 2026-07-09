{
  pkgs,
  lib,
  ...
}: {
  # NetworkManager
  networking.networkmanager = {
    enable = true;
    dns = "none";
  };

  # Disable conflicting DNS
  networking.resolvconf.enable = false;
  services.resolved.enable = false;

  # Firewall rules
  networking.firewall = {
    allowedTCPPorts = [80 443 53 1080];
    allowedUDPPorts = [53];
  };

  # Encrypted DNS (dnscrypt-proxy)
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = ["127.0.0.1:53"];
      bootstrap_resolvers = ["9.9.9.9:53" "1.1.1.1:53" "8.8.8.8:53"];
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

  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 127.0.0.1
  '';
  networking.nameservers = ["127.0.0.1"];

  # DPI Bypass (disabled by default — enable if needed)
  # systemd.services.byedpi = { ... };

  # Proxy management
  services.v2raya.enable = true;

  # Network packages
  environment.systemPackages = with pkgs; [
    dnsutils doggo stubby
    curl wget aria2 axel
    tcpdump nmap mtr gping trippy
    iftop nethogs iperf3 net-tools iproute2 ethtool
    xray sing-box v2ray shadowsocks-libev proxychains-ng tor
  ];
}
