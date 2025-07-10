{ lib, pkgs, ... }:

let
  python = pkgs.python314;
  pythonPackages = python.pkgs;
in pythonPackages.buildPythonApplication rec {
  pname = "care";
  version = "3.0.0";
  pyproject = true;
  build-system = [ pythonPackages.setuptools ];

  src = pkgs.fetchFromGitHub {
    owner  = "ohcnetwork";
    repo   = "care";
    rev    = "v${version}";
    sha256 =  "sha256-B7d+hiNYDVSDicukVakTl4g3d6dz8uEWy9skzlrfw5U=";
  };

  propagatedBuildInputs = with pythonPackages; [
    argon2-cffi
    authlib
    boto3
    celery
    django
    django-environ
    django-cors-headers
    django-filter
    django-maintenance-mode
    django-queryset-csv
    django-ratelimit
    django-redis
    django-rest-passwordreset
    django-simple-history
    djangoql
    djangorestframework
    djangorestframework-simplejwt
    dry-rest-permissions
    drf-nested-routers
    drf-spectacular
    gunicorn
    healthy-django
    json-fingerprint
    jsonschema
    newrelic
    pillow
    psycopg
    pydantic
    pyjwt
    python-slugify
    pywebpush
    redis
    redis-om
    requests
    simplejson
    sentry-sdk
    whitenoise
    django-anymail
    pydantic-extra-types
    phonenumberslite
    # Add any other dependencies as needed
    hiredis
  ];

  checkInputs = [ pythonPackages.pytest ];
  doCheck     = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/care
    cp -r . $out/lib/care
    chmod +x $out/lib/care/manage.py

    # Create a wrapper for manage.py
    makeWrapper $out/lib/care/manage.py $out/bin/care-manage \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --set DJANGO_SETTINGS_MODULE config.settings.staging

    # Create wrappers for gunicorn and celery
    makeWrapper ${lib.getExe pythonPackages.gunicorn} $out/bin/care-gunicorn \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --set DJANGO_SETTINGS_MODULE config.settings.staging

    makeWrapper ${lib.getExe pythonPackages.celery} $out/bin/care-celery \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --set DJANGO_SETTINGS_MODULE config.settings.staging

    runHook postInstall
  '';

  meta = with lib; {
    description = "CARE EMR backend";
    homepage    = "https://github.com/ohcnetwork/care";
    license     = licenses.mit;
    platforms   = platforms.linux;
  };
}
