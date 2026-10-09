{ config, inputs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.${config.user.name} = {
      home.stateVersion = "26.05";

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
