#!/bin/bash
sleep 20

TARGET_VOLUME="80%"

while true; do
    # Get the current volume level
    CURRENT_VOLUME=$(amixer sget 'Master' | grep -oP '\[\d+%\]' | head -1 | tr -d '[]')

    # Check if the sound is muted
    IS_MUTED=$(amixer sget 'Master' | grep -oP '\[off\]')
    echo $IS_MUTED
    # If muted or volume is not at target, reset the volume
    if [[ "$IS_MUTED" == *"off"* ]] || [ "$CURRENT_VOLUME" != "$TARGET_VOLUME" ]; then
        amixer sset 'Master' unmute
        amixer sset 'Master' $TARGET_VOLUME
    fi

    # Sleep for 15 seconds before checking again
    sleep 15
done