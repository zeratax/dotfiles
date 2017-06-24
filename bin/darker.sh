#!/bin/bash
CURR=$(</sys/class/backlight/intel_backlight/brightness)
MIN=10
MAX=$(</sys/class/backlight/intel_backlight/max_brightness)
NEW=$((CURR-20))
if [[ $NEW -lt $MIN ]]
  then
    NEW=$MIN
fi
echo $NEW > /sys/class/backlight/intel_backlight/brightness 
notify-send "Backlight $((NEW*100/MAX)) %" 
