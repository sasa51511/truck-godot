#!/bin/bash
adb install -r truck.apk
adb logcat -c
adb shell am start -n com.sasa.truckspike/com.godot.game.GodotApp
sleep 25
adb exec-out screencap -p > /tmp/shot1.png
adb shell wm size > /tmp/size.txt
adb shell input swipe 1900 900 1900 900 4000 &
adb shell input swipe 2000 950 2000 950 4000 &
sleep 6
adb exec-out screencap -p > /tmp/shot2.png
sleep 2
adb logcat -d | grep -iE "godot|AndroidRuntime|FATAL|vulkan" | tail -80 > /tmp/log.txt
cat /tmp/size.txt >> /tmp/log.txt
adb shell pidof com.sasa.truckspike >> /tmp/log.txt || echo "NOT RUNNING" >> /tmp/log.txt
exit 0
