# cook.nix

## CARE Cookbook Usage

This cookbook provides a pure Nix module for running the CARE Django EMR application, including API, Celery worker, and Celery beat roles, with automatic migrations and dependency management.

### How to Use

1. **Import the Module**

   In your NixOS configuration, import the CARE module:

   ```nix
   {
     imports = [
       /path/to/cook.nix/modules/care.nix
     ];
   }
   ```

2. **Enable CARE Services**

   Enable the CARE service and select which roles you want to run:

   ```nix
   services.care = {
     enable = true;
     api.enable = true;      # Enable the API (gunicorn)
     worker.enable = true;   # Enable the Celery worker
     beat.enable = true;     # Enable the Celery beat
   };
   ```

3. **Set Environment Variables**

   Configure all required environment variables for your deployment:

   ```nix
   services.care.environment = {
     DATABASE_URL = "postgres://user:pass@host:5432/dbname";
     REDIS_URL = "rediss://:password@host:6379/0?ssl_cert_reqs=none";
     POSTGRES_HOST = "localhost";
     POSTGRES_PORT = "5432";
     REDIS_HOST = "localhost";
     REDIS_PORT = "6379";
     # Add S3/garage2 or other variables as needed
   };
   ```

4. **Automatic Migrations**

   Every time the CARE package or configuration changes, a systemd oneshot service (`care-migrate`) will automatically run the following Django commands before starting any CARE service:

   - `python manage.py migrate --noinput`
   - `python manage.py compilemessages -v 0`
   - `python manage.py sync_permissions_roles`
   - `python manage.py sync_valueset`

   All main services (`care-api`, `care-worker`, `care-beat`) will wait for migrations to complete before starting.

5. **Dependencies**

   The module ensures the following dependencies are available on your system:
   - PostgreSQL
   - Redis
   - garage_2 (S3-compatible object store)
   - wait4x (for service readiness checks)

   These are added to your system environment automatically.

### Example Minimal Configuration

```nix
{
  imports = [
    /path/to/cook.nix/modules/care.nix
  ];

  services.care = {
    enable = true;
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

### Notes

- No impure scripting or bash is used; all orchestration is handled via pure Nix and systemd.
- You can further customize the environment and service options as needed.
- For advanced S3/garage2 configuration, add the relevant environment variables.
