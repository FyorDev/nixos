# Insomnium (maintained fork github.com/yokomohoyo/insomnium)
# To update: set version and hash
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "insomnium";
  version = "0.3.0-rc.18";
  src = fetchurl {
    url = "https://github.com/yokomohoyo/insomnium/releases/download/${version}/Insomnium.Core-${version}.AppImage";
    hash = "sha256-dWn6kPboxOYXsZv96xCJAkM5XhrLhqsnEJh5SReKHYc=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/insomnium.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/insomnium.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=insomnium'
    cp -r ${contents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Insomnium is a fast local API testing tool that is privacy-focused and 100% local. For testing GraphQL, REST, WebSockets and gRPC. This is a fork of Kong/insomnia";
    homepage = "https://github.com/yokomohoyo/insomnium";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "insomnium";
  };
}
