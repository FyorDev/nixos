# Term, a GPU rendered terminal, editor and git client.
# Built with crane so the ~300 dependencies are their own derivation and only
# rebuild when Cargo.lock changes. The source is a private repo flake input, so
# evaluation needs your SSH key: rebuild with --sudo so it runs as you, not root.
{
  lib,
  craneLib,
  src,
  pkg-config,
  makeWrapper,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libGL,
  libglvnd,
  fontconfig,
  freetype,
  libxml2,
  libX11,
  libxcursor,
  libxi,
  libxrandr,
}:
let
  # wgpu and winit dlopen these at run time
  runtimeLibs = [
    vulkan-loader
    libGL
    libglvnd
    wayland
    libxkbcommon
    libX11
    libxcursor
    libxi
    libxrandr
  ];

  common = {
    inherit src;
    pname = "term";
    version = "0.1.0";
    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
      makeWrapper
    ];
    buildInputs = [
      wayland
      libxkbcommon
      fontconfig
      freetype
      libxml2
    ]
    ++ runtimeLibs;
  };

  cargoArtifacts = craneLib.buildDepsOnly common;
in
craneLib.buildPackage (
  common
  // {
    inherit cargoArtifacts;

    # only the app crate has a binary
    cargoExtraArgs = "--package term";

    postInstall = ''
      wrapProgram $out/bin/term \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

      install -Dm644 /dev/stdin $out/share/applications/term.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=Term
      GenericName=Terminal
      Comment=GPU rendered terminal, file explorer, editor, git client and Claude Code front end
      Exec=term
      Terminal=false
      Categories=System;TerminalEmulator;Development;
      EOF
    '';

    meta = {
      description = "GPU rendered terminal, file explorer, editor, git client and Claude Code front end";
      homepage = "https://github.com/FyorDev/Term";
      license = lib.licenses.unfree; # private repo, no licence declared
      platforms = [ "x86_64-linux" ];
      mainProgram = "term";
    };
  }
)
