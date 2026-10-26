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
  displayScale = 1.5;
  # the AMD iGPU, NVENC would wake the dGPU
  recordingDevice = "/dev/dri/by-path/pci-0000:06:00.0-render";

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

  # TODO: remove when fixed
  boot = {
    # TODO: remove when fixed
    # nixpkgs wants a kmodigest certificate next to every module (NixOS/nixpkgs#571181), but
    # these two copy their .ko by hand and ship none. Drop once they install via modules_install.
    kernelPackages = pkgs.linuxPackages.extend (
      _final: prev:
      let
        sign =
          pkg:
          pkg.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.buildPackages.kmodigest ];
            # after fixup, stripping would drop the appended signature
            postFixup = (old.postFixup or "") + ''
              for ko in $(find "$out/lib/modules" -name '*.ko'); do
                [ -e "$ko.cer" ] || kmodigest "$ko"
              done
            '';
          });
      in
      {
        lenovo-legion-module = sign prev.lenovo-legion-module;
        zenpower = sign prev.zenpower; # from nixos-hardware's common/cpu/amd/zenpower.nix
      }
    );

    # Needed for legion_cli
    extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
    kernelModules = [ "legion-laptop" ];
  };
  environment.systemPackages = [ pkgs.lenovo-legion ];
}
