{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?ref=main";
    dream2nix.url = "github:nix-community/dream2nix";
  };
  outputs = { nixpkgs, flake-utils, dream2nix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        d2n = dream2nix.lib;
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          care = d2n.makeFlakePackage {
            inherit system;
            source = pkgs.fetchFromGitHub {
              owner = "ohcnetwork";
              repo = "care";
              rev = "v3.0.0";
              sha256 = "sha256-B7d+hiNYDVSDicukVakTl4g3d6dz8uEWy9skzlrfw5U=";
            };
            python = "python3.14";
            postInstall = ''
              mkdir -p $out/bin
              makeWrapper $out/lib/care/manage.py $out/bin/care-manage \
                --set DJANGO_SETTINGS_MODULE config.settings.staging
              makeWrapper ${pkgs.gunicorn}/bin/gunicorn $out/bin/care-gunicorn \
                --set DJANGO_SETTINGS_MODULE config.settings.staging
              makeWrapper ${pkgs.celery}/bin/celery $out/bin/care-celery \
                --set DJANGO_SETTINGS_MODULE config.settings.staging
            '';
          };
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
