{ pkgs, ... }:
{
  systemd.services.kvmd-vnc = {
    description = "PiKVM - VNC to KVMD/Streamer proxy";
    after = [ "kvmd.service" ];

    serviceConfig = {
      User = "kvmd-vnc";
      Group = "kvmd-vnc";
      Type = "simple";
      Restart = "always";
      RestartSec = 3;

      ExecStart = "${pkgs.kvmd}/bin/kvmd-vnc --run";
      TimeoutStopSec = 3;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

