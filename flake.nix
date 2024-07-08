{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:matthewcroughan/nixpkgs/mc/pi-kernel-6.9";
    adapter = {
      url = "github:webrtcHacks/adapter/v9.0.1";
      flake = false;
    };
    janus-gateway-src = {
      url = "github:meetecho/janus-gateway/99e133bc00cb910186a34b4e2083821cb6c111fc";
      flake = false;
    };
#    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "github:matthewcroughan/disko/mc/make-builder-kernel-configurable";
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
          kvmd = pkgs.callPackage ./packages/kvmd {};
          ustreamer = pkgs.callPackage ./packages/ustreamer.nix {};
          janus-gateway = pkgs.janus-gateway.overrideAttrs (old: {
            src = inputs.janus-gateway-src;
            patches = (old.patches or []) ++ [
              ./packages/janus-gateway/0001-unmute-hack.patch
#              ./packages/janus-gateway/0002-connectionState.patch
            ];
            postFixup = ''
              sed -i -e 's|^function Janus(|export function Janus(|g' "$doc/share/janus/javascript/janus.js"
              sed -i '1s|^|import "./adapter.js"\n|' "$doc/share/janus/javascript/janus.js"
              cp ${inputs.adapter}/release/adapter.js "$doc/share/janus/javascript/adapter.js"
            '';
          });
        }; 
      };
      flake = {
        nixosModules = import ./nixosModules { lib = inputs.nixpkgs.lib; };
      };
    };
}
