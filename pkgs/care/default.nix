{ lib, pkgs, ... }:

let
  python = pkgs.python314;
  pythonPackages = python.pkgs;
in pythonPackages.buildPythonApplication rec {
  pname = "care";
  version = "3.0.0";
  src = pkgs.fetchFromGitHub {
    owner  = "ohcnetwork";
    repo   = "care";
    rev    = "v${version}";
    sha256 =  "sha256-B7d+hiNYDVSDicukVakTl4g3d6dz8uEWy9skzlrfw5U=";
  };

  # Use pip to install all dependencies from Pipfile or requirements.txt in the source repo
  format = "other";
  # pip is required for install
  propagatedBuildInputs = [ pythonPackages.pip ];

  # If the repo does not contain requirements.txt, you can generate it from Pipfile.lock
  # Here we assume requirements.txt or Pipfile/Pipfile.lock is present in the repo

  installPhase = ''
    runHook preInstall

    # Prefer requirements.txt, fallback to Pipfile if needed
    if [ -f requirements.txt ]; then
      reqfile=requirements.txt
    elif [ -f Pipfile.lock ]; then
      # Use pipenv to generate requirements.txt from Pipfile.lock
      ${pythonPackages.pipenv}/bin/pipenv lock --requirements > requirements.txt
      reqfile=requirements.txt
    elif [ -f Pipfile ]; then
      # Use pipenv to generate requirements.txt from Pipfile
      ${pythonPackages.pipenv}/bin/pipenv lock --requirements > requirements.txt
      reqfile=requirements.txt
    else
      echo "No requirements.txt or Pipfile found!"
      exit 1
    fi

    # Install all dependencies with pip
    ${pythonPackages.pip}/bin/pip install --prefix=$out --no-cache-dir -r $reqfile

    mkdir -p $out/lib/care
    cp -r . $out/lib/care
    chmod +x $out/lib/care/manage.py

    makeWrapper $out/lib/care/manage.py $out/bin/care-manage \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --set DJANGO_SETTINGS_MODULE config.settings.staging

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
