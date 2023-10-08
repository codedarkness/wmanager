#!/bin/bash
# baraction.sh script for spectrwm status bar

## CPU
cpu() {
	read cpu a b c previdle rest < /proc/stat
	prevtotal=$((a+b+c+previdle))
	sleep 0.5
	read cpu a b c idle rest < /proc/stat
	total=$((a+b+c+idle))
	cpu=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))
	echo -e "CPU $cpu%"
}

## TEMP
temp() {
	eval $(sensors | awk '/^Core 0/ {gsub(/°/,""); printf "CPU0=%s;", $3}')
	eval $(sensors | awk '/^Core 1/ {gsub(/°/,""); printf "CPU1=%s;", $3}')
	echo -e "TEM ${CPU0}"
}

## RAM
mem() {
	mem=`free | awk '/Mem/ {printf "%dM", $3 / 1024.0, $2 /1024.0 }'`
	echo -e "MEM $mem"
}

## DISK
hdd() {
	hdd="$(df -h | awk 'NR==5{print $4}')"
	echo -e "SSD $hdd"
}

## BATTERY
bat() {
	battery="$(cat /sys/class/power_supply/BAT0/capacity)"
	echo "BAT $battery%"
}

## VOLUME
vol() {
	vol="$(amixer get Master | awk '$0~/%/{print $4}' | tr -d '[]')"
	echo -e "VOL $vol"
}

SLEEP_SEC=3
#loops forever outputting a line every SLEEP_SEC secs

# It seems that we are limited to how many characters can be displayed via
# the baraction script output. And the the markup tags count in that limit.
# So I would love to add more functions to this script but it makes the
# echo output too long to display correctly.
while :; do
    echo "+@fg=1; $(cpu) +@fg=0; : +@fg=2; $(temp) +@fg=0; : +@fg=3; $(mem) +@fg=0; : +@fg=5; $(hdd) +@fg=0; : +@fg=1; $(bat) +@fg=0; : +@fg=4; $(vol) +@fg=0;"
	sleep $SLEEP_SEC
done
