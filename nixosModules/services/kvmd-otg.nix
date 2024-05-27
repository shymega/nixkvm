{ pkgs, ... }:
{
  systemd.services.kvmd-otg = {
    description = "PiKVM - OTG setup";
    after = [ "systemd-modules-load.service" ];
    before = [ "kvmd.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kvmd}/bin/kvmd-otg start";
      ExecStop = "${pkgs.kvmd}/bin/kvmd-otg stop";
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

