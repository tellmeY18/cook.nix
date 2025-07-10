{ lib, pkgs, ... }:

let
  pythonPackages = pkgs.python3.pkgs;
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

  # all your Python deps
  propagatedBuildInputs = with pythonPackages; [
    django
    djangorestframework
    celery
    redis
    gunicorn
    # …plus any others you listed in your Pipfile
  ];

  # expose manage.py / any entrypoints
  checkInputs = [ pythonPackages.pytest ];
  doCheck     = false;

  meta = with lib; {
    description = "CARE EMR backend";
    homepage    = "https://github.com/ohcnetwork/care";
    license     = licenses.mit;
    platforms   = platforms.linux;
  };
}
