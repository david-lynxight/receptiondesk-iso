#!/bin/bash
sleep 15

rm -rf ~/snap/chromium/common/chromium/Default/Sessions/*

chromium  --disable-pinch --overscroll-history-navigation=0  --start-fullscreen --disable-infobars --noerrdialogs --disable-session-crashed-bubble --noerrors --use-fake-ui-for-media-stream --test-type  --autoplay-policy=no-user-gesture-required  http://192.168.0.229:51000/inspections/leisure