{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs"; # TODO: remove when niri-flake fixed
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs.lib) mkOption types;
      hosts = [
        "asus"
        "legion"
      ];

      mkHost =
        name:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { disabledModules = [ "programs/wayland/niri.nix" ]; }
            inputs.niri.nixosModules.niri
            inputs.home-manager.nixosModules.home-manager
            ./modules/common.nix
            ./modules/home.nix
            ./modules/shell.nix
            ./modules/packages.nix
            ./hosts/${name}/configuration.nix
            { networking.hostName = name; }
            {
              options = {
                hostLabel = mkOption {
                  type = types.str;
                  description = "Host label shown by fastfetch";
                };
                user = {
                  name = mkOption {
                    type = types.str;
                    description = "Your username";
                  };
                  git = {
                    name = mkOption {
                      type = types.str;
                      description = "git user.name";
                    };
                    email = mkOption {
                      type = types.str;
                      description = "git user.email";
                    };
                    signingKey = mkOption {
                      type = types.str;
                      default = "~/.ssh/id_rsa.pub";
                      description = "SSH public key for commit signing";
                    };
                  };
                };
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = inputs.nixpkgs.lib.genAttrs hosts mkHost;
    };
}
