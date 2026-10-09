{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  hostLabel = "Asus TUF Gaming X570-PLUS (WI-FI)";

  user = {
    name = "fyor";
    git = {
      name = "FyorDev";
      email = "uuf@fyor.nl";
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
}
