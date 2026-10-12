{
  lib,
  rustPlatform,
  fetchCrate,
}:

rustPlatform.buildRustPackage rec {
  pname = "wl-uinput-proxy";
  version = "0.0.3";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-1SVW4GNhx6LYmJftyJq61MFh/vnkZuRfemHKfQTKDTg=";
  };

  cargoHash = "sha256-IKewTBdB/FEjYaFhoFOnAV6KCocobHVLawAYHrBJHKc=";

  meta = {
    description = "Wayland proxy that turns virtual keyboard and pointer requests into uinput events";
    homepage = "https://github.com/pgaskin/wl-uinput-proxy";
    license = lib.licenses.mit;
    mainProgram = "wl-uinput-proxy";
  };
}
