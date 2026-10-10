# Base system and services
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # systemd 261 deprecates niri-session calling import-environment without names
  niriSession = pkgs.writeShellScript "niri-session" ''
    exec ${config.programs.niri.package}/bin/niri-session "$@" 2> >(${pkgs.gnugrep}/bin/grep -v 'import-environment without a list' >&2)
  '';
in
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
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      inputs.niri.overlays.niri
      # TODO: remove once flake updated https://github.com/sodiboo/niri-flake/issues/1851
      # niri-unstable asserts libdisplay-info 0.2.0, which nixpkgs has dropped
      (final: prev: {
        libdisplay-info_0_2 = prev.libdisplay-info.overrideAttrs {
          version = "0.2.0";
          src = final.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "emersion";
            repo = "libdisplay-info";
            tag = "0.2.0";
            hash = "sha256-6xmWBrPHghjok43eIDGeshpUEQTuwWLXNHg7CnBUt3Q=";
          };
        };
      })
    ];
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_GB.UTF-8";

  console = {
    useXkbConfig = true;
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = lib.mkDefault "ter-v32n"; # Better for 4k
  };

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
    udev.packages = [
      pkgs.platformio-core.udev # non-root usb with dialout
      pkgs.brightnessctl # brightness settings with video
    ];
    fwupd.enable = true; # firmware updates
    gvfs.enable = true; # nautilus virtual fs for trash, mtp and network
    udisks2.enable = true; # mounting
    hardware.openrgb.enable = true;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = builtins.concatStringsSep " " [
          "${pkgs.tuigreet}/bin/tuigreet"
          "--time"
          "--user ${config.user.name}"
          "--remember"
          "--asterisks"
          "--greeting 'Welcome back'"
          "--cmd ${niriSession}"
        ];
        user = "greeter";
      };
    };
  };

  programs = {
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
    dconf.enable = true; # settings backend for GTK apps
    virt-manager.enable = true;
    nix-ld.enable = true; # allows prebuilt binaries (steam etc)
    appimage = {
      enable = true;
      binfmt = true;
    };
  };

  security.rtkit.enable = true; # no audio stuttering

  hardware.bluetooth.enable = true;

  virtualisation.libvirtd.enable = true;

  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # sudo access
      "networkmanager" # manage network connections without root
      "dialout" # serial ports for microcontrollers
      "video" # backlight and devices
      "audio" # direct audio
      "render" # GPU compute
      "kvm" # hardware virtualisation
      "libvirtd" # libvirt virtual machine management
    ];
  };

  system.stateVersion = "26.05";
}
