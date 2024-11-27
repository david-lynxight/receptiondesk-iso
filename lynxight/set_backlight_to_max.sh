#!/bin/bash
# Run as root
set -x
# Set backlight to max
for dir in /sys/class/backlight/*/; do
    cp -f "$dir/max_brightness" "$dir/brightness"
done
