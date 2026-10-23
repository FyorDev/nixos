{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  hostLabel = "Asus TUF Gaming X570-PLUS (WI-FI)";
  mainOutput = "HDMI-A-1";
  displayScale = 1.5;

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
