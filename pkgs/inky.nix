# Inky https://www.inklestudios.com/ink/
# Editor for narrative scripting language Ink
{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  asar,
  makeDesktopItem,
  copyDesktopItems,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libxkbfile,
  systemd,
  libGL,
  vulkan-loader,
  icu,
  gsettings-desktop-schemas,
}:

stdenv.mkDerivation rec {
  pname = "inky";
  version = "0.15.2";

  src = fetchzip {
    url = "https://github.com/inkle/inky/releases/download/${version}/Inky_linux.zip";
    hash = "sha256-Oesw09et2tJOx1O1w0FOJje6F1+o0cTyBmziTAtKgw0=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    asar
    copyDesktopItems
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "inky";
      desktopName = "Inky";
      comment = "Editor for the Ink narrative scripting language";
      exec = "inky %F";
      icon = "inky";
      categories = [
        "Development"
        "TextEditor"
      ];
    })
  ];
  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxkbfile
    stdenv.cc.cc.lib
  ];
  # Loaded with dlopen at runtime, so the patcher can't see them. icu is for
  # the bundled inklecate, a self-contained .NET binary that refuses to start
  # without it.
  runtimeDependencies = [
    systemd
    libGL
    vulkan-loader
    icu
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/inky $out/bin
    cp -r . $out/opt/inky
    chmod +x $out/opt/inky/Inky
    # --no-sandbox: the sandbox helper can't be setuid in the store, and with it
    # on the renderers die and the window never appears. No ozone flags: this
    # Electron spins forever on native Wayland, so it runs through XWayland.
    # GSettings schemas are for the GTK file dialogs.
    makeWrapper $out/opt/inky/Inky $out/bin/inky \
      --add-flags "--no-sandbox" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}:${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
    asar extract-file $out/opt/inky/resources/app.asar renderer/about/icon256.png
    install -Dm644 icon256.png $out/share/icons/hicolor/256x256/apps/inky.png
    runHook postInstall
  '';

  meta = {
    description = "Editor for the Ink narrative scripting language";
    homepage = "https://github.com/inkle/inky";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "inky";
  };
}
