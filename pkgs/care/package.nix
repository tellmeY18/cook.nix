{ lib
, fetchFromGitHub
, python3
, makeWrapper
, pipInstallHook
}:

let
  # Path to your requirements lock file (should be in the same directory as this file)
  requirements = ./Pipfile.lock;
in

python3.pkgs.buildPythonApplication rec {
  pname = "care";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "ohcnetwork";
    repo = "care";
    rev = "v3.0.0";
    sha256 = "sha256-B7d+hiNYDVSDicukVakTl4g3d6dz8uEWy9skzlrfw5U=";
  };

  nativeBuildInputs = [ makeWrapper pipInstallHook ];

  # No propagatedBuildInputs: all dependencies are handled by pipInstallHook from requirements.lock
  propagatedBuildInputs = [ ];

  # Ensure pip only uses binary wheels from PyPI and hashes from the lock file
  pipInstallFlags = [
    "--require-hashes"
    "--no-deps"
    "--no-build-isolation"
    "--only-binary=:all:"
  ];

  # Copy the lock file into the build context
  postPatch = ''
    cp ${requirements} requirements.lock
  '';

  # Install dependencies from lock file using pipInstallHook
  installPhase = ''
    runHook preInstall
    pip install --prefix=$out --requirement requirements.lock --no-deps --no-build-isolation --only-binary=:all:
    runHook postInstall
  '';

  meta = with lib; {
    description = "Care backend";
    homepage = "https://github.com/ohcnetwork/care";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "manage.py";
  };
}
