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

  networking.networkmanager = {
    enable = true;
    settings.connection."ethernet.wake-on-lan" = "64";
  };
  networking.firewall.allowedUDPPorts = [ 4242 ]; # lan-mouse

  systemd.network.links."50-wol" = {
    matchConfig.Type = "ether";
    linkConfig.WakeOnLan = "magic";
  };

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
      inputs.rust-overlay.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      (final: _prev: {
        term = final.callPackage ../pkgs/term.nix {
          src = inputs.term;
          craneLib = (inputs.crane.mkLib final).overrideToolchain (
            final.rust-bin.fromRustupToolchainFile "${inputs.term}/rust-toolchain.toml"
          );
        };
      })
      # goxel's Makefile hardcodes -Werror and the newer gcc trips on its code
      (_final: prev: {
        goxel = prev.goxel.overrideAttrs (old: {
          NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error";
        });
      })
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
      authorizedKeysFiles = [ ".ssh/id_ed25519.pub" ]; # your own key can log in
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
    gnome.sushi.enable = true; # nautilus space preview
    udisks2.enable = true; # mounting
    syncthing = {
      enable = true;
      user = config.user.name;
      dataDir = config.users.users.${config.user.name}.home;
      configDir = "${config.users.users.${config.user.name}.home}/.local/state/syncthing";
      openDefaultPorts = true;
    };
    blueman.enable = true; # bluetooth applet
    gnome.gnome-keyring.enable = true; # secret storage for libsecret apps
    hardware.openrgb.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true; # wine
      };
      pulse.enable = true;
      jack.enable = true; # DAWs
      # The bridge exposes PipeWire-System and PipeWire-RT-Event as ALSA seq
      # ports that Wine lists as MIDI inputs but can't open, which makes FL
      # Studio report "failed to open device" on startup. Hardware MIDI is
      # kernel seq and is unaffected.
      wireplumber.extraConfig."51-no-alsa-midi-bridge"."wireplumber.profiles".main."monitor.alsa-midi" =
        "disabled";
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
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      protontricks.enable = true;
      extest.enable = true; # steam input on wayland
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
    gamemode.enable = true; # gamemoderun %command%
    gamescope.enable = true;
    ssh.knownHosts = {
      github = {
        hostNames = [ "github.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
      forgejo = {
        hostNames = [ "[git.blahajresidence.nl]:2222" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbzDrnHR2L3eqZzdVNE2cv2oWilnY3/7G+HGHUVOVqZ";
      };
    };
    dconf.enable = true; # settings backend for GTK apps
    virt-manager.enable = true;
    xppen.enable = true; # xp-pen tablet driver
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    nix-ld.enable = true; # allows prebuilt binaries (steam etc)
    appimage = {
      enable = true;
      binfmt = true;
    };
  };

  # niri leaks VRAM on nvidia unless the driver stops holding freed buffers
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [
            {
              key = "GLVidHeapReuseRatio";
              value = 0;
            }
          ];
        }
      ];
    };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # electron and chromium apps use wayland
    _JAVA_AWT_WM_NONREPARENTING = "1"; # so java swing apps don't draw blank
    WINEDLLOVERRIDES = "winemenubuilder.exe=d"; # no wine .desktop files in the app menu
  };

  security = {
    polkit.enable = true; # privilege prompt for mounting drives etc
    rtkit.enable = true; # no audio stuttering
    # WineASIO locks its memory, the default 8 MiB memlock limit makes FL
    # Studio's own allocations fail once the driver loads
    pam.loginLimits = [
      {
        domain = "@audio";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@audio";
        type = "-";
        item = "rtprio";
        value = "95";
      }
      {
        domain = "@audio";
        type = "-";
        item = "nice";
        value = "-19";
      }
    ];
    pam.services.greetd.enableGnomeKeyring = true; # unlock keyring at login
  };

  hardware.bluetooth.enable = true;
  hardware.keyboard.qmk.enable = true; # udev rules for flashing qmk keyboards

  # copied if it doesn't exist
  systemd.tmpfiles.rules = [
    "C /var/lib/pentablet/conf/xppen/config.xml - - - - ${../config/xppen/config.xml}"
    "z /var/lib/pentablet/conf/xppen/config.xml 0666 - - -"
  ];

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
      "wireshark" # packet capture without root
    ];
  };

  system.stateVersion = "26.05";
}
