{ pkgs, ... }:
{
  systemd.services.kvmd-ipmi = {
    description = "PiKVM - IPMI to KVMD proxy";
    after = [ "kvmd.service" ];

    serviceConfig = {
      User = "kvmd-ipmi";
      Group = "kvmd-ipmi";
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";

      ExecStart = "${pkgs.kvmd}/bin/kvmd-ipmi --run";
      TimeoutStopSec = 3;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

