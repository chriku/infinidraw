# Settings for my HUION H610
xsetwacom set "HUION Huion Tablet Pen stylus" MapToOutput "HEAD-1"
xsetwacom set "HUION Huion Tablet Pad pad" Button 1 "key ctrl z"
xsetwacom set "HUION Huion Tablet Pad pad" Button 2 "key a"
xsetwacom set "HUION Huion Tablet Pad pad" Button 3 "key d"
xsetwacom set "HUION Huion Tablet Pad pad" Button +11 "key ctrl n"
xsetwacom set "HUION Huion Tablet Pad pad" Button +12 "key ctrl s"
xinput set-prop "HUION Huion Tablet Pad pad" --type=float "Device Accel Constant Deceleration" 1
xinput set-prop "HUION Huion Tablet Pad pad" --type=float "Device Accel Adaptive Deceleration" 1
xinput set-prop "HUION Huion Tablet Pad pad" --type=float "Device Accel Velocity Scaling" 10
