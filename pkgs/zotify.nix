{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication {
  pname = "zotify";
  version = "0.6.14-unstable-2024-09-01";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zotify-dev";
    repo = "zotify";
    rev = "08d844fe3e644ae6cd9bea34a3b4982e61129f33";
    hash = "sha256-4xiqAaAawpO/GsjPq8G4QkLAlSMZIRcYC5pO9Q0Bfuk=";
  };

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    ffmpy
    librespot
    music-tag
    pillow
    protobuf
    pwinput
    requests
    tabulate
    tqdm
  ];

  # upstream pins protobuf==3.20.1 and pulls librespot from git
  pythonRelaxDeps = [ "protobuf" ];
  pythonRemoveDeps = [ "librespot" ];

  # librespot's generated protobuf code is too old for the protobuf in nixpkgs
  makeWrapperArgs = [
    "--set"
    "PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"
    "python"
  ];

  doCheck = false;

  meta = {
    description = "Music and podcast downloader using Spotify's own streams";
    homepage = "https://github.com/zotify-dev/zotify";
    license = lib.licenses.unlicense;
    mainProgram = "zotify";
  };
}
