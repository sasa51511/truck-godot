#!/bin/bash
adb install -r truck.apk
adb shell run-as com.sasa.truckspike sh -c 'mkdir -p files; touch files/auto'
adb logcat -c
adb shell am start -n com.sasa.truckspike/com.godot.game.GodotApp
sleep 30
adb exec-out screencap -p > /tmp/shot1.png
adb shell input swipe 553 278 553 278 9000 &
sleep 7
adb exec-out screencap -p > /tmp/shot2.png
adb shell input swipe 158 278 158 278 4000 &
sleep 5
adb exec-out screencap -p > /tmp/shot3.png
sleep 4
adb shell wm size > /tmp/size.txt
adb logcat -d | grep -iE "godot|AndroidRuntime|FATAL|vulkan|error" | tail -120 > /tmp/log.txt
cat /tmp/size.txt >> /tmp/log.txt
adb shell pidof com.sasa.truckspike >> /tmp/log.txt || echo "NOT RUNNING" >> /tmp/log.txt
exit 0
