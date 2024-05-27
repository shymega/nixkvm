{ pkgs, ... }:
{
  systemd.services.kvmd-watchdog = {
    description = "PiKVM - RTC-based hardware watchdog";
    after = [ "systemd-modules-load.service" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 3;

      ExecStart = "${pkgs.kvmd}/bin/kvmd-watchdog run";
      TimeoutStopSec = 3;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

