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
    "bcm2835-v4l2"
    "dwc2"
  ];

  services.logind.extraConfig = ''
    RuntimeDirectorySize=50%
  '';

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

    # Taken from https://github.com/pikvm/kvmd/blob/01fff2c7a9404c963800b2df43debb816ad89874/configs/os/udev/v3-hdmi-rpi4.rules#L2
    # https://unix.stackexchange.com/questions/66901/how-to-bind-usb-device-under-a-static-name
    # https://wiki.archlinux.org/index.php/Udev#Setting_static_device_names
    KERNEL=="video[0-9]*", SUBSYSTEM=="video4linux", KERNELS=="fe801000.csi|fe801000.csi1", ATTR{name}=="unicam-image", GROUP="kvmd", SYMLINK+="kvmd-video", TAG+="systemd"
    KERNEL=="hidg0", GROUP="kvmd", SYMLINK+="kvmd-hid-keyboard"
    KERNEL=="hidg1", GROUP="kvmd", SYMLINK+="kvmd-hid-mouse"
    KERNEL=="hidg2", GROUP="kvmd", SYMLINK+="kvmd-hid-mouse-alt"
  '';

    hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
#    hardware.raspberry-pi."4".tc358743.enable = true;
#    hardware.raspberry-pi."4".dwc2 = {
#      enable = true;
#      dr_mode = "host";
#    };
#    hardware.raspberry-pi."4".xhci.enable = true;
#    hardware.deviceTree.filter = "bcm2711-rpi-cm4.dtb";
    hardware.deviceTree.filter = "bcm2711-rpi-4-b.dtb"; }
