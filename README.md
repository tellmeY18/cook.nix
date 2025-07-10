# cook.nix

## CARE Django EMR on NixOS with dream2nix

This repository provides a NixOS module and a prebuilt Django EMR package (`care`) using [dream2nix](https://github.com/nix-community/dream2nix). It is designed for modern Nix Flake-based workflows and is fully declarative, reproducible, and binary-optimized.

---

## Quick Start

### 1. Add cook.nix as a flake input

In your `flake.nix`:

```nix
{
  inputs.cook.url = "github:tellmeY18/cook.nix";
  # ...other inputs
  outputs = { self, nixpkgs, cook, ... }@inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or your system
      modules = [
        cook.nixosModules.default
        # ...other modules
      ];
    };
  };
}
```

---

### 2. Enable CARE in your NixOS configuration

In your `configuration.nix` or as part of your flake-based module list:

```nix
{
  services.care = {
    enable = true;
    # Explicitly set the package from the flake outputs:
    package = inputs.cook.packages.${pkgs.system}.care;
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

---

### 3. What this does

- Installs the dream2nix-built `care` package and all dependencies.
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
- You **must** set `services.care.package` explicitly as shown above, because Nix flakes do not automatically pass outputs into module scope.
- For more advanced configuration, see the comments in `cook.nix/modules/care.nix`.

---

## Example Minimal Configuration

```nix
{
  services.care = {
    enable = true;
    package = inputs.cook.packages.${pkgs.system}.care;
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
