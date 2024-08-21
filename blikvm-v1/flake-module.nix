{ self, inputs, config, ... }:
{
  #  perSystem = { pkgs, system, ... }: {
  #    _module.args.pkgs = import inputs.nixpkgs {
  #      inherit system;
  #    };
  #  };
  flake = rec {
    images = {
      pi = self.nixosConfigurations.pi.config.system.build.diskoImages;
      #pi = (self.nixosConfigurations.pi.extendModules {
      #  modules = [
      #    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      #    {
      #      disabledModules = [
      #        "profiles/base.nix"
      #        "profiles/all-hardware.nix"
      #      ];
      #    }
      #  ];
      #}).config.system.build.sdImage;
    };
    packages.x86_64-linux.pi-image = (self.nixosConfigurations.pi.extendModules {
      modules = [
        { disko.imageBuilderQemu = (builtins.getFlake "github:nixos/nixpkgs/65c851cd7523c669b8fb25236b1c48283a2f43ec").legacyPackages.x86_64-linux.qemu + "/bin/qemu-system-aarch64 -M virt -cpu cortex-a57"; }
      ];
    }).config.system.build.diskoImages;
    packages.aarch64-linux.pi-image = images.pi;
    nixosConfigurations = {
      pi = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ self.overlays.default ]; }
          inputs.disko.nixosModules.default
          inputs.nixos-hardware.nixosModules.raspberry-pi-4
          "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
          ./configuration.nix
          ./base.nix
          ./disko.nix
          self.nixosModules.services-kvmd-janus-static
          self.nixosModules.services-kvmd-janus
          self.nixosModules.services-kvmd-edid-loader
          self.nixosModules.services-kvmd-otg
          self.nixosModules.services-kvmd
        ];
      };
    };
  };
}

