{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    # last nixos-unstable with the mcp 1.x Python SDK, for the MCP servers in modules/claude.nix
    nixpkgs-mcp.url = "https://releases.nixos.org/nixos/unstable/nixos-26.11pre1097682.02c087f3fe67/nixexprs.tar.zst";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs"; # TODO: remove when niri-flake fixed
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions"; # marketplace extensions nixpkgs lacks
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane"; # for term
    rust-overlay = {
      url = "github:oxalica/rust-overlay"; # for term
      inputs.nixpkgs.follows = "nixpkgs";
    };
    term = {
      url = "git+ssh://git@github.com/FyorDev/Term.git"; # term
      flake = false;
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
            inputs.catppuccin.nixosModules.catppuccin
            inputs.agenix.nixosModules.default
            inputs.spicetify-nix.nixosModules.default
            ./modules/system.nix
            ./modules/applications.nix
            ./modules/firefox.nix
            ./modules/mime.nix
            ./modules/secrets.nix
            ./modules/terminal.nix
            ./modules/claude.nix
            ./modules/theme.nix
            ./modules/login.nix
            ./modules/catppuccin.nix
            ./modules/niri.nix
            ./modules/waybar.nix
            ./modules/packages.nix
            ./hosts/${name}/configuration.nix
            { networking.hostName = name; }
            {
              options = {
                hostLabel = mkOption {
                  type = types.str;
                  description = "Host label shown by fastfetch";
                };
                mainOutput = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Monitor that is focused at login and holds the chat workspace";
                };
                displayScale = mkOption {
                  type = types.number;
                  default = 1;
                  description = "Display scale for the greeter";
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
                      default = "~/.ssh/id_ed25519.pub";
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
