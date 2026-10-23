# Login and lock screens in Quickshell
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.user.name;
  weatherFile = "/var/cache/login-weather/weather.json";

  # systemd 261 deprecates niri-session calling import-environment without names
  niriSession = pkgs.writeShellScript "niri-session" ''
    exec ${config.programs.niri.package}/bin/niri-session "$@" 2> >(${pkgs.gnugrep}/bin/grep -v 'import-environment without a list' >&2)
  '';

  cavaConfig = pkgs.writeText "login-cava.conf" (
    lib.generators.toINI { } {
      general = {
        framerate = 60;
        bars = 40;
        sensitivity = 150;
      };
      input = {
        method = "pipewire";
        source = "auto";
      };
      output = {
        method = "raw";
        raw_target = "/dev/stdout";
        data_format = "ascii";
        ascii_max_range = 32;
        bar_delimiter = 59;
        channels = "mono";
        mono_option = "average";
      };
      smoothing = {
        noise_reduction = 0.2;
        gravity = 180;
      };
    }
  );

  settings = {
    inherit user weatherFile;
    users = lib.unique (
      [ user ] ++ lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users)
    );
    session = [ "${niriSession}" ];
    wallpaper = lib.optionalString (config.wallpaper != null) "file://${config.wallpaper}";
    place = "Utrecht";
    font = builtins.head config.fonts.fontconfig.defaultFonts.monospace;
    logo = lib.removeSuffix "\n" (builtins.readFile ../config/fastfetch/logo.txt);
    fastfetchCommand = [
      (lib.getExe config.users.users.${user}.shell)
      "-c"
      "${lib.getExe pkgs.fastfetch} -c ${
        config.home-manager.users.${user}.xdg.configFile."fastfetch/config.jsonc".source
      } --logo none --pipe false"
    ];
    cavaCommand = [
      (lib.getExe pkgs.cava)
      "-p"
      "${cavaConfig}"
    ];
  }
  //
    lib.mapAttrs (_: color: color.hex)
      (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
      .${config.catppuccin.flavor}.colors;

  settingsQml = pkgs.writeText "Settings.qml" ''
    pragma Singleton
    import Quickshell

    Singleton {
    ${
      lib.concatStrings (
        lib.mapAttrsToList (
          name: value: "    readonly property var ${name}: ${builtins.toJSON value}\n"
        ) settings
      )
    }}
  '';

  shells = pkgs.runCommand "login-shells" { } ''
    for kind in lock greeter; do
      mkdir -p $out/$kind
      cp ${../config/quickshell/common}/*.qml ${../config/quickshell}/$kind/shell.qml $out/$kind/
      cp ${settingsQml} $out/$kind/Settings.qml
    done
  '';

  greeter = pkgs.writeShellScript "login-greeter" ''
    state=''${XDG_RUNTIME_DIR:-/tmp/greeter}/quickshell
    export XDG_CACHE_HOME=$state XDG_STATE_HOME=$state XDG_DATA_HOME=$state
    export QT_QPA_PLATFORM=wayland QT_SCALE_FACTOR=${toString config.displayScale}
    exec ${lib.getExe pkgs.quickshell} -p ${shells}/greeter
  '';
in
{
  environment.systemPackages = [ pkgs.quickshell ];
  environment.etc."xdg/quickshell/lock".source = "${shells}/lock";
  security.pam.services.quickshell-lock = { };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.cage} -s -d -- ${greeter}";
      user = "greeter";
    };
  };

  systemd.services.login-weather = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    startAt = "*:0/30";
    path = [
      pkgs.curl
      pkgs.jq
    ];
    script = ''
      set -o pipefail
      curl -fsS --max-time 30 https://forecast.buienradar.nl/2.0/forecast/2745912 \
        | jq -f ${../config/quickshell/weather.jq} > "$CACHE_DIRECTORY/new.json"
      mv "$CACHE_DIRECTORY/new.json" ${weatherFile}
    '';
    serviceConfig = {
      Type = "oneshot";
      CacheDirectory = "login-weather";
    };
  };
}
