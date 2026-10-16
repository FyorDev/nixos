# Signal Desktop with the Catppuccin stylesheet appended to its app.asar.
# Signal has no theme or user CSS hook. The finished package is copied and
# patched instead of using overrideAttrs, which would rebuild Signal from source.
{
  runCommand,
  signal-desktop,
  asar,
  fetchurl,
  makeWrapper,
  flavor ? "mocha",
}:

let
  theme = fetchurl {
    url = "https://raw.githubusercontent.com/CalfMoon/signal-desktop/main/themes/catppuccin-${flavor}.css";
    hash = "sha256-G+SXzbqgdd4DMoy6L+RW5xdoMMj3oCfd6hyalVnPkR4=";
  };
in
runCommand "signal-desktop-catppuccin-${flavor}"
  {
    nativeBuildInputs = [
      asar
      makeWrapper
    ];
    inherit (signal-desktop) meta;
  }
  ''
    cp -r ${signal-desktop} $out
    chmod -R u+w $out
    app=$out/share/signal-desktop

    asar extract "$app/app.asar" app-src

    # manifest.css is minified onto one line, so an @import would not be at the
    # top and would be ignored: append the rules instead
    cat ${theme} >> app-src/stylesheets/manifest.css

    rm -rf "$app/app.asar" "$app/app.asar.unpacked"
    # the native modules must stay outside the archive or electron cannot load them
    asar pack app-src "$app/app.asar" --unpack "*.node"
    test "$(find "$app/app.asar.unpacked" -name '*.node' | wc -l)" -ge 4

    # the launcher hardcodes the path it loads the archive from
    substituteInPlace $out/bin/signal-desktop --replace-fail ${signal-desktop} $out

    # the renderer Media thread traps on NVIDIA under wayland with hardware video decoding
    wrapProgram $out/bin/signal-desktop \
      --add-flags "--disable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiVideoDecoder"
  ''
