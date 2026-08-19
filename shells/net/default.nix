{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "net";
  icon = "🌐";
  description = "Network diagnosis, proxy cores, packet and protocol tools";

  packages = with pkgs; [
    sing-box
    tun2proxy
    byedpi
    xray
    v2rayn
    tor
    wireguard-tools

    iproute2
    ethtool
    iw
    socat

    nmap
    tcpdump
    termshark
    iperf3

    testssl
    websocat
    oha
  ];

  tips = [
    {
      key = "Routes / sockets";
      cmd = "ip route / ss -tulpn";
    }
    {
      key = "Proxy cores";
      cmd = "sing-box / xray / v2rayN / tor";
    }
    {
      key = "TUN / DPI";
      cmd = "tun2proxy-bin / ciadpi / wg";
    }
  ];

  notes = [
    "mtr is system-level so its capability wrapper works; vnstat history is collected by vnstatd"
    "These cores are packages, not services. Start the filter yourself on $PROXY_PORT"
  ];
}
