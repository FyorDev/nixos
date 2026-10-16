#!/usr/bin/env bash
# Local address; a click toggles the public one, fetched on demand and cached for 5 minutes
dir=${XDG_RUNTIME_DIR:-/tmp}
flag=$dir/waybar-ip-public
cache=$dir/waybar-public-ip

if [ "${1:-}" = toggle ]; then
	if [ -e "$flag" ]; then rm "$flag"; else touch "$flag"; fi
	pkill -RTMIN+8 -x '\.?waybar(-wrapped)?' || true
	exit 0
fi

local_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' || true)
if [ -z "$local_ip" ]; then
	echo '{"text":"offline","tooltip":"No route"}'
	exit 0
fi

if [ ! -e "$flag" ]; then
	printf '{"text":"%s","tooltip":"Click for the public address"}\n' "$local_ip"
	exit 0
fi

if [ -z "$(find "$cache" -mmin -5 -size +0 2>/dev/null)" ]; then
	if curl -fsS --max-time 3 https://api.ipify.org >"$cache.new" 2>/dev/null; then
		mv "$cache.new" "$cache"
	fi
fi
printf '{"text":"%s","tooltip":"Public address, click to go back"}\n' "$(cat "$cache" 2>/dev/null || echo '?')"
