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
          overlays = [ (import ./overlays/care-overlay.nix) ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          care = pkgs.care;
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }@args: {
        imports = [ ./modules/default.nix ];
        # With the overlay, pkgs.care is available by default.
        config = { };
      };
    };
}
