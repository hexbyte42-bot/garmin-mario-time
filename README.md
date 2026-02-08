# Mario Time for Garmin (Color Version)

A port of the popular Pebble Mario watchface to Garmin Connect IQ devices, specifically designed for the Garmin Forerunner 265.

## 🎮 Features

- **Mario jumps every minute** (just like the original!)
- **Question blocks bounce** when Mario jumps
- **Custom pixel fonts** for time and date display
- **Date display** (Day, Month, Date)
- **Watch battery indicator only** (simplified as requested)
- **Character selection** (Mario, Luigi, Bowser)
- **Auto background** that changes with time of day
- **April Fools surprise** (Bowser appears on April 1st!)

## 🎨 Color Resources

This version uses **color resources specifically created for Pebble Time** (the color version of Pebble), which provides:

- **Rich color backgrounds** (Day, Night, Underground, Castle themes)
- **Color character sprites** (Mario, Luigi, Bowser in full color)
- **Color UI elements** (blocks, battery icons with proper colors)
- **Optimized for color displays** like the Garmin Forerunner 265

All graphics have been copied directly from the original Pebble Mario repository's color assets.

## 📦 Project Structure

```
garmin-mario-time-color/
├── README.md
├── manifest.xml
├── build.xml
├── resources/
│   ├── mario_normal.png        ← Color version from Pebble Time
│   ├── mario_jump.png          ← Color version from Pebble Time
│   ├── luigi_normal.png        ← Color version from Pebble Time
│   ├── luigi_jump.png          ← Color version from Pebble Time
│   ├── bowser_normal.png       ← Color version from Pebble Time
│   ├── bowser_jump.png         ← Color version from Pebble Time
│   ├── background_day.png      ← Color basalt version (Pebble Time)
│   ├── background_night.png    ← Color basalt version (Pebble Time)
│   ├── background_underground.png ← Color basalt version (Pebble Time)
│   ├── background_castle.png   ← Color basalt version (Pebble Time)
│   ├── block.png              ← Color version from Pebble Time
│   ├── watch_battery.png      ← Color version from Pebble Time
│   ├── Gamegirl.ttf           ← Original font
│   └── emulogic.ttf           ← Original font
└── source/
    └── MarioTimeApp.mc        # Main source code
```

## 🔧 Setup Instructions

1. **Clone this repository**
2. **Install Garmin Connect IQ SDK** on your machine
3. **Set environment variable**: `export CONNECTIQ_SDK=/path/to/sdk`
4. **Build the watchface**: `ant build`
5. **Install to your watch**: `ant install`

## 📥 Resources Source

All graphics and font files have been **copied directly from the original Pebble Mario watchface repository**:
- https://github.com/ClusterM/pebble-mario

Specifically using the **color assets** created for **Pebble Time** (basalt platform) to ensure the best visual experience on your color Garmin Forerunner 265!

Enjoy your Mario Time watchface! 🍄