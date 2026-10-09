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

  user = {
    name = "fyor";
    git = {
      name = "FyorDev";
      email = "uuf@fyor.nl";
    };
  };

  hardware.nvidia = {
    prime.amdgpuBusId = "PCI:6:0:0"; # `lspci | grep VGA`
    powerManagement.finegrained = true; # power the dGPU down when idle
  };

  services.upower.enable = true; # battery state
  services.power-profiles-daemon.enable = true; # profile switching with powerprofilesctl

  # Needed for legion_cli
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  boot.kernelModules = [ "legion-laptop" ];
  environment.systemPackages = [ pkgs.lenovo-legion ];
}
