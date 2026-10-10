# Application user settings
{
  config,
  inputs,
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

      stylix.targets.firefox.profileNames = [ "default" ];

      programs = {
        fuzzel.enable = true;
        alacritty.enable = true;
        swaylock.enable = true;
        mpv.enable = true;
        zathura.enable = true;
        imv.enable = true;
        firefox.enable = true;
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
