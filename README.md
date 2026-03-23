# Mario Time for Garmin (Color Version)

A port of the popular Pebble Mario watchface to Garmin Connect IQ devices, specifically designed for the Garmin Forerunner 265.

## Features

- Mario jumps every minute
- Question blocks bounce and the time moves with the blocks during the minute change
- Watch battery indicator at the top center
- Garmin activity metrics for steps and heart rate
- Character selection: Mario, Luigi, Bowser
- Automatic and manual backgrounds using the Pebble time-of-day schedule
- On-device settings for character and background selection
- April 1 Bowser override

## Pebble Parity

Implemented to stay close to the upstream Pebble watchface:

- Minute jump animation with delayed block bounce
- April 1 Bowser override
- Auto/manual background selection using the original time-of-day split
- Configurable character switching

Remaining differences from upstream Pebble behavior:

- The date row was removed to leave room for the battery indicator on FR265
- No Pebble companion app features such as phone battery, weather, Bluetooth disconnect icon, or vibration alerts
- The Garmin layout is scaled for the FR265 display rather than reproducing Pebble pixel coordinates exactly
- Garmin adds watch battery, steps, and heart-rate data that were not part of the original Pebble face

## Settings

This watch face now supports both:

- Connect IQ app settings
- On-device watch-face settings on the Garmin watch itself

On-device settings currently expose:

- Character
- Background

## 🎨 Color Resources

This version uses **color resources specifically created for Pebble Time** (the color version of Pebble), which provides:

- **Rich color backgrounds** (Day, Night, Underground, Castle themes)
- **Color character sprites** (Mario, Luigi, Bowser in full color)
- **Color UI elements** (blocks and character art from the original color build)
- **Optimized for color displays** like the Garmin Forerunner 265

All graphics have been copied directly from the original Pebble Mario repository's color assets.

## 📦 Project Structure

```
garmin-mario-time/
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

Specifically using the **color assets** created for **Pebble Time** (basalt platform) to keep the Garmin port visually close to the original color watchface on Forerunner 265 hardware.

Enjoy your Mario Time watchface.
