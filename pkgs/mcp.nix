# MCP server packages, wired up in modules/claude.nix
{ callPackage }:
{
  blender = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
    }:

    python3Packages.buildPythonApplication {
      pname = "mcp-for-blender";
      version = "2.1.8";
      pyproject = true;

      src = fetchFromGitHub {
        owner = "ahujasid";
        repo = "blender-mcp";
        rev = "34b7bd277fff75a693cde78930b4359478958a01";
        hash = "sha256-g3AAh3spVYxL1WwdO8WlyzuTFzrVu4dIEJttHRVS618=";
      };

      build-system = [ python3Packages.setuptools ];
      dependencies = with python3Packages; [
        mcp
        httpx
      ];

      doCheck = false;
      pythonImportsCheck = [ "blender_mcp" ];

      # The Blender add-on the server talks to, so it can be installed declaratively
      postInstall = ''
        ln -s $out/${python3Packages.python.sitePackages}/blender_mcp/bundled/addon.py $out/addon.py
      '';

      meta = {
        description = "Connect Blender to LLMs through the Model Context Protocol";
        homepage = "https://github.com/ahujasid/blender-mcp";
        license = lib.licenses.mit;
        mainProgram = "mcp-for-blender";
      };
    }
  ) { };

  # Runs the compound server (src/server.py) against the scripting library that
  # ships inside the davinci-resolve package. Resolve itself has to be running
  # with Preferences > System > General > External scripting using set to Local.
  "davinci-resolve" = callPackage (
    {
      lib,
      stdenv,
      fetchFromGitHub,
      makeWrapper,
      python3,
      util-linux,
      davinci-resolve,
    }:

    let
      python = python3.withPackages (ps: [ ps.mcp ]);
      resolve = davinci-resolve.passthru.davinci;
    in
    stdenv.mkDerivation {
      pname = "davinci-resolve-mcp";
      version = "0-unstable-2026-10-06";

      src = fetchFromGitHub {
        owner = "samuelgursky";
        repo = "davinci-resolve-mcp";
        rev = "ea77afdf0209b9d061500ff10c5cade88d22cd21";
        hash = "sha256-1yIjyaRtJcBCn0fQ68xdWjk8PdBR1tByhlSOIdWuhec=";
      };

      nativeBuildInputs = [ makeWrapper ];

      dontBuild = true;
      installPhase = ''
        mkdir -p $out/lib/davinci-resolve-mcp
        cp -r src $out/lib/davinci-resolve-mcp/
        # The server makes a logs/ directory next to itself at import time, which
        # cannot exist in the store
        ln -s /tmp $out/lib/davinci-resolve-mcp/logs
        makeWrapper ${python}/bin/python $out/bin/davinci-resolve-mcp \
          --add-flags $out/lib/davinci-resolve-mcp/src/server.py \
          --set-default RESOLVE_SCRIPT_API ${resolve}/Developer/Scripting \
          --set-default RESOLVE_SCRIPT_LIB ${resolve}/libs/Fusion/fusionscript.so \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ util-linux.lib ]}
      '';

      meta = {
        description = "MCP server for DaVinci Resolve's scripting API";
        homepage = "https://github.com/samuelgursky/davinci-resolve-mcp";
        license = lib.licenses.mit;
        mainProgram = "davinci-resolve-mcp";
      };
    }
  ) { };

  # Two halves: the MCP server (bin/freecad-mcp) and the FreeCAD add-on it talks
  # to over XML-RPC (share/freecad-mcp/Mod/FreeCADMCP).
  freecad = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
    }:

    python3Packages.buildPythonApplication {
      pname = "freecad-mcp";
      version = "0.1.25";
      pyproject = true;

      src = fetchFromGitHub {
        owner = "neka-nat";
        repo = "freecad-mcp";
        rev = "8e14693a9b46b50a3656cbdd9c2922456bb3bd06";
        hash = "sha256-nO6Q5W6fBjaIqb0Nev73gdwYwdBB//pYr/sArTpdc64=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        mcp
        validators
      ];
      pythonRelaxDeps = true;

      postInstall = ''
        mkdir -p $out/share/freecad-mcp/Mod
        cp -r addon/FreeCADMCP $out/share/freecad-mcp/Mod/
      '';

      doCheck = false;
      pythonImportsCheck = [ "freecad_mcp" ];

      meta = {
        description = "MCP server and add-on that let an AI drive FreeCAD";
        homepage = "https://github.com/neka-nat/freecad-mcp";
        license = lib.licenses.mit;
        mainProgram = "freecad-mcp";
      };
    }
  ) { };

  inkscape = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
      inkscape,
    }:

    python3Packages.buildPythonApplication {
      pname = "inkscape-mcp";
      version = "0-unstable-2025-10-22";
      pyproject = true;

      src = fetchFromGitHub {
        owner = "grumpydevorg";
        repo = "inkscape-mcps";
        rev = "e621da1a8287896fa3a7bf8e3cf4fd6a9c2f87ea";
        hash = "sha256-P+84x+jHg+o0ddsZzwaIHaRZXKzh63gJK9r14x3gFQU=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        fastmcp
        pydantic
        anyio
        filelock
        inkex
        scour
      ];
      # scour is pinned <0.38 upstream, nixpkgs has 0.38
      pythonRelaxDeps = true;

      makeWrapperArgs = [
        "--set-default"
        "INKS_INKSCAPE_BIN"
        "${inkscape}/bin/inkscape"
      ];

      doCheck = false;
      pythonImportsCheck = [ "inkscape_mcp" ];

      meta = {
        description = "MCP server for Inkscape's command line and SVG document tools";
        homepage = "https://github.com/grumpydevorg/inkscape-mcps";
        license = lib.licenses.mit;
        mainProgram = "inkscape-mcp";
      };
    }
  ) { };

  kicad = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
      kicad,
    }:

    python3Packages.buildPythonApplication {
      pname = "kicad-mcp";
      version = "0.1.0";
      pyproject = true;

      src = fetchFromGitHub {
        owner = "lamaalrajih";
        repo = "kicad-mcp";
        rev = "98c9ea41cb393393a8bafd157a93e84431e00afb";
        hash = "sha256-45+uc0QMqQKCRkmUOq/+F36Ap4Ab3iiJy0kTqDz2SeI=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        mcp
        fastmcp
        pandas
        pyyaml
        defusedxml
      ];
      pythonRelaxDeps = true;

      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath [ kicad ])
      ];

      doCheck = false;
      pythonImportsCheck = [ "kicad_mcp" ];

      meta = {
        description = "MCP server for KiCad projects, schematics and PCBs";
        homepage = "https://github.com/lamaalrajih/kicad-mcp";
        license = lib.licenses.mit;
        mainProgram = "kicad-mcp";
      };
    }
  ) { };

  # Two halves: the MCP server (bin/krita-mcp) and the Krita plugin it talks to
  # over HTTP on localhost:5678 (share/krita-mcp/pykrita).
  krita = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3,
      makeWrapper,
      stdenvNoCC,
    }:

    let
      python = python3.withPackages (ps: [
        ps.fastmcp
        ps.httpx
      ]);
    in
    stdenvNoCC.mkDerivation {
      pname = "krita-mcp";
      version = "0-unstable-2026-02-26";

      src = fetchFromGitHub {
        owner = "nanayax3";
        repo = "krita-mcp";
        rev = "5019f58852176aeeb11805126360ff749cd70dce";
        hash = "sha256-X+riZ8HpP6mwpMGkX2fxCvEYn/lGqVRq7VmltLmxMBM=";
      };

      nativeBuildInputs = [ makeWrapper ];
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        install -Dm644 server.py $out/lib/krita-mcp/server.py
        makeWrapper ${python}/bin/python $out/bin/krita-mcp --add-flags $out/lib/krita-mcp/server.py
        mkdir -p $out/share/krita-mcp/pykrita
        cp -r krita-plugin/kritamcp krita-plugin/kritamcp.desktop $out/share/krita-mcp/pykrita/
        runHook postInstall
      '';

      meta = {
        description = "MCP server and plugin that let an AI paint in Krita";
        homepage = "https://github.com/nanayax3/krita-mcp";
        license = lib.licenses.mit;
        mainProgram = "krita-mcp";
      };
    }
  ) { };

  nmap = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
      nmap,
    }:

    python3Packages.buildPythonApplication {
      pname = "nmap-mcp";
      version = "0.1.0";
      pyproject = true;

      src = fetchFromGitHub {
        owner = "Vorota-ai";
        repo = "nmap-mcp";
        rev = "3636afa6ad4e159c7ad07ca35ede644f37db9c5e";
        hash = "sha256-zecAab28mecYdkNLmYjkfvOFsn+x9UQZLoTVaLOPw9w=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        mcp
        pydantic
        loguru
      ];
      pythonRelaxDeps = true;

      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath [ nmap ])
      ];

      doCheck = false;
      pythonImportsCheck = [ "nmap_mcp" ];

      meta = {
        description = "MCP server that runs nmap scans";
        homepage = "https://github.com/Vorota-ai/nmap-mcp";
        license = lib.licenses.mit;
        mainProgram = "nmap-mcp";
      };
    }
  ) { };

  obsidian = callPackage (
    {
      lib,
      fetchFromGitHub,
      buildNpmPackage,
    }:

    buildNpmPackage {
      pname = "obsidian-mcp";
      version = "2.0.0";

      src = fetchFromGitHub {
        owner = "StevenStavrakis";
        repo = "obsidian-mcp";
        rev = "bd900974adc6d7451f1f9d0f09d46b14307714f8";
        hash = "sha256-5iI6UZrMpMKQv9tznZEl6qe8OT8r3VypFd5DRnLCFUw=";
      };

      npmDepsHash = "sha256-waw/XF+nE4+sPsElSDLVYCbXv/jo+iXue5CdCN2o7k8=";

      meta = {
        description = "Local MCP server for reading and editing Obsidian vaults";
        homepage = "https://github.com/StevenStavrakis/obsidian-mcp";
        license = lib.licenses.mit;
        mainProgram = "obsidian-mcp";
      };
    }
  ) { };

  obs = callPackage (
    {
      lib,
      python3Packages,
      fetchPypi,
    }:

    python3Packages.buildPythonApplication rec {
      pname = "obs-studio-mcp";
      version = "0.5.1";
      pyproject = true;

      src = fetchPypi {
        pname = "obs_studio_mcp";
        inherit version;
        hash = "sha256-IUxynsbIlvp/bMePDTlAr2AQ9rg8RaQHRC+R34tfFJo=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        mcp
        obsws-python
      ];
      pythonRelaxDeps = true;

      doCheck = false;
      pythonImportsCheck = [ "obs_studio_mcp" ];

      meta = {
        description = "MCP server that controls OBS Studio over obs-websocket";
        homepage = "https://github.com/aaronckj/obs-studio-mcp";
        license = lib.licenses.mit;
        mainProgram = "obs-studio-mcp";
      };
    }
  ) { };

  wireshark = callPackage (
    {
      lib,
      fetchFromGitHub,
      python3Packages,
      wireshark-cli,
    }:

    python3Packages.buildPythonApplication {
      pname = "wireshark-mcp";
      version = "2.0.0";
      pyproject = true;

      # v3 needs the MCP SDK 2.x, nixpkgs has 1.x
      src = fetchFromGitHub {
        owner = "bx33661";
        repo = "Wireshark-MCP";
        rev = "v2.0.0";
        hash = "sha256-1uS5kbk658bcxcudHadFKBJLOdKDaNS7XPDai57xnhc=";
      };

      build-system = [ python3Packages.hatchling ];
      dependencies = with python3Packages; [
        mcp
        pyyaml
      ];

      makeWrapperArgs = [
        "--prefix"
        "PATH"
        ":"
        (lib.makeBinPath [ wireshark-cli ])
      ];

      doCheck = false;
      pythonImportsCheck = [ "wireshark_mcp" ];

      meta = {
        description = "MCP server that wraps tshark for packet capture analysis";
        homepage = "https://github.com/bx33661/Wireshark-MCP";
        license = lib.licenses.mit;
        mainProgram = "wireshark-mcp";
      };
    }
  ) { };
}
