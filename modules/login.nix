# Login and lock screens in Quickshell
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.user.name;
  shared = import ../pkgs/quickshell-lib.nix { inherit config lib pkgs; };
  weatherFile = "/var/cache/login-weather/weather.json";

  # systemd 261 deprecates niri-session calling import-environment without names
  niriSession = pkgs.writeShellScript "niri-session" ''
    exec ${config.programs.niri.package}/bin/niri-session "$@" 2> >(${pkgs.gnugrep}/bin/grep -v 'import-environment without a list' >&2)
  '';

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
      "${shared.cavaConfig "login-cava.conf" 40}"
    ];
  }
  // shared.palette;

  settingsQml = shared.settingsQml settings;

  shells = pkgs.runCommand "login-shells" { } ''
    for kind in lock greeter; do
      mkdir -p $out/$kind
      cp ${../config/quickshell/common}/*.qml $out/$kind/
      cp ${settingsQml} $out/$kind/Settings.qml
    done
    cp ${../config/quickshell/lock/shell.qml} $out/lock/shell.qml
    cp ${../config/quickshell/greeter/shell.qml} $out/greeter/shell.qml
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
