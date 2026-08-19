{
  pkgs,
  lib,
  proxy,
  ...
}: {
  # ============================================================
  # NETWORKING — static resolv.conf (pre-harden method) + opt-in proxy
  # ============================================================

  networking = {
    enableIPv6 = false;

    networkmanager = {
      enable = true;
      # DNS is owned by the static resolv.conf below, not by DHCP.
      dns = "none";
    };

    # Never let openresolv regenerate the file. That path wrote 127.0.0.1
    # as a regular file and NixOS would not replace it.
    resolvconf.enable = false;
    nameservers = ["127.0.0.1"];
  };

  environment = {
    etc."resolv.conf".text = lib.mkForce ''
      nameserver 127.0.0.1
    '';

    sessionVariables = {
      PROXY_HOST = proxy.host;
      PROXY_PORT = toString proxy.port;
    };
  };

  # environment.etc skips a leftover regular file. Force the symlink so a
  # previous generation's resolvconf output cannot stick around.
  system.activationScripts.forceResolvConf = {
    deps = ["etc"];
    text = ''
      ln -sfn /etc/static/resolv.conf /etc/resolv.conf
    '';
  };

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.ip_forward" = 1;
  };

  services = {
    resolved.enable = false;

    # Same resolver settings that worked at 3501d38. Do not tighten filters
    # or hand ownership to resolvconf.
    dnscrypt-proxy = {
      enable = true;
      settings = {
        listen_addresses = ["127.0.0.1:53"];
        bootstrap_resolvers = ["9.9.9.9:53" "1.1.1.1:53"];
        ignore_system_dns = true;
        netprobe_address = "1.1.1.1:53";
        netprobe_timeout = 5;
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

    vnstat.enable = true;
  };

  systemd.services = {
    NetworkManager-wait-online.enable = false;
    dnscrypt-proxy.serviceConfig.TimeoutStopSec = "5";
  };

  programs = {
    mtr.enable = true;

    proxychains = {
      enable = true;
      package = pkgs.proxychains-ng;
      proxyDNS = true;
      chain.type = "strict";
      proxies.default = {
        enable = true;
        type = "socks5";
        inherit (proxy) host port;
      };
    };
  };
}
