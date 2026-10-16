#!/usr/bin/env bash
# Mako do-not-disturb state, as an icon key for format-icons
if [ "${1:-}" = toggle ]; then
	makoctl mode -t do-not-disturb >/dev/null
	pkill -RTMIN+9 -x '\.?waybar(-wrapped)?' || true
	exit 0
fi

modes=$(makoctl mode 2>/dev/null || true)
if grep -qx do-not-disturb <<<"$modes"; then
	echo '{"alt":"dnd","class":"dnd","tooltip":"Do not disturb is on, click to turn off"}'
else
	echo '{"alt":"on","class":"on","tooltip":"Click for do not disturb"}'
fi
