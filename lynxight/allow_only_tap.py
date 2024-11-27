#!/usr/bin/env python3

import evdev
import uinput
import time
from evdev import InputDevice, ecodes
from select import select


# Desired device name (e.g., 'Your Touchscreen Device Name')
# List of device names to search for
device_names = ['Melfas LGDisplay Incell Touch', 'Siliconworks SiW HID Touch Controller']

# Find the device path dynamically
device_path = None
for path in evdev.list_devices():
    device = evdev.InputDevice(path)
    if device.name in device_names:
        device_path = path
        print(f"Found device: {device.name} at {path}")
        break  # Stop as soon as one device is found
    
if device_path is None:
    raise Exception(f"Devices not found. Check the device name.")


# Open the input device
device = InputDevice(device_path)

# Grab the input device to prevent event propagation
device.grab()

# Create a virtual input device with adjusted coordinate ranges
virtual_device = uinput.Device([
    uinput.ABS_X + (0, 4096, 0, 0),  # Modify these ranges to match your touchscreen's range
    uinput.ABS_Y + (0, 4096, 0, 0),  # Modify these ranges to match your touchscreen's range
    uinput.BTN_TOUCH,
])

# Variables to track touch slots and states
active_slots = {}
current_slot = None
ignore_event = False
last_x, last_y = None, None
tap_start_time = None

print(f"Listening to touch events on {device_path}...")

try:
    while True:
        # Wait for input events
        r, w, x = select([device], [], [])
        for event in device.read():
            # Track the current slot (finger)
            if event.type == ecodes.EV_ABS and event.code == ecodes.ABS_MT_SLOT:
                current_slot = event.value

            # Detect if a finger is added or removed
            if event.type == ecodes.EV_ABS and event.code == ecodes.ABS_MT_TRACKING_ID:
                if event.value == -1:
                    # Finger removed
                    if current_slot in active_slots:
                        del active_slots[current_slot]
                else:
                    # Finger added
                    active_slots[current_slot] = event.value

                # If more than one finger is detected, set ignore_event to True
                if len(active_slots) > 1:
                    ignore_event = True
                    print(f"Multi-touch detected ({len(active_slots)} fingers). Ignoring event...")
                else:
                    ignore_event = False

            # Track swipe-like movements
            if event.type == ecodes.EV_ABS and event.code in [ecodes.ABS_X, ecodes.ABS_Y, ecodes.ABS_MT_POSITION_X, ecodes.ABS_MT_POSITION_Y]:
                if ignore_event or len(active_slots) > 1:
                    print("Swipe or multi-touch detected. Ignoring movement...")
                    continue  # Ignore swipes and multi-touch movements
                else:
                    # Store the last known coordinates for tap use
                    if event.code in [ecodes.ABS_X, ecodes.ABS_MT_POSITION_X]:
                        last_x = event.value
                        virtual_device.emit(uinput.ABS_X, event.value, syn=False)
                    elif event.code in [ecodes.ABS_Y, ecodes.ABS_MT_POSITION_Y]:
                        last_y = event.value
                        virtual_device.emit(uinput.ABS_Y, event.value, syn=False)

            # Handle touch press and release events
            if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_TOUCH:
                if event.value == 1:  # Finger touched the screen
                    if len(active_slots) == 1 and not ignore_event:
                        tap_start_time = time.time()  # Start timing the tap
                        print("Single tap detected.")
                        # Emit coordinates before the tap event
                        if last_x is not None and last_y is not None:
                            virtual_device.emit(uinput.ABS_X, last_x, syn=False)
                            virtual_device.emit(uinput.ABS_Y, last_y, syn=False)
                        # Emit the tap press
                        virtual_device.emit(uinput.BTN_TOUCH, 1)
                        virtual_device.syn()  # Synchronize after press
                elif event.value == 0:  # Finger released from the screen
                    # Check if it's a quick tap (short duration)
                    if tap_start_time and (time.time() - tap_start_time) < 0.3:  # Adjust tap duration threshold
                        if not ignore_event:
                            # Emit the tap release
                            virtual_device.emit(uinput.BTN_TOUCH, 0)
                            virtual_device.syn()  # Synchronize after release
                        print("Tap event completed.")
                    else:
                        print("Ignoring event due to swipe/multi-touch.")

                    # Reset state variables after release
                    ignore_event = False
                    last_x, last_y = None, None
                    tap_start_time = None
                    active_slots.clear()  # Clear active slots

            # Synchronize the virtual device state after each event set
            virtual_device.syn()

except KeyboardInterrupt:
    print("\nExiting tap filter script.")
    device.ungrab()
except Exception as e:
    print(f"Error: {e}")
    device.ungrab()
