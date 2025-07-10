{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?ref=main";
  };
  outputs = { nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          care = pkgs.callPackage ./pkgs/care { };
        };
      }
    ) // {
      nixosModules.default = { pkgs, ... }: {
        imports = [ ./modules/default.nix ];
        nixpkgs.overlays = [ (import ./overlays/care-overlay.nix) ];
      };
      overlays.default = import ./overlays/care-overlay.nix;
    };
}
