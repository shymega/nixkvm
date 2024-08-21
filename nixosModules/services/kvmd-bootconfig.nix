{ pkgs, ... }:
{
  systemd.services.kvmd-bootconfig = {
    description = "Pi-KVM - Boot configuration";
    after = [ "systemd-modules-load.service" ];
    before = [
      "network-pre.target"
      "kvmd-otg.service"
      "kvmd-nginx.service"
      "kvmd.service"
      "sshd.service"
      "pikvm-bootconfig.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kvmd}/bin/kvmd-bootconfig --do-the-thing";
      ExecStop = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };
}

