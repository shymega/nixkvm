{ lib, pkgs, config, ... }:
let
#  rpi4 = pkgs.linuxKernel.packagesFor
#    (pkgs.callPackage ./linux-rpi.nix {
#      kernelPatches = with ((pkgs.callPackage (pkgs.path + "/pkgs/os-specific/linux/kernel/patches.nix") {})); [
#        bridge_stp_helper
#        request_key_helper
#      ];
#      rpiVersion = 4;
#    });
  rpi4 =
    (pkgs.callPackage (./linux-rpi.nix) {
      kernelPatches = with ((pkgs.callPackage (pkgs.path + "/pkgs/os-specific/linux/kernel/patches.nix") {})); [
        bridge_stp_helper
        request_key_helper
      ];
      rpiVersion = 4;
    });
in
{
#  boot.kernelPackages = pkgs.linuxPackages_latest.extend (lib.const (super: {
  boot.kernelPackages = pkgs.linuxPackages_rpi4.extend (lib.const (super: {
    kernel = rpi4.overrideDerivation (drv: {
      nativeBuildInputs = (drv.nativeBuildInputs or []) ++ [ pkgs.hexdump ];
    });
  }));
  boot.kernelPatches = [
    {
      name = "config-zboot-zstd";
      patch = null;
      extraStructuredConfig = { EFI_ZBOOT = lib.kernel.yes; KERNEL_ZSTD = lib.kernel.yes; };
    }
  ];
  nixpkgs.hostPlatform = {
    system = "aarch64-linux";
    linux-kernel = {
      name = "aarch64-multiplatform";
      baseConfig = "defconfig";
      DTB = true;
      autoModules = true;
      preferBuiltin = true;
      extraConfig = ''
        # Raspberry Pi 3 stuff. Not needed for   s >= 4.10.
        ARCH_BCM2835 y
        BCM2835_MBOX y
        BCM2835_WDT y
        RASPBERRYPI_FIRMWARE y
        RASPBERRYPI_POWER y
        SERIAL_8250_BCM2835AUX y
        SERIAL_8250_EXTENDED y
        SERIAL_8250_SHARE_IRQ y

        # Cavium ThunderX stuff.
        PCI_HOST_THUNDER_ECAM y

        # Nvidia Tegra stuff.
        PCI_TEGRA y

        # The default (=y) forces us to have the XHCI firmware available in initrd,
        # which our initrd builder can't currently do easily.
        USB_XHCI_TEGRA m
      '';
      target = "vmlinuz.efi";
      installTarget = "zinstall";
    };
    gcc = {
      arch = "armv8-a";
    };
  };
  nixpkgs.overlays = [(final: super: {
    # Workaround for modules expected by NixOS not being built                                                                                                                            
    makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
  })];
}
