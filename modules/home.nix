{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # gitignored, optional
  background = lib.findFirst builtins.pathExists null [
    ../background.png
    ../background.jpg
  ];
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} = lib.mkMerge [
      {
        home.stateVersion = "26.05";

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      }

      (lib.mkIf (background != null) {
        xdg.configFile."swaylock/config".text = ''
          image=${background}
          scaling=fill
        '';

        systemd.user.services.swaybg = {
          # Live background swapping
          Unit = {
            Description = "Wallpaper";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${background}";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      })
    ];
  };
}
