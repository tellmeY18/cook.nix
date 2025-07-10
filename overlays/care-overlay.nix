self: super: {
  # call your package definition
  care = super.callPackage ../pkgs/care/default.nix { };
}
