# FMOD Studio sits behind a free fmod.com login, so there is no URL to pin.
# The first launch signs in with the agenix secret and caches the AppImage.
{
  writeShellApplication,
  makeDesktopItem,
  symlinkJoin,
  appimage-run,
  coreutils,
  curl,
  jq,
  libnotify,
  credentials,
}:

let
  # libraries the AppImage needs that appimage-run's FHS env lacks
  appimage-run' = appimage-run.override {
    extraPkgs =
      pkgs: with pkgs; [
        zstd
        libxshmfence
        libxkbfile
        libXau
      ];
  };

  fetch = writeShellApplication {
    name = "fmod-fetch";
    runtimeInputs = [
      curl
      jq
      coreutils
    ];
    text = builtins.readFile ./fmod-fetch.sh;
  };

  launcher = writeShellApplication {
    name = "fmodstudio";
    runtimeInputs = [
      appimage-run'
      coreutils
      libnotify
      fetch
    ];
    text = ''
      store="''${XDG_CACHE_HOME:-$HOME/.cache}/fmod-studio"

      fail() {
          echo "$*" >&2
          notify-send "FMOD Studio" "$*" || true
          exit 1
      }

      # find fails while the store dir is missing, which would trip pipefail
      newest() {
          { find "$store" -maxdepth 1 -name 'fmodstudio*.AppImage' 2>/dev/null || true; } |
              sort -V | tail -n1
      }

      mkdir -p "$store"
      appimage="$(newest)"

      if [ -z "$appimage" ]; then
          [ -r "${credentials}" ] || fail "Cannot read ${credentials}, see the secrets section of the README"

          # shellcheck source=/dev/null
          . "${credentials}"
          export FMOD_USERNAME FMOD_PASSWORD

          notify-send "FMOD Studio" "Downloading, about 210 MB" || true
          fmod-fetch "$store" || fail "Could not fetch FMOD Studio"

          appimage="$(newest)"
          [ -n "$appimage" ] || fail "No AppImage found in $store after fetching"
      fi

      exec appimage-run "$appimage" "$@"
    '';
  };

  desktopItem = makeDesktopItem {
    name = "fmodstudio";
    desktopName = "FMOD Studio";
    genericName = "FMOD Digital Audio Workstation for Games";
    exec = "fmodstudio";
    icon = "fmodstudio";
    categories = [
      "AudioVideo"
      "Audio"
    ];
  };
in
symlinkJoin {
  name = "fmodstudio";
  paths = [
    launcher
    desktopItem
  ];
  meta.mainProgram = "fmodstudio";
}
