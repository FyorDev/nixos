# CurseForge AppImage
# To update: take the newest version from https://curseforge.com/download/app
# and fix hash
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "curseforge";
  version = "1.321.1-39714";
  src = fetchurl {
    url = "https://curseforge.overwolf.com/electron/linux/CurseForge-${version}.AppImage";
    hash = "sha256-4DQZNlrJGY1gGAyqB74+vhhI9lCDPAEQrayhSX5G0Uc=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/curseforge.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/curseforge.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=curseforge'
    cp -r ${contents}/usr/share/icons $out/share
  '';

  meta = {
    description = "CurseForge desktop client for mods and modpacks";
    homepage = "https://curseforge.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "curseforge";
  };
}
