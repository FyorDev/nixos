# What the Quickshell shells in login.nix and bar.nix have in common
{
  config,
  lib,
  pkgs,
}:
{
  palette =
    lib.mapAttrs (_: color: color.hex)
      (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
      .${config.catppuccin.flavor}.colors;

  # one line of semicolon separated levels per frame, up to 32
  cavaConfig =
    name: bars:
    pkgs.writeText name (
      lib.generators.toINI { } {
        general = {
          framerate = 60;
          inherit bars;
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

  # The Settings singleton the QML files read
  settingsQml =
    settings:
    pkgs.writeText "Settings.qml" ''
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
}
