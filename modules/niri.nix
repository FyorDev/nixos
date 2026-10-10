{ config, ... }:
{
  home-manager.users.${config.user.name} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) range nameValuePair concatMap;
      inherit (config.lib.niri) actions;

      directions = [
        {
          dir = "left";
          keys = [
            "Left"
            "H"
          ];
          focus = "focus-column-left";
          move = "move-column-left";
        }
        {
          dir = "down";
          keys = [
            "Down"
            "J"
          ];
          focus = "focus-window-down";
          move = "move-window-down";
        }
        {
          dir = "up";
          keys = [
            "Up"
            "K"
          ];
          focus = "focus-window-up";
          move = "move-window-up";
        }
        {
          dir = "right";
          keys = [
            "Right"
            "L"
          ];
          focus = "focus-column-right";
          move = "move-column-right";
        }
      ];

      directional = concatMap (
        d:
        concatMap (key: [
          (nameValuePair "Mod+${key}" { action = actions.${d.focus}; })
          (nameValuePair "Mod+Ctrl+${key}" { action = actions.${d.move}; })
          (nameValuePair "Mod+Shift+${key}" { action = actions."focus-monitor-${d.dir}"; })
          (nameValuePair "Mod+Shift+Ctrl+${key}" { action = actions."move-column-to-monitor-${d.dir}"; })
        ]) d.keys
      ) directions;

      screenshot-ocr = pkgs.writeShellApplication {
        name = "screenshot-ocr";
        runtimeInputs = with pkgs; [
          grim
          slurp
          tesseract
          wl-clipboard
          libnotify
        ];
        text = ''
          area=$(slurp) || exit 0
          text=$(grim -g "$area" - | tesseract - - -l eng 2>/dev/null)
          if [ -z "''${text//[[:space:]]/}" ]; then
            notify-send "OCR" "No text found in that area"
            exit 0
          fi
          printf '%s' "$text" | wl-copy
          notify-send "OCR" "Copied $(printf '%s' "$text" | wc -w) words to the clipboard"
        '';
      };

      numbered = concatMap (i: [
        (nameValuePair "Mod+${toString i}" { action.focus-workspace = i; })
        (nameValuePair "Mod+Ctrl+${toString i}" { action.move-column-to-workspace = i; })
      ]) (range 1 9);
    in
    {
      home.packages = [ screenshot-ocr ];

      programs.niri.settings = {
        input = {
          keyboard = {
            xkb = { };
            numlock = true;
          };
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
          mouse = { };
          trackpoint = { };
        };

        layout = {
          gaps = 16;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          default-column-width.proportion = 0.5;
          # colours and which of the two is on come from the stylix target
          focus-ring.width = 4;
          border.width = 4;
          shadow = {
            softness = 30;
            spread = 5;
            offset = {
              x = 0;
              y = 5;
            };
            color = "#0007";
          };
          struts = { };
        };

        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        window-rules = [
          {
            matches = [ { app-id = ''^org\.wezfurlong\.wezterm$''; } ];
            default-column-width = { };
          }
          {
            matches = [
              {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              }
            ];
            open-floating = true;
          }
        ];

        binds =
          lib.listToAttrs (directional ++ numbered)
          // (with actions; {
            "Mod+Shift+Slash".action = show-hotkey-overlay;

            "Mod+T" = {
              hotkey-overlay.title = "Open a Terminal: alacritty";
              action = spawn "alacritty";
            };
            "Mod+D" = {
              hotkey-overlay.title = "Run an Application: fuzzel";
              action = spawn "fuzzel";
            };
            "Mod+Y" = {
              hotkey-overlay.title = "Clipboard History: cliphist";
              action = spawn-sh "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";
            };
            "Mod+Shift+S" = {
              hotkey-overlay.title = "Annotate a Screenshot: swappy";
              action = spawn-sh "grim -g \"$(slurp)\" - | swappy -f -";
            };
            "Mod+Shift+Print" = {
              hotkey-overlay.title = "Copy Text From Screen: tesseract";
              action = spawn "screenshot-ocr";
            };
            "Mod+P" = {
              hotkey-overlay.title = "Pick a Colour: hyprpicker";
              action = spawn "hyprpicker" "--autocopy";
            };
            "Super+Alt+L" = {
              hotkey-overlay.title = "Lock the Screen: swaylock";
              action = spawn "swaylock";
            };
            "Super+Alt+S" = {
              allow-when-locked = true;
              hotkey-overlay.hidden = true;
              action = spawn-sh "pkill orca || exec orca";
            };

            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--output-volume" "raise";
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--output-volume" "lower";
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--output-volume" "mute-toggle";
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--input-volume" "mute-toggle";
            };
            "XF86AudioPlay" = {
              allow-when-locked = true;
              action = spawn-sh "playerctl play-pause";
            };
            "XF86AudioPause" = {
              allow-when-locked = true;
              action = spawn-sh "playerctl play-pause";
            };
            "XF86AudioStop" = {
              allow-when-locked = true;
              action = spawn-sh "playerctl stop";
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action = spawn-sh "playerctl previous";
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action = spawn-sh "playerctl next";
            };
            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--brightness" "raise";
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              action = spawn "swayosd-client" "--brightness" "lower";
            };

            "Mod+O" = {
              repeat = false;
              action = toggle-overview;
            };
            "Mod+Q" = {
              repeat = false;
              action = close-window;
            };

            "Mod+Home".action = focus-column-first;
            "Mod+End".action = focus-column-last;
            "Mod+Ctrl+Home".action = move-column-to-first;
            "Mod+Ctrl+End".action = move-column-to-last;

            "Mod+Page_Down".action = focus-workspace-down;
            "Mod+Page_Up".action = focus-workspace-up;
            "Mod+U".action = focus-workspace-down;
            "Mod+I".action = focus-workspace-up;
            "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
            "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
            "Mod+Ctrl+U".action = move-column-to-workspace-down;
            "Mod+Ctrl+I".action = move-column-to-workspace-up;
            "Mod+Shift+Page_Down".action = move-workspace-down;
            "Mod+Shift+Page_Up".action = move-workspace-up;
            "Mod+Shift+U".action = move-workspace-down;
            "Mod+Shift+I".action = move-workspace-up;

            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action = focus-workspace-down;
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action = focus-workspace-up;
            };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action = move-column-to-workspace-down;
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action = move-column-to-workspace-up;
            };

            "Mod+WheelScrollRight".action = focus-column-right;
            "Mod+WheelScrollLeft".action = focus-column-left;
            "Mod+Ctrl+WheelScrollRight".action = move-column-right;
            "Mod+Ctrl+WheelScrollLeft".action = move-column-left;
            "Mod+Shift+WheelScrollDown".action = focus-column-right;
            "Mod+Shift+WheelScrollUp".action = focus-column-left;
            "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
            "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

            "Mod+BracketLeft".action = consume-or-expel-window-left;
            "Mod+BracketRight".action = consume-or-expel-window-right;
            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            "Mod+R".action = switch-preset-column-width;
            "Mod+Shift+R".action = switch-preset-column-width-back;
            "Mod+Ctrl+Shift+R".action = switch-preset-window-height;
            "Mod+Ctrl+R".action = reset-window-height;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+M".action = maximize-window-to-edges;
            "Mod+Ctrl+F".action = expand-column-to-available-width;
            "Mod+C".action = center-column;
            "Mod+Ctrl+C".action = center-visible-columns;

            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

            "Mod+V".action = toggle-window-floating;
            "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
            "Mod+W".action = toggle-column-tabbed-display;

            "Print".action.screenshot = [ ];
            "Ctrl+Print".action.screenshot-screen = [ ];
            "Alt+Print".action.screenshot-window = [ ];

            "Mod+Escape" = {
              allow-inhibiting = false;
              action = toggle-keyboard-shortcuts-inhibit;
            };
            "Mod+Shift+E".action.quit = [ ];
            "Ctrl+Alt+Delete".action.quit = [ ];
            "Mod+Shift+P".action = power-off-monitors;
          });
      };
    };
}
