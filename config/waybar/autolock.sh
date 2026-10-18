#!/usr/bin/env bash
# Idle auto-lock is the swayidle user service; stopping it disables locking
if [ "${1:-}" = toggle ]; then
	if systemctl --user is-active --quiet swayidle; then
		systemctl --user stop swayidle
	else
		systemctl --user start swayidle
	fi
	pkill -RTMIN+10 -x '\.?waybar(-wrapped)?' || true
	exit 0
fi

if systemctl --user is-active --quiet swayidle; then
	echo '{"alt":"on","class":"on","tooltip":"Locks after 15 minutes idle, click to turn off"}'
else
	echo '{"alt":"off","class":"off","tooltip":"Auto lock is off, click to turn on"}'
fi
