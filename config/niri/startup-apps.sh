#!/usr/bin/env bash
# Opens the chat apps in a fixed order and leaves the view on workspace 2.
# Optional argument: monitor to focus first, so these and later apps open there.
# An unfocused window opens right of the first column, so all but the first
# app are launched in reverse, each once the previous window is up.
order=(spotify vesktop com.rtosta.zapzap signal org.keepassxc.KeePassXC)
launch=(spotify:spotify keepassxc:org.keepassxc.KeePassXC signal-desktop:signal zapzap:com.rtosta.zapzap vesktop:vesktop)

msg() { niri msg "$@"; }
windows() { msg --json windows | jq -r '.[] | select(.layout.pos_in_scrolling_layout) | "\(.app_id) \(.id) \(.layout.pos_in_scrolling_layout[0])"'; }

if [ $# -gt 0 ]; then msg action focus-monitor "$1"; fi
msg action focus-workspace 2

for entry in "${launch[@]}"; do
	msg action spawn -- "${entry%%:*}"
	for _ in $(seq 100); do
		up=$(windows)
		if grep -q "^${entry#*:} " <<<"$up"; then break; fi
		sleep 0.2
	done
done

# Safety net for the case the order still came out wrong
slot=0
moved=
for app in "${order[@]}"; do
	read -r _ id col < <(windows | grep "^$app " || true)
	[ -n "${id:-}" ] || continue
	slot=$((slot + 1))
	[ "$col" = "$slot" ] && continue
	msg action focus-window --id "$id"
	msg action move-column-to-index "$slot"
	moved=1
done
if [ -n "$moved" ]; then msg action focus-workspace 2; fi
