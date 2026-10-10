# Application user settings
{
  config,
  inputs,
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
        firefox.enable = true;
      };
    };
  };
}
