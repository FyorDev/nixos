{ inputs, pkgs, ... }:
let
  # systemd 261 deprecates niri-session calling import-environment without names
  niriSession = pkgs.writeShellScript "niri-session" ''
    exec ${pkgs.niri}/bin/niri-session "$@" 2> >(${pkgs.gnugrep}/bin/grep -v 'import-environment without a list' >&2)
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
    hardware.openrgb.enable = true;
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
          "--cmd ${niriSession}"
        ];
        user = "greeter";
      };
    };
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs = {
    niri = {
      enable = true;
      package = pkgs.niri-unstable;
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
