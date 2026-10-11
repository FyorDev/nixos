# Application user settings
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  obsProfile = "Untitled";
  obsSettings = {
    "user.ini" = {
      General.FirstRun = "true";
      Basic = {
        Profile = obsProfile;
        ProfileDir = obsProfile;
      };
    };
    "basic/profiles/${obsProfile}/basic.ini" = {
      General.Name = obsProfile;
      Output.Mode = "Simple";
      SimpleOutput = {
        FilePath = "${config.users.users.${config.user.name}.home}/Videos/obs";
        RecFormat2 = "hybrid_mp4";
        RecQuality = "Small";
      };
      Video = {
        BaseCX = "3840";
        BaseCY = "2160";
        OutputCX = "3840";
        OutputCY = "2160";
        FPSType = "0";
        FPSCommon = "60";
      };
    };
  };

  obsSetIni =
    file: sections:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          section: keys:
          lib.mapAttrsToList (
            key: value:
            "${lib.getExe pkgs.crudini} --set \"$dir/${file}\" ${section} ${key} ${lib.escapeShellArg value}"
          ) keys
        ) sections
      )
    );
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    overwriteBackup = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} =
      { lib, ... }:
      {
        home.stateVersion = "26.05";

        home.activation.obsDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          dir="$HOME/.config/obs-studio"
          run mkdir -p "$HOME/Videos/obs" "$dir/basic/profiles/${obsProfile}"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList obsSetIni obsSettings)}
        '';

        programs = {
          fuzzel = {
            enable = true;
            settings.main = {
              font = lib.mkForce "${config.stylix.fonts.monospace.name}:size=12";
              icon-theme = "Papirus-Dark";
              terminal = "alacritty -e";
              width = 45;
              lines = 15;
            };
          };
          alacritty.enable = true;
          swaylock.enable = true;
          mpv.enable = true;
          zathura.enable = true;
          imv.enable = true;
          waybar = {
            enable = true;
            systemd.enable = true;
          };
        };

        services = {
          swayosd.enable = true;
          cliphist.enable = true;
          mako.enable = true;
          blueman-applet.enable = true;
          network-manager-applet.enable = true;
          swayidle = {
            enable = true;
            timeouts = [
              {
                timeout = 900;
                command = "${pkgs.swaylock}/bin/swaylock -f";
              }
            ];
          };
        };
      };
  };
}
