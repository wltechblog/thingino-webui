#!/bin/sh

plugin="daynight"

. /usr/sbin/common-plugins
singleton

STOP_FILE=/tmp/daynight.stop
MODE_FILE=/tmp/nightmode.txt

switch_to_day() {
	/usr/sbin/color.sh on
	/usr/sbin/irled.sh off
	/usr/sbin/ircut.sh on
	echo "Switched to day mode"
	echo "day" >$MODE_FILE
}

switch_to_night() {
	/usr/sbin/color.sh off
	/usr/sbin/irled.sh on
	/usr/sbin/ircut.sh off
	echo "Switched to night mode"
	echo "night" >$MODE_FILE
}

# determine luminance of the scene
value=$(imp-control.sh gettotalgain)
reversed=1

case "$1" in
	night)
		switch_to_night
		;;
	day)
		switch_to_day
		;;
	~ | toggle)
		if [ "$(cat $MODE_FILE 2>/dev/null)" = "day" ]; then
			switch_to_night
		else
			switch_to_day
		fi
		;;
	*)
		day_night_max=$(fw_printenv -n day_night_max || echo 2400)
		day_night_min=$(fw_printenv -n day_night_min || echo 1200)

		echo "$day_night_min - $value - $day_night_max"

		if [ "$reversed" -eq 0 ]; then
			if [ "$value" -lt "$day_night_min" ]; then
				switch_to_day
			elif [ "$value" -gt "$day_night_max" ]; then
				switch_to_night
			fi
		else
			if [ "$value" -gt "$day_night_max" ]; then
				switch_to_night
			elif [ "$value" -lt "$day_night_min" ]; then
				switch_to_day
			fi
		fi
		;;
esac

exit 0