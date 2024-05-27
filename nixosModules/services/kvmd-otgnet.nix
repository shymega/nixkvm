{ pkgs, ... }:
{
  systemd.services.kvmd-otgnet = {
    description = "PiKVM - OTG network service";
    after = [ "kvmd-otg.service" "network-pre.target" ];
    wants = [ "network-pre.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kvmd}/bin/kvmd-otgnet start";
      ExecStop = "${pkgs.kvmd}/bin/kvmd-otgnet stop";
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

