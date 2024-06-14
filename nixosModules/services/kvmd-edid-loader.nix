{ pkgs, ... }:
{
  environment.etc."kvmd/tc358743-edid.hex".source = "${pkgs.kvmd}/share/kvmd/edid/v3.hex";
  systemd.services.kvmd-edid-loader = {
    description = "PiKVM - EDID loader for TC358743";
    wants = [ "dev-kvmd\x2dvideo.device" ];
    after = [ "dev-kvmd\x2dvideo.device" "systemd-modules-load.service" ];
    before = [ "kvmd.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.v4l-utils}/bin/v4l2-ctl --device=/dev/kvmd-video --set-edid=file=/etc/kvmd/tc358743-edid.hex --fix-edid-checksums --info-edid";
      ExecStop = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

