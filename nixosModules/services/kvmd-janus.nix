{ config, pkgs, ... }:
{
  systemd.services.kvmd-janus = {
    description = "PiKVM - Janus WebRTC Gateway";
    after = [ "network.target" "network-online.target" "nss-lookup.target" "kvmd.service" ];

    serviceConfig = {
      #User = "kvmd-janus";
      #Group = "kvmd-janus";
      DynamicUser = true;
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      AmbientCapabilities = "CAP_NET_RAW";
      LimitNOFILE = 65536;
      UMask = "0117";

      ExecStart = "${pkgs.kvmd}/bin/kvmd-janus --run";
      TimeoutStopSec = 10;
      KillMode = "mixed";
    };

    wantedBy = [ "multi-user.target" ];
  };
}

