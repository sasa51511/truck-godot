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
adb shell input swipe 136 262 136 262 3000 &
sleep 4
adb exec-out screencap -p > /tmp/shot3.png
adb shell input tap 557 25
sleep 3
adb exec-out screencap -p > /tmp/shot4.png
adb shell input tap 557 25
sleep 3
adb exec-out screencap -p > /tmp/shot5.png
sleep 3
adb shell wm size > /tmp/size.txt
adb logcat -d | grep -iE "godot|AndroidRuntime|FATAL|vulkan|error" | tail -120 > /tmp/log.txt
cat /tmp/size.txt >> /tmp/log.txt
adb shell pidof com.sasa.truckspike >> /tmp/log.txt || echo "NOT RUNNING" >> /tmp/log.txt
exit 0
