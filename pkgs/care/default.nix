{ lib, python3, fetchFromGitHub, celery, django, djangorestframework, redis, gunicorn, ... }:

python3.pkgs.buildPythonApplication rec {
  pname = "care";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner  = "ohcnetwork";
    repo   = "care";
    rev    = "v${version}";
    sha256 = lib.fakeSha256;  # replace on first build
  };

  # all your Python deps
  propagatedBuildInputs = with python3.pkgs; [
    django
    djangorestframework
    celery
    redis
    gunicorn
    # …plus any others you listed in your Pipfile
  ];

  # expose manage.py / any entrypoints
  checkInputs = [ python3.pkgs.pytest ];
  doCheck     = false;

  meta = with lib; {
    description = "CARE EMR backend";
    homepage    = "https://github.com/ohcnetwork/care";
    license     = licenses.mit;
    platforms   = platforms.linux;
  };
}

