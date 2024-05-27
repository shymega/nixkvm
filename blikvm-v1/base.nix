{ pkgs, config, lib, ... }:
{
  environment.noXlibs = lib.mkForce false;
  boot = {
    kernelParams = [ "cma=512M" ];
    loader = {
      systemd-boot.enable = true;
      generic-extlinux-compatible.enable = false;
      grub.enable = false;
    };
  };
  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";
  boot.loader.systemd-boot.extraInstallCommands = ''
    set -euo pipefail
    ${pkgs.coreutils}/bin/mkdir -p ${config.boot.loader.efi.efiSysMountPoint}/dtbs
    ${pkgs.coreutils}/bin/cp --no-preserve=mode -r ${config.hardware.deviceTree.package} ${config.boot.loader.efi.efiSysMountPoint}/dtbs
    for filename in ${config.boot.loader.efi.efiSysMountPoint}/loader/entries/nixos*-generation-[1-9]*.conf; do
      if ! ${pkgs.gnugrep}/bin/grep -q 'devicetree' $filename; then
        echo "devicetree /dtbs/$(${pkgs.coreutils}/bin/basename ${config.hardware.deviceTree.package})/${config.hardware.deviceTree.name}" >> $filename
      fi
    done
  '';
}
