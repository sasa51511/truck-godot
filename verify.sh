#!/bin/bash
adb install -r truck.apk
adb shell run-as com.sasa.truckspike sh -c 'mkdir -p files; touch files/auto'
adb logcat -c
adb shell am start -n com.sasa.truckspike/com.godot.game.GodotApp
sleep 75
adb exec-out screencap -p > /tmp/shot1.png
sleep 20
for i in 1 2 3 4 5; do adb exec-out run-as com.sasa.truckspike cat files/s$i.png > /tmp/shot$((i+1)).png; done
adb shell run-as com.sasa.truckspike ls -R files > /tmp/ls.txt 2>&1
adb shell wm size > /tmp/size.txt
adb logcat -d | grep -iE "godot|AndroidRuntime|FATAL|vulkan|error" | tail -120 > /tmp/log.txt
cat /tmp/size.txt >> /tmp/log.txt
adb logcat -d | grep " MESH " | sed "s/.*MESH //" | cut -c1-120 > /tmp/mesh.txt; cat /tmp/mesh.txt >> /tmp/log.txt
adb shell pidof com.sasa.truckspike >> /tmp/log.txt || echo "NOT RUNNING" >> /tmp/log.txt

cat /tmp/ls.txt >> /tmp/log.txt
exit 0
