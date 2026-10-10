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

  # games on the nvidia gpu without per-game nvidia-offload
  # keeps the dgpu awake while steam is open
  programs.steam.package = pkgs.steam.override {
    extraEnv = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };
  };

  services.upower.enable = true; # battery state
  services.power-profiles-daemon.enable = true; # profile switching with powerprofilesctl

  # Needed for legion_cli
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  boot.kernelModules = [ "legion-laptop" ];
  environment.systemPackages = [ pkgs.lenovo-legion ];
}
