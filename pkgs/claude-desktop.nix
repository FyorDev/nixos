# Claude Desktop, from Anthropic's official Linux (beta) .deb.
# To update, take latest version and update hash
# https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
{
  lib,
  stdenvNoCC,
  fetchurl,
  libarchive,
  buildFHSEnv,
}:

let
  version = "2.9939.4";

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "claude-desktop-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
      hash = "sha256-PP3bI78pEeBeJ7TtOFa455XflGQ7LDW1nesxfPmVvKA=";
    };

    nativeBuildInputs = [ libarchive ];
    dontUnpack = true;
    dontFixup = true; # keep the bundled Electron untouched

    installPhase = ''
      # bsdtar drops setuid bits (chrome-sandbox), which Nix doesn't allow
      mkdir -p $out
      bsdtar -xOf $src 'data.tar.*' | bsdtar -xf - -C $out
    '';
  };
in
buildFHSEnv {
  pname = "claude-desktop";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
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
      libGL
      libnotify
      libsecret
      libuuid
      libxkbcommon
      nspr
      nss
      pango
      udev
      xdg-utils
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxtst
    ];

  runScript = "${unwrapped}/usr/lib/claude-desktop/claude-desktop";

  extraInstallCommands = ''
    install -Dm444 ${unwrapped}/usr/share/applications/com.anthropic.Claude.desktop -t $out/share/applications
    sed -i 's|^Exec=[^ ]*|Exec=claude-desktop|; /^TryExec=/d' $out/share/applications/com.anthropic.Claude.desktop
    cp -r ${unwrapped}/usr/share/icons $out/share
  '';

  meta = {
    description = "All of Claude, in one app. Works with your files and apps to get things done.";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
