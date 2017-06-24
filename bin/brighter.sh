#!/bin/bash
CURR=$(</sys/class/backlight/intel_backlight/brightness)
MAX=$(</sys/class/backlight/intel_backlight/max_brightness)
NEW=$((CURR+20))
if [[ $NEW -gt $MAX ]]
  then
    NEW=$MAX
fi
echo $NEW > /sys/class/backlight/intel_backlight/brightness 
notify-send "Backlight $((NEW*100/MAX)) %"
