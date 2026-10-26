# Top bar in Quickshell, colors from catppuccin/nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.user.name;
  shared = import ../pkgs/quickshell-lib.nix { inherit config lib pkgs; };

  tempo = pkgs.writeShellApplication {
    name = "bar-tempo";
    runtimeInputs = with pkgs; [
      playerctl
      pipewire
      wireplumber
      aubio
      coreutils
    ];
    text = ''
      exec ${lib.getExe pkgs.python3} ${../config/quickshell/bar/tempo.py}
    '';
  };

  settings = {
    font = builtins.head config.fonts.fontconfig.defaultFonts.monospace;
    cavaCommand = [
      (lib.getExe pkgs.cava)
      "-p"
      "${shared.cavaConfig "bar-cava.conf" 40}"
    ];
    tempoCommand = [ (lib.getExe tempo) ];
    niri = "${config.programs.niri.package}/bin/niri";
    ip = "${pkgs.iproute2}/bin/ip";
    curl = lib.getExe pkgs.curl;
    makoctl = "${pkgs.mako}/bin/makoctl";
    pgrep = "${pkgs.procps}/bin/pgrep";
    pkill = "${pkgs.procps}/bin/pkill";
  }
  // shared.palette;

  settingsQml = shared.settingsQml settings;

  shell = pkgs.runCommand "bar-shell" { } ''
    mkdir $out
    cp ${../config/quickshell/common}/{AnalogClock,Markup}.qml ${../config/quickshell/bar}/*.qml $out/
    cp ${settingsQml} $out/Settings.qml
  '';
in
{
  home-manager.users.${user}.systemd.user.services.bar = {
    Unit = {
      Description = "Top bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.quickshell} --no-duplicate -p ${shell}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
