{ inputs, pkgs, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  networking.networkmanager.enable = true;

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    optimise.automatic = true;
  };
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_GB.UTF-8";

  console.useXkbConfig = true;

  services = {
    xserver.xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
    libinput.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    udev.packages = [ pkgs.platformio-core.udev ];
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = builtins.concatStringsSep " " [
          "${pkgs.cage}/bin/cage -s --"
          "${pkgs.alacritty}/bin/alacritty"
          "-e ${pkgs.tuigreet}/bin/tuigreet"
          "--time"
          "--user fyor"
          "--remember"
          "--asterisks"
          "--greeting 'Welcome back'"
          "--cmd niri-session"
        ];
        user = "greeter";
      };
    };
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs = {
    niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };
    virt-manager.enable = true;
  };

  virtualisation.libvirtd.enable = true;

  users.users.fyor = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "dialout"
      "video"
      "audio"
      "render"
      "kvm"
      "libvirtd"
    ];
  };

  system.stateVersion = "26.05";
}
