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
    sharedModules = [ inputs.spicetify-nix.homeManagerModules.default ];

    users.${config.user.name} = {
      home.stateVersion = "26.05";

      stylix.targets.firefox.profileNames = [ "default" ];
      stylix.targets.spicetify.enable = false;

      programs = {
        spicetify =
          let
            spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            enable = true;
            theme = spicePkgs.themes.catppuccin;
            colorScheme = "mocha";
            enabledExtensions = with spicePkgs.extensions; [
              adblockify
              keyboardShortcut
              history
              volumePercentage
            ];
          };
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
