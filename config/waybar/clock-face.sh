#!/usr/bin/env bash
# Analog clock as an SVG for the image module, which only takes a file path.
# Arguments: hour hand color, minute hand color. Renamed into place so the bar never reads a partial file.
out=${XDG_RUNTIME_DIR:-/tmp}/waybar-clock.svg
read -r h m s < <(date +'%I %M %S')

awk -v h="$((10#$h))" -v m="$((10#$m))" -v s="$((10#$s))" -v hc="$1" -v mc="$2" '
function hand(deg, from, to, width, color,  rad, sn, cs) {
  rad = deg * atan2(0, -1) / 180
  sn = sin(rad)
  cs = cos(rad)
  return sprintf("<line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\" stroke=\"%s\" stroke-width=\"%s\"/>",
                 12 + from * sn, 12 - from * cs, 12 + to * sn, 12 - to * cs, color, width)
}
BEGIN {
  printf "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\">"
  printf "%s%s</svg>", hand((h % 12 + m / 60) * 30, 0, 6, 2.8, hc), hand((m + s / 60) * 6, 7.4, 10.4, 3, mc)
}' >"$out.new"
mv "$out.new" "$out"
echo "$out"
