#!/bin/bash
# Run as GUI user
set -x
while true; do
    # Sets the brightness of all monitors to 100%
    for display in $(xrandr --listmonitors | tail -n +2 | awk '{print $NF}'); do
        xrandr --output "$display" --brightness 1;
    done
    sleep 15;
done
