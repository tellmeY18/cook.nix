{ lib, pkgs, mach-nix, ... }:

let
  pname = "care";
  version = "3.0.0";
  src = pkgs.fetchFromGitHub {
    owner  = "ohcnetwork";
    repo   = "care";
    rev    = "v${version}";
    sha256 = "sha256-B7d+hiNYDVSDicukVakTl4g3d6dz8uEWy9skzlrfw5U=";
  };
  pythonVersion = "3.14";
in
mach-nix.buildPythonApplication {
  inherit pname version src;
  python = pythonVersion;
  # Use Pipfile.lock if available, else Pipfile, else requirements.txt
  requirements = "Pipfile.lock";
  # If you want to use Pipfile or requirements.txt instead, change above line accordingly.

  # Optionally, you can set extraBuildInputs if you need system libraries
  # extraBuildInputs = [ pkgs.postgresql pkgs.redis ];

  # Post-install: create wrappers for manage.py, gunicorn, and celery
  postInstall = ''
    mkdir -p $out/bin
    makeWrapper $out/lib/${pname}/manage.py $out/bin/care-manage \
      --set DJANGO_SETTINGS_MODULE config.settings.staging
    makeWrapper ${pkgs.gunicorn}/bin/gunicorn $out/bin/care-gunicorn \
      --set DJANGO_SETTINGS_MODULE config.settings.staging
    makeWrapper ${pkgs.celery}/bin/celery $out/bin/care-celery \
      --set DJANGO_SETTINGS_MODULE config.settings.staging
  '';

  meta = with lib; {
    description = "CARE EMR backend";
    homepage    = "https://github.com/ohcnetwork/care";
    license     = licenses.mit;
    platforms   = platforms.linux;
  };
}
