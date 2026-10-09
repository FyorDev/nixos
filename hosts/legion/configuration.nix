{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-legion-16ach6h-hybrid
  ];

  hostLabel = "Lenovo Legion 5 Pro 16ACH6H 82JQ";

  hardware.nvidia = {
    prime.amdgpuBusId = "PCI:6:0:0"; # `lspci | grep VGA`
    powerManagement.finegrained = true; # power the dGPU down when idle
  };

  # profile switching with powerprofilesctl, replaces the module's default tlp
  services.power-profiles-daemon.enable = true;

  # Needed for legion_cli
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  boot.kernelModules = [ "legion-laptop" ];
  environment.systemPackages = [ pkgs.lenovo-legion ];
}
