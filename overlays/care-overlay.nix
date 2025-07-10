self: super: {
  # call your package definition
  care = super.callPackage ../pkgs/care/default.nix {
    mach-nix = self.mach-nix or super.mach-nix;
  };
}
