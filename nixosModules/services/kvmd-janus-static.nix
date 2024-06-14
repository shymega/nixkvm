{ pkgs, ... }:
{
  systemd.services.kvmd-janus-static = {
    description = "PiKVM - Janus WebRTC Gateway (Static Config)";
    after = [ "network.target" "network-online.target" "nss-lookup.target" "kvmd.service" ];
    serviceConfig = {
#      User = "kvmd-janus";
#      Group = "kvmd-janus";
      DynamicUser = true;
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      AmbientCapabilities = "CAP_NET_RAW";
      LimitNOFILE = 65536;
      UMask = "0117";

      ExecStart = "${pkgs.janus-gateway}/bin/janus --disable-colors --plugins-folder=/usr/lib/ustreamer/janus --configs-folder=/etc/kvmd/janus";
      TimeoutStopSec = 10;
      KillMode = "mixed";
    };
    wantedBy = [ "multi-user.target" ];
  };
}

