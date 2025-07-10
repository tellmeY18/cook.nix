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
          care = pkgs.callPackage ./pkgs/care/package.nix { };
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }@args: {
        imports = [ ./modules/default.nix ];

        config = {
          # NOTE: You must set services.care.package explicitly in your NixOS configuration, e.g.:
          # services.care.package = inputs.cook.packages.${pkgs.system}.care;
        };
      };
    };
}
