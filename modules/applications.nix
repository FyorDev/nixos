# Application user settings
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    overwriteBackup = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} = {
      home.stateVersion = "26.05";

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
