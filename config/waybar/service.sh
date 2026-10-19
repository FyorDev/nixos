#!/usr/bin/env bash
# Waybar toggle for a systemd user service: service.sh unit signal on-tip off-tip [toggle]
unit=$1 signal=$2 on_tip=$3 off_tip=$4

if [ "${5:-}" = toggle ]; then
	if systemctl --user is-active --quiet "$unit"; then
		systemctl --user stop "$unit"
	else
		systemctl --user start "$unit"
	fi
	pkill -RTMIN+"$signal" -x '\.?waybar(-wrapped)?' || true
	exit 0
fi

if systemctl --user is-active --quiet "$unit"; then
	printf '{"alt":"on","class":"on","tooltip":"%s"}\n' "$on_tip"
else
	printf '{"alt":"off","class":"off","tooltip":"%s"}\n' "$off_tip"
fi
