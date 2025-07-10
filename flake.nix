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
          care = pkgs.callPackage ./pkgs/care/default.nix { };
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }: {
        imports = [ ./modules/default.nix ];

        config = {
          # Apply the overlay to make care package available
          nixpkgs.overlays = [ (import ./overlays/care-overlay.nix) ];

          # If package isn't explicitly set, use our care package
          services.care.package = lib.mkDefault pkgs.care;
        };
      };
      overlays.default = import ./overlays/care-overlay.nix;
    };
}
