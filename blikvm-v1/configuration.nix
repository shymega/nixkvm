{ pkgs, lib, config, ... }:
{
  imports = [
    ./kernel
  ];
#  services.ttyd.enable = true;
  networking.firewall.allowedTCPPorts = [
#    7681
    80
  ];
  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };
  users = {
    users.default = {
      password = "default";
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "input" "video" "audio" ];
      openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOJDRQfb1+7VK5tOe8W40iryfBWYRO6Uf1r2viDjmsJtAAAABHNzaDo= backup-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDgsWq+G/tcr6eUQYT7+sJeBtRmOMabgFiIgIV44XNc6AAAABHNzaDo= main-yubikey"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJMi3TAuwDtIeO4MsORlBZ31HzaV5bji1fFBPcC9/tWuAAAABHNzaDo= nano-yubikey"
      ];
    };
  };
  services.avahi = {
    openFirewall = true;
    enable = true;
    publish = {
      userServices = true;
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  hardware.opengl.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };
  environment.systemPackages = with pkgs; [
    vim
    git
    waypipe
  ];
  services.openssh.enable = true;
  networking.hostName = "blikvm-v1";
  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        DoESLiverpool.psk = "decafbad00";
      };
    };
  };

  fileSystems."/var/lib/kvmd/msd" = {
    device = "/var/lib/kvmd/msd-loopback.img";
    fsType = "ext4";
    options = [
      "nodev"
      "nosuid"
      "noexec"
# Mounting a loopback ro for the first time sets it permanently to ro
#      "rw"
      "errors=remount-ro"
      "data=journal"
      "X-kvmd.otgmsd-root=/var/lib/kvmd/msd"
      "X-kvmd.otgmsd-user=kvmd"
    ];
  };

#  fileSystems."/var/lib/kvmd/msd-bindmount" = {
#    device = "/var/lib/kvmd/msd";
#    fsType = "bind";
##options = [ "nodev" "nosuid" "noexec" "ro" "errors=remount-ro" "data=journal" "X-kvmd.otgmsd-root=/var/lib/kvmd/msd" "X-kvmd.otgmsd-user=kvmd" ]
#    options = [
#      "ro"
#      "noexec"
#      "nosuid"
#      "nodev"
#      "errors=remount-ro"
#      "data=journal"
#      "X-kvmd.otgmsd-root=/var/lib/kvmd/msd"
#      "X-kvmd.otgmsd-user=kvmd"
#    ];
#  };

  boot.kernelModules = [
    "usb_f_hid"
    "usb_f_mass_storage"
  ];


  systemd.tmpfiles.rules = [
    "d /run/kvmd 0777 - - - - -"
  ];


  environment.etc."kvmd/main.yaml".source = ../kvmd/main.yaml;
  environment.etc."kvmd/logging.yaml".source = ../kvmd/logging.yaml;
  environment.etc."kvmd/meta.yaml".source = ../kvmd/meta.yaml;
  environment.etc."kvmd/empty_file".source = builtins.toFile "empty" "default:$2y$05$a8WXzJVW84T8XbeE71nuoebxia7goYntlIK76oatye4eNEG2ylriu";
  environment.etc."kvmd/totp.secret".source = builtins.toFile "empty" "";

  users.groups.kvmd-pst = {};

  security.sudo.extraConfig = ''
    kvmd-pst ALL=(ALL) NOPASSWD: ${pkgs.kvmd}/bin/kvmd-helper-pst-remount
  '';

  users.groups.gpio = {};
  # Change permissions gpio devices
  services.udev.extraRules = ''
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", GROUP="gpio",MODE="0660"
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

}
