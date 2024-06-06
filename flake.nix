{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
#    nixpkgs.url = "github:matthewcroughan/nixpkgs/mc/pi-kernel-6.9";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "github:nix-community/disko";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        flake-parts.flakeModules.easyOverlay
        ./blikvm-v1/flake-module.nix
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        overlayAttrs = config.legacyPackages;
        _module.args.pkgs = import inputs.nixpkgs {
          overlays = [
            inputs.self.overlays.default
          ];
          inherit system;
        };
        legacyPackages = {
          kvmd = pkgs.callPackage ./kvmd {};
        }; 
      };
      flake = {
        nixosModules = import ./nixosModules { lib = inputs.nixpkgs.lib; };
      };
    };
}
