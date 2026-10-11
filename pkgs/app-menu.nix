# Mod+S gives a fuzzel prompt for categories and then apps
# Step in and out with right and left arrow
{
  lib,
  runCommand,
  writeShellApplication,
  gawk,
  fuzzel,
  alacritty,
  coreutils,
  desktopEntries,
  categoryOrder,
}:

let
  # category, name, icon, terminal, command: one app per line, tab separated
  entries = runCommand "app-menu-entries" { nativeBuildInputs = [ gawk ]; } ''
    touch unsorted
    for f in ${desktopEntries}/share/applications/*.desktop; do
      [ -e "$f" ] || continue
      awk -F= '
        /^\[/ { main = ($0 == "[Desktop Entry]"); next }
        !main { next }
        $1 == "Name" && !name { name = substr($0, 6) }
        $1 == "Icon" && !icon { icon = substr($0, 6) }
        $1 == "Exec" && !exec { exec = substr($0, 6) }
        $1 == "Keywords" && !keywords { keywords = substr($0, 10) }
        $1 == "Terminal" && $2 == "true" { term = "true" }
        ($1 == "NoDisplay" || $1 == "Hidden") && $2 == "true" { hidden = 1 }
        $1 == "Type" && $2 != "Application" { hidden = 1 }
        END {
          if (name && exec && !hidden) {
            split(keywords, k, ";")
            category = k[1] == "" ? "Other" : k[1]
            gsub(/ *%[fFuUdDnNickvm]/, "", exec)
            printf "%s\t%s\t%s\t%s\t%s\n", category, name, icon, term, exec
          }
        }
      ' "$f" >> unsorted
    done
    sort -f -u -t "$(printf '\t')" -k1,1 -k2,2 unsorted > $out
  '';

  # fuzzel refuses to map a key twice, so cursor-left and cursor-right go first
  keyBindings = builtins.toFile "app-menu-key-bindings.ini" ''

    [key-bindings]
    cursor-left=none
    cursor-right=none
    custom-1=Right
    custom-2=Left
  '';

  # Nerd Font code point and name, in the order packages.nix lists them
  categoryList = builtins.toFile "app-menu-categories" (
    lib.concatMapStrings (c: "${c.icon}\t${c.name}\n") categoryOrder
  );
in
writeShellApplication {
  name = "app-menu";
  runtimeInputs = [
    fuzzel
    gawk
    alacritty
    coreutils
  ];
  text = ''
    entries=${entries}
    categoryList=${categoryList}

    # --config replaces the config file, so the bindings go on a copy of it
    menuConfig=$(mktemp)
    trap 'rm -f "$menuConfig"' EXIT
    cat "''${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel/fuzzel.ini" > "$menuConfig" 2>/dev/null || true
    cat ${keyBindings} >> "$menuConfig"

    ENTERED=10
    WENT_BACK=11

    show_categories() {
        used=$(cut -f1 "$entries")
        while IFS=$'\t' read -r cp name; do
            grep -qxF "$name" <<< "$used" || continue
            printf -v esc '\\U%08x' "0x$cp"
            printf '%b  %s\n' "$esc" "$name"
        done < "$categoryList" | fuzzel --config "$menuConfig" --width 24 --dmenu --prompt "  "
    }

    # --index ties the answer to a line, so odd characters in a name are safe
    show_apps() {
        awk -F'\t' -v c="$1" '
          $1 == c { printf "%s%cicon\37%s\n", $2, 0, $3 }
        ' "$entries" | fuzzel --config "$menuConfig" --width 40 --dmenu --index --prompt "$1  "
    }

    while :; do
        # Right on a category steps in, same as choosing it
        category=$(show_categories) && status=0 || status=$?
        case $status in
            0 | "$ENTERED") ;;
            *) exit 0 ;;
        esac
        category=''${category#*  }

        # status on the same line: set -e would otherwise exit on Left (11)
        idx=$(show_apps "$category") && status=0 || status=$?
        case $status in
            0 | "$ENTERED") ;;
            "$WENT_BACK") continue ;;
            *) exit 0 ;;
        esac

        selected=$(awk -F'\t' -v c="$category" -v i="$idx" '
          $1 == c && n++ == i { print $4 "\t" $5; exit }
        ' "$entries")
        [ -n "$selected" ] || exit 0
        break
    done

    terminal=''${selected%%$'\t'*}
    command=''${selected#*$'\t'}
    case "$terminal" in
        true) exec alacritty -e sh -c "$command" ;;
        *) exec sh -c "$command" ;;
    esac
  '';
}
