# cook.nix

## How to Use cook.nix in Your NixOS Flake

This repository provides a NixOS module and a prebuilt Django EMR package (`care`). It is designed for modern Nix Flake-based workflows and is fully declarative, reproducible, and binary-optimized.


---

### 1. Add cook.nix as a flake input

In your top-level `flake.nix`:

```nix
inputs.cook.url = "github:tellmeY18/cook.nix";
```

---

### Overlay: `pkgs.care` is available by default

This flake provides an overlay so that `pkgs.care` is available automatically in your NixOS configuration and modules. You do **not** need to set `services.care.package` manually unless you want to override it.

### 2. Add the CARE module to your NixOS host configuration

In your `nixosConfigurations.<hostname>` block:

```nix
nixosConfigurations.chopper = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hosts/chopper/configuration.nix
    # ...other modules...
    cook.nixosModules.default
  ];
};
```

---

### 3. Enable and configure CARE in your host's configuration

In `./hosts/chopper/configuration.nix` (or wherever you configure your host):

```nix
{ config, pkgs, lib, ... }:

{
  services.care = {
    enable = true;
    # No need to set package = pkgs.care; -- the overlay makes pkgs.care available by default!
    # Optionally, customize roles and environment:
    api.enable = true;
    worker.enable = true;
    beat.enable = true;
    environment = {
      DATABASE_URL = "postgres://user:pass@localhost:5432/care";
      REDIS_URL = "redis://localhost:6379/0";
      POSTGRES_HOST = "localhost";
      POSTGRES_PORT = "5432";
      REDIS_HOST = "localhost";
      REDIS_PORT = "6379";
      # Add S3/garage2 variables as needed
    };
  };
}
```

**Note:**  
- The overlay in this flake makes `pkgs.care` available everywhere. You do **not** need to set `services.care.package` unless you want to override the default.

---

### 4. Rebuild your system

```sh
sudo nixos-rebuild switch --flake .
```

---

**Summary:**  
- Add `cook` as a flake input.
- Add `cook.nixosModules.default` to your host's module list.
- Pass `cook` as a `specialArg` and set `services.care.package = cook.packages.${pkgs.system}.care;` in your host config.
- Enable and configure CARE as needed.

---

### 3. What this does

- Installs the prebuilt `care` package and all dependencies.
- Sets up systemd services for API, Celery worker, and Celery beat.
- Runs Django migrations automatically before starting services.
- Ensures PostgreSQL, Redis, and other dependencies are available.

---

## Advanced Configuration

You can override any environment variables or enable/disable specific roles:

```nix
services.care.environment.DATABASE_URL = "postgres://custom:custom@dbhost:5432/customdb";
services.care.api.enable = true;
services.care.worker.enable = false;
services.care.beat.enable = true;
```

For advanced S3/garage2 configuration, add the relevant environment variables.

---

## Notes

- No impure scripting or bash is used; all orchestration is handled via pure Nix and systemd.
- The overlay ensures `pkgs.care` is available by default. You only need to set `services.care.package` if you want to override the default.
- For more advanced configuration, see the comments in `cook.nix/modules/care.nix`.

---

## Example Minimal Configuration

```nix
{
  services.care = {
    enable = true;
    # package = pkgs.care; # Not needed unless you want to override!
    api.enable = true;
    worker.enable = true;
    beat.enable = true;
    environment = {
      DATABASE_URL = "postgres://user:pass@localhost:5432/care";
      REDIS_URL = "redis://localhost:6379/0";
      POSTGRES_HOST = "localhost";
      POSTGRES_PORT = "5432";
      REDIS_HOST = "localhost";
      REDIS_PORT = "6379";
      # Add S3/garage2 variables as needed
    };
  };
}
```

---

## Troubleshooting

- If you see errors about missing `care` package, ensure you have set `services.care.package` as shown above.
- If you update the flake, run `nix flake update` and rebuild your system.

---

## License
