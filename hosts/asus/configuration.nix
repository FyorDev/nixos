{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  hostLabel = "Asus TUF Gaming X570-PLUS (WI-FI)";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
}
