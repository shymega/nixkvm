{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/f1bad50880bae73ff2d82fafc22010b4fc097a9c";
    adapter = {
      url = "github:webrtcHacks/adapter/v9.0.1";
      flake = false;
    };
    janus-gateway-src = {
      url = "github:meetecho/janus-gateway/99e133bc00cb910186a34b4e2083821cb6c111fc";
      flake = false;
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "github:matthewcroughan/disko/mc/make-builder-kernel-configurable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./blikvm-v1/flake-module.nix
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.git-hooks.flakeModule
        inputs.treefmt-nix.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
      treefmt = {
  package = pkgs.treefmt;
  projectRootFile = "flake.nix";

  settings = {
    global.excludes = [
      "*.age"
      "*.md"
      "*.gpg"
      "*.bin"
    ];
    shellcheck.includes = [
      "*"
      ".envrc"
    ];
  };
  programs = {
    deadnix.enable = true;
    statix.enable = true;
    nixpkgs-fmt.enable = true;
    prettier.enable = true;
    yamlfmt.enable = true;
    jsonfmt.enable = true;
    mdformat.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    actionlint.enable = true;
  };
};
        pre-commit = {
          check.enable = true;
          settings = {
            hooks = {
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              actionlint.enable = true;
            };
          };
        };
        devShells.default = pkgs.mkShell {
          name = "nix-config";

          nativeBuildInputs = with pkgs; [
            jq
            nil
            nixpkgs-fmt
            pre-commit
            python3Packages.pyflakes
            shellcheck
            shfmt
            statix
          ];
          shelLHook = config.pre-commit.installationScript;
          buildInputs = config.pre-commit.settings.enabledPackages;
        };
        overlayAttrs = config.legacyPackages;
        _module.args.pkgs = import inputs.nixpkgs {
          overlays = [
            inputs.self.overlays.default
          ];
          inherit system;
        };
        legacyPackages = {
          kvmd = pkgs.callPackage ./packages/kvmd { };
          ustreamer = pkgs.callPackage ./packages/ustreamer.nix { };
          janus-gateway = pkgs.janus-gateway.overrideAttrs (old: {
            src = inputs.janus-gateway-src;
            patches = (old.patches or [ ]) ++ [
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
