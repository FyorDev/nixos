# Top bar, colors from catppuccin/nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  script =
    name: runtimeInputs: text:
    lib.getExe (pkgs.writeShellApplication { inherit name runtimeInputs text; });
  scriptFile =
    name: runtimeInputs:
    script "waybar-${name}" runtimeInputs (builtins.readFile ../config/waybar/${name}.sh);

  media =
    script "waybar-media"
      (with pkgs; [
        playerctl
        pipewire
        wireplumber
        aubio
        cava
        coreutils
      ])
      ''
        exec ${lib.getExe pkgs.python3} ${../config/waybar/media.py} "$@"
      '';
  ip = scriptFile "ip" (
    with pkgs;
    [
      iproute2
      gnused
      findutils
      coreutils
      curl
      procps
    ]
  );
  dnd = scriptFile "dnd" (
    with pkgs;
    [
      mako
      gnugrep
      procps
    ]
  );
  service = scriptFile "service" (
    with pkgs;
    [
      systemd
      procps
    ]
  );
  clockFace = scriptFile "clock-face" (
    with pkgs;
    [
      gawk
      coreutils
    ]
  );

  playerctl = lib.getExe pkgs.playerctl;
  glyph = code: builtins.fromJSON ''"\u${code}"'';

  # button that starts and stops a systemd user service
  serviceToggle =
    {
      unit,
      signal,
      on,
      off,
    }:
    let
      exec = "${service} ${
        lib.escapeShellArgs [
          unit
          (toString signal)
          on.tip
          off.tip
        ]
      }";
    in
    {
      inherit exec signal;
      return-type = "json";
      interval = "once";
      format = "{icon}";
      format-icons = {
        on = glyph on.icon;
        off = glyph off.icon;
      };
      on-click = "${exec} toggle";
    };
in
{
  home-manager.users.${config.user.name} =
    { config, lib, ... }:
    let
      palette = lib.importJSON "${config.catppuccin.sources.palette}/palette.json";
      c = lib.mapAttrs (_: color: color.hex) palette.${config.catppuccin.flavor}.colors;
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings.main = {
          layer = "top";
          position = "top";
          height = 34;
          reload_style_on_change = true;

          modules-left = [
            "custom/media-prev"
            "custom/media-play"
            "custom/media-next"
            "custom/media"
            "custom/media-bars"
          ];
          modules-center = [
            "clock"
            "image#clock"
            "custom/ip"
          ];
          modules-right = [
            "battery"
            "tray"
            "custom/lan-mouse"
            "custom/autolock"
            "custom/notifications"
            "custom/power"
          ];

          "custom/media-prev" = {
            format = glyph "f048";
            tooltip = false;
            on-click = "${playerctl} previous";
          };
          "custom/media-play" = {
            exec = "${playerctl} --follow metadata --format '{\"alt\":\"{{status}}\"}'";
            return-type = "json";
            format = "{icon}";
            format-icons = {
              Playing = glyph "f04c";
              default = glyph "f04b";
            };
            tooltip = false;
            on-click = "${playerctl} play-pause";
          };
          "custom/media-next" = {
            format = glyph "f051";
            tooltip = false;
            on-click = "${playerctl} next";
          };
          "custom/media" = {
            exec = "${media} text";
            return-type = "json";
            max-length = 300;
            on-click = "${media} toggle";
            on-scroll-up = "${playerctl} next";
            on-scroll-down = "${playerctl} previous";
          };
          "custom/media-bars" = {
            exec = "${media} bars";
            return-type = "json";
            on-click = "${media} toggle";
            on-scroll-up = "${playerctl} next";
            on-scroll-down = "${playerctl} previous";
          };

          "image#clock" = {
            exec = "${clockFace} '${c.mauve}' '${c.subtext0}'";
            size = 24;
            interval = 5;
            tooltip = false;
          };
          clock = {
            interval = 1;
            format = "{:%Y %m<span color='${c.subtext0}'>_%b</span> %d<span color='${c.subtext0}'>_%a</span> %H:%M:%S}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "month";
              weeks-pos = "right";
              format = {
                months = "<span color='${c.mauve}'><b>{}</b></span>";
                weeks = "<span color='${c.blue}'>{}</span>";
                today = "<span color='${c.red}'><b>{}</b></span>";
              };
            };
            actions = {
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };

          "custom/ip" = {
            exec = ip;
            return-type = "json";
            interval = 10;
            signal = 8;
            on-click = "${ip} toggle";
          };
          battery = {
            states = {
              warning = 25;
              critical = 10;
            };
            format = "{icon} {capacity}%";
            format-charging = "${glyph "f0e7"} {capacity}%";
            format-plugged = "${glyph "f1e6"} {capacity}%";
            format-icons = map glyph [
              "f244"
              "f243"
              "f242"
              "f241"
              "f240"
            ];
            tooltip-format = "{timeTo}";
          };
          tray.spacing = 10;
          "custom/lan-mouse" = serviceToggle {
            unit = "lan-mouse";
            signal = 11;
            on = {
              icon = "f245";
              tip = "Sharing mouse and keyboard, click to turn off";
            };
            off = {
              icon = "f245";
              tip = "Lan Mouse is off, click to turn on";
            };
          };
          "custom/autolock" = serviceToggle {
            unit = "swayidle";
            signal = 10;
            on = {
              icon = "f023";
              tip = "Locks after 15 minutes idle, click to turn off";
            };
            off = {
              icon = "f09c";
              tip = "Auto lock is off, click to turn on";
            };
          };
          "custom/notifications" = {
            exec = dnd;
            return-type = "json";
            interval = "once";
            signal = 9;
            format = "{icon}";
            format-icons = {
              on = glyph "f0f3";
              dnd = glyph "f1f6";
            };
            on-click = "${dnd} toggle";
          };
          "custom/power" = {
            format = glyph "f011";
            tooltip = false;
            menu = "on-click";
            menu-file = "${../config/waybar/power-menu.xml}";
            menu-actions = {
              lock = "lock-screen";
              suspend = "systemctl suspend";
              logout = "niri msg action quit --skip-confirmation";
              reboot = "systemctl reboot";
              shutdown = "systemctl poweroff";
            };
          };
        };

        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font";
            font-size: 13px;
            border: none;
            border-radius: 0;
            min-height: 0;
          }

          window#waybar {
            background: @mantle;
            color: @text;
            border-bottom: 1px solid @surface0;
          }

          .modules-left { padding-left: 6px; }
          .modules-right { padding-right: 6px; }
          .module { padding: 0 10px; }

          #custom-media-prev,
          #custom-media-play,
          #custom-media-next {
            padding: 0 6px;
            color: @subtext0;
          }
          #custom-media-prev:hover,
          #custom-media-play:hover,
          #custom-media-next:hover { color: @accent; }
          #custom-media { padding: 0 4px; }
          #custom-media-bars { padding: 0 10px 0 4px; }

          #image.clock { padding: 0 0 0 8px; }
          #clock {
            padding: 0 0 0 10px;
            color: @accent;
            font-weight: bold;
          }

          #custom-ip {
            padding-left: 0;
            color: @subtext0;
          }
          #custom-ip:hover { background: @surface0; }

          #battery { color: @teal; }
          #battery.charging { color: @green; }
          #battery.warning { color: @yellow; }
          #battery.critical { color: @red; }

          #tray > .passive { -gtk-icon-effect: dim; }
          #tray > .needs-attention { -gtk-icon-effect: highlight; }

          #custom-lan-mouse,
          #custom-autolock,
          #custom-notifications { color: @accent; }
          #custom-lan-mouse.off,
          #custom-autolock.off,
          #custom-notifications.dnd { color: @overlay0; }
          #custom-lan-mouse:hover,
          #custom-autolock:hover,
          #custom-notifications:hover { background: @surface0; }

          #custom-power { color: @red; }
          #custom-power:hover {
            background: @red;
            color: @crust;
          }

          tooltip {
            background: @base;
            border: 1px solid @accent;
          }
          tooltip label { color: @text; }
        '';
      };
    };
}
