{ config, pkgs, lib, ... }:

let
  wait4x = pkgs.wait4x;
in {
  options.services.care = {
    enable = lib.mkEnableOption "CARE EMR Django service";
    api = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CARE API (gunicorn)";
      };
    };
    worker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CARE celery worker";
      };
    };
    beat = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CARE celery beat";
      };
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        POSTGRES_HOST = "localhost";
        POSTGRES_PORT = "5432";
        POSTGRES_USER = "care";
        POSTGRES_PASSWORD = "care";
        POSTGRES_DB = "care";
        DATABASE_URL = "postgres://care:care@localhost:5432/care";
        REDIS_HOST = "localhost";
        REDIS_PORT = "6379";
        REDIS_AUTH_TOKEN = "";
        REDIS_DATABASE = "0";
        REDIS_URL = "redis://localhost:6379/0";
        # Add S3/garage2 defaults if needed
      };
      description = "Environment variables for CARE services, e.g. DATABASE_URL, REDIS_URL, etc.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "Which package to run for CARE";
      # No default - this will be set by the flake's nixosModule
    };
  };

  config = lib.mkIf config.services.care.enable {
    users.users.care = {
      isSystemUser = true;
      home = "/var/lib/care";
      createHome = true;
      group = "care";
    };

    users.groups.care = {};

    environment.systemPackages = with pkgs; [
      postgresql
      redis
      garage_2
      wait4x
      config.services.care.package
    ];

    # Django migration oneshot service
    systemd.services.care-migrate = {
      description = "CARE Django database migration and setup";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = config.services.care.environment // {
        DJANGO_SETTINGS_MODULE = "care.settings";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "/var/lib/care";
        User = "care";
        Group = "care";
        ExecStart = lib.concatStringsSep " && " [
          # Wait for PostgreSQL
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.POSTGRES_HOST or "localhost"}:${toString (config.services.care.environment.POSTGRES_PORT or 5432)} --timeout 60s"
          # Wait for Redis
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.REDIS_HOST or "localhost"}:${toString (config.services.care.environment.REDIS_PORT or 6379)} --timeout 60s"
          # Django migration commands
          "${config.services.care.package}/bin/python manage.py migrate --noinput"
          "${config.services.care.package}/bin/python manage.py compilemessages -v 0"
          "${config.services.care.package}/bin/python manage.py sync_permissions_roles"
          "${config.services.care.package}/bin/python manage.py sync_valueset"
        ];
      };
      wantedBy = [ "multi-user.target" ];
    };

    # API Service
    systemd.services.care-api = lib.mkIf config.services.care.api.enable {
      description = "CARE Django EMR API";
      after = [ "network-online.target" "care-migrate.service" ];
      requires = [ "care-migrate.service" ];
      wants = [ "network-online.target" ];
      environment = config.services.care.environment // {
        DJANGO_SETTINGS_MODULE = "care.settings";
      };
      serviceConfig = {
        ExecStartPre = lib.concatStringsSep " && " [
          # Wait for PostgreSQL
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.POSTGRES_HOST or "localhost"}:${toString (config.services.care.environment.POSTGRES_PORT or 5432)} --timeout 60s"
          # Wait for Redis
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.REDIS_HOST or "localhost"}:${toString (config.services.care.environment.REDIS_PORT or 6379)} --timeout 60s"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${config.services.care.package}/bin/gunicorn"
          "-w 4"
          "care.wsgi:application"
          "--bind" "0.0.0.0:8000"
        ];
        WorkingDirectory = "/var/lib/care";
        User = "care";
        Group = "care";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Celery Worker Service
    systemd.services.care-worker = lib.mkIf config.services.care.worker.enable {
      description = "CARE Celery Worker";
      after = [ "network-online.target" "care-migrate.service" ];
      requires = [ "care-migrate.service" ];
      wants = [ "network-online.target" ];
      environment = config.services.care.environment // {
        DJANGO_SETTINGS_MODULE = "care.settings";
      };
      serviceConfig = {
        ExecStartPre = lib.concatStringsSep " && " [
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.POSTGRES_HOST or "localhost"}:${toString (config.services.care.environment.POSTGRES_PORT or 5432)} --timeout 60s"
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.REDIS_HOST or "localhost"}:${toString (config.services.care.environment.REDIS_PORT or 6379)} --timeout 60s"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${config.services.care.package}/bin/celery"
          "--app=care.celery_app"
          "worker"
          "--max-tasks-per-child=6"
          "--loglevel=info"
        ];
        WorkingDirectory = "/var/lib/care";
        User = "care";
        Group = "care";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Celery Beat Service
    systemd.services.care-beat = lib.mkIf config.services.care.beat.enable {
      description = "CARE Celery Beat";
      after = [ "network-online.target" "care-migrate.service" ];
      requires = [ "care-migrate.service" ];
      wants = [ "network-online.target" ];
      environment = config.services.care.environment // {
        DJANGO_SETTINGS_MODULE = "care.settings";
      };
      serviceConfig = {
        ExecStartPre = lib.concatStringsSep " && " [
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.POSTGRES_HOST or "localhost"}:${toString (config.services.care.environment.POSTGRES_PORT or 5432)} --timeout 60s"
          "${wait4x}/bin/wait4x tcp ${config.services.care.environment.REDIS_HOST or "localhost"}:${toString (config.services.care.environment.REDIS_PORT or 6379)} --timeout 60s"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${config.services.care.package}/bin/celery"
          "--app=care.celery_app"
          "beat"
          "--loglevel=info"
        ];
        WorkingDirectory = "/var/lib/care";
        User = "care";
        Group = "care";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
