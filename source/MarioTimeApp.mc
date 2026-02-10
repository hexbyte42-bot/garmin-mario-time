using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy;
using Toybox.Sensor;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;
using Toybox.UserProfile;

// Properties for settings
class Properties {
    static const character = 1;
    static const background = 2;
}

class MarioTimeApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    function onStop(state) {}

    function getInitialView() {
        return [new MarioTimeView()];
    }
}

class MarioTimeView extends WatchUi.WatchFace {
    // Assets
    var bitmaps = {};
    var timeFont, iconsFont;

    // State
    var marioIsDown = true;
    var animationStartTime = 0;
    var animationDuration = 400;
    var jumpTimer = null;
    var inLowPower = false;
    
    // Cached values
    var screenWidth, screenHeight;
    var lastMinute = -1;
    var is24Hour = true;
    
    // User Settings
    var selectedCharacter = 0; 
    var selectedBackground = 0;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();

        // Batch load essential resources
        var resMap = {
            :mario_normal => Rez.Drawables.mario_normal, :mario_jump => Rez.Drawables.mario_jump,
            :luigi_normal => Rez.Drawables.luigi_normal, :luigi_jump => Rez.Drawables.luigi_jump,
            :bowser_normal => Rez.Drawables.bowser_normal, :bowser_jump => Rez.Drawables.bowser_jump,
            :block => Rez.Drawables.block,
            :bg_day => Rez.Drawables.background_day, :bg_night => Rez.Drawables.background_night,
            :bg_under => Rez.Drawables.background_underground, :bg_castle => Rez.Drawables.background_castle
        };
        
        var keys = resMap.keys();
        for (var i = 0; i < keys.size(); i++) {
            try { bitmaps[keys[i]] = WatchUi.loadResource(resMap[keys[i]]); } catch (e) { bitmaps[keys[i]] = null; }
        }
        
        try { timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font); } catch (e) { timeFont = Graphics.FONT_MEDIUM; }
        try { iconsFont = WatchUi.loadResource(Rez.Fonts.IconsFont); } catch (e) { iconsFont = null; }

        loadSettings();
    }

    function loadSettings() {
        // Use modern Properties API with fallback for older devices
        if (Application has :Properties) {
            selectedCharacter = Application.Properties.getValue("Character");
            selectedBackground = Application.Properties.getValue("Background");
        } else {
            var app = Application.getApp();
            selectedCharacter = app.getProperty("Character");
            selectedBackground = app.getProperty("Background");
        }
        selectedCharacter = (selectedCharacter != null) ? selectedCharacter : 0;
        selectedBackground = (selectedBackground != null) ? selectedBackground : 0;
        
        is24Hour = System.getDeviceSettings().is24Hour;
    }

    function onHide() {
        stopAnimation();
        WatchFace.onHide();
    }

    function onUpdate(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        // 1. Logic & Safety
        handleSafetyCheck();
        if (now.min != lastMinute && !inLowPower) {
            lastMinute = now.min;
            startMarioJump();
        }

        // 2. Rendering
        drawBackground(dc, now.hour);
        
        var sinProgress = 0;
        if (!marioIsDown) {
            sinProgress = Math.sin(getAnimationProgress() * Math.PI);
        }

        drawBlocks(dc, now, sinProgress);
        drawCharacter(dc, sinProgress);
        drawFitnessMetrics(dc, now);
    }

    private function handleSafetyCheck() {
        if (!marioIsDown && animationStartTime > 0) {
            try {
                var elapsed = System.getTimer() - animationStartTime;
                // If animation has been running longer than expected (with 500ms safety margin)
                if (elapsed > animationDuration + 500) {
                    stopAnimation();
                }
            } catch (e) {
                // Fallback: if any error occurs during safety check, force reset
                stopAnimation();
            }
        }
    }

    private function drawBackground(dc, hour) {
        var bgKey = :bg_day;
        if (selectedBackground == 0) { // Auto mode
            if (hour >= 22 || hour < 6) { 
                bgKey = :bg_night; 
            } else if (hour >= 6 && hour < 12) {
                bgKey = :bg_day;
            } else if (hour >= 12 && hour < 18) { 
                bgKey = :bg_under; 
            } else {
                bgKey = :bg_castle;
            }
        } else {
            var map = {1 => :bg_day, 2 => :bg_night, 3 => :bg_under, 4 => :bg_castle};
            bgKey = map[selectedBackground];
        }

        if (bitmaps[bgKey] != null) {
            dc.drawBitmap(0, 0, bitmaps[bgKey]);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRectangle(0, 0, screenWidth, screenHeight);
        }
    }

    private function drawBlocks(dc, now, sinProgress) {
        var blockSize = 100;
        var blockX = (screenWidth - blockSize * 2) / 2;
        var blockY = 80 - (15 * sinProgress).toNumber();

        if (bitmaps[:block] != null) {
            dc.drawBitmap(blockX, blockY, bitmaps[:block]);
            dc.drawBitmap(blockX + blockSize, blockY, bitmaps[:block]);
        }

        var hourVal = now.hour;
        if (!is24Hour) {
            if (hourVal > 12) { hourVal = hourVal - 12; } else if (hourVal == 0) { hourVal = 12; }
        }
        var hourStr = hourVal.format("%d");
        var minStr = now.min.format("%02d");

        // Draw time in blocks using custom pixel font
        // Original project uses brown color rgb(117, 58, 0)
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + blockSize/2, blockY + 30, timeFont, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + blockSize + blockSize/2, blockY + 30, timeFont, minStr, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawCharacter(dc, sinProgress) {
        var characterBitmap = getCurrentCharacterBitmap();
        if (characterBitmap != null) {
            var charX = (screenWidth - 120) / 2;
            // Position character on the ground (ground at Y=375, character height=120)
            var charY = 375 - 120;  // Character stands on ground at Y=375
            charY = charY - (60 * sinProgress).toNumber();  // Jump upward (negative offset)

            dc.drawBitmap(charX, charY, characterBitmap);
        }
    }

    function getCurrentCharacterBitmap() {
        var isJumping = !marioIsDown;
        if (selectedCharacter == 1) { // Luigi
            return isJumping ? bitmaps[:luigi_jump] : bitmaps[:luigi_normal];
        } else if (selectedCharacter == 2) { // Bowser
            return isJumping ? bitmaps[:bowser_jump] : bitmaps[:bowser_normal];
        } else { // Mario (default)
            return isJumping ? bitmaps[:mario_jump] : bitmaps[:mario_normal];
        }
    }

    function startMarioJump() {
        if (!marioIsDown || inLowPower) { return; }
        try {
            marioIsDown = false;
            animationStartTime = System.getTimer();
            if (jumpTimer == null) { 
                jumpTimer = new Timer.Timer(); 
            } else {
                // Stop any existing timer to prevent conflicts
                jumpTimer.stop();
            }
            jumpTimer.start(method(:onJumpUpdate), 33, true); // ~30 FPS
            WatchUi.requestUpdate();
        } catch (e) {
            // Log error and ensure state is reset to prevent being stuck
            stopAnimation();
        }
    }

    function stopAnimation() {
        marioIsDown = true;
        animationStartTime = 0;
        if (jumpTimer != null) {
            try {
                jumpTimer.stop();
            } catch (e) {
                // Ignore errors during cleanup
            }
            jumpTimer = null;
        }
        WatchUi.requestUpdate();
    }

    function onJumpUpdate() {
        try {
            var elapsed = System.getTimer() - animationStartTime;
            if (elapsed >= animationDuration) {
                stopAnimation();
            } else {
                WatchUi.requestUpdate();
            }
        } catch (e) {
            // Safety fallback: if any error occurs during animation update, reset state
            stopAnimation();
        }
    }

    function getAnimationProgress() {
        if (animationStartTime == 0) { return 0.0; }
        var elapsed = System.getTimer() - animationStartTime;
        if (elapsed >= animationDuration) { return 1.0; }
        return elapsed.toFloat() / animationDuration.toFloat();
    }

    // Handle partial updates to ensure smooth animation and proper state transitions
    function onPartialUpdate(dc) {
        if (!marioIsDown) {
            WatchUi.requestUpdate();
        }
    }
    
    // Override to handle settings changes
    function onSettingsChanged() {
        loadSettings();
        WatchUi.requestUpdate();
    }
    
    function onEnterSleep() { 
        inLowPower = true; 
        stopAnimation(); 
    }
    
    function onExitSleep() { 
        inLowPower = false; 
        WatchUi.requestUpdate(); 
    }
    
    function drawFitnessMetrics(dc, now) {
        if (iconsFont == null) { 
            // Fallback to default font if icons font not available
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        
        // Top: Battery icon only (no text, just icon indicating battery level)
        var batteryLevel = 0;
        try {
            var stats = System.getSystemStats();
            if (stats != null && stats.battery != null) {
                batteryLevel = stats.battery;
            }
        } catch(e) {
            // Fallback if system stats not available
        }
        
        // Determine battery icon based on level
        var batteryIcon = "m"; // default medium battery
        if (batteryLevel >= 90) {
            batteryIcon = "h"; // high battery
        } else if (batteryLevel < 20) {
            batteryIcon = "k"; // low battery
        }
        
        // Check if charging (try to get charging status separately)
        try {
            var stats = System.getSystemStats();
            if (stats.charging) {
                batteryIcon = "l"; // charging icon
            }
        } catch(e) {
            // Ignore if charging status not available
        }
        
        // Left side: Steps count with icon
        var steps = 0;
        var hasSteps = false;
        try {
            var activityInfo = ActivityMonitor.getInfo();
            if (activityInfo != null && activityInfo.steps != null) {
                steps = activityInfo.steps;
                hasSteps = true;
            }
        } catch(e) {
            // Fallback if activity monitor not available
        }
        
        // Right side: Heart rate with icon (following reference project approach)
        var heartRate = 0;
        var hasHeartRate = false;
        
        // Check if heart rate data is available in the activity info
        if (Activity.Info has :currentHeartRate) {
            var activityInfo = Activity.getActivityInfo();
            if (activityInfo != null && activityInfo.currentHeartRate != null && activityInfo.currentHeartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRate = activityInfo.currentHeartRate;
                hasHeartRate = true;
            }
        }
        // If not available in activity info, try to get from history
        if (!hasHeartRate && ActivityMonitor has :getHeartRateHistory) {
            var hrHistory = ActivityMonitor.getHeartRateHistory(new Time.Duration(60), true).next(); // Try to get latest entry from the last minute
            if (hrHistory != null && hrHistory.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRate = hrHistory.heartRate;
                hasHeartRate = true;
            }
        }
        
        // Draw battery icon at the top center
        if (iconsFont != null) {
            dc.drawText(screenWidth / 2, 15, iconsFont, batteryIcon, Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw steps icon at 9 o'clock position (left side, middle height) - icon on top, data below
        var iconX = 35; // Fixed icon position (moved right to accommodate 5-digit numbers)
        
        if (iconsFont != null) {
            dc.drawText(iconX, screenHeight / 2 - 25, iconsFont, "s", Graphics.TEXT_JUSTIFY_LEFT);
        }
        
        // Draw steps count below the icon, centered when possible
        var stepsText = hasSteps ? steps.format("%d") : "--";
        var stepsTextWidth = dc.getTextWidthInPixels(stepsText, Graphics.FONT_XTINY);
        
        // Calculate ideal text position (centered under icon, assuming icon center is at iconX + 7)
        var iconCenterX = iconX + 7; // Approximate center of icon
        var idealTextX = iconCenterX - stepsTextWidth / 2;
        
        // Ensure text doesn't overflow left edge (min 5px)
        var minLeftEdge = 5;
        var textX = idealTextX;
        if (idealTextX < minLeftEdge) {
            textX = minLeftEdge; // Shift right to prevent overflow, breaking center alignment
        }
        
        dc.drawText(textX, screenHeight / 2 + 15, Graphics.FONT_XTINY, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Draw heart rate icon at 3 o'clock position (right side, middle height) - icon on top, data below
        if (iconsFont != null) {
            dc.drawText(screenWidth - 20, screenHeight / 2 - 25, iconsFont, "p", Graphics.TEXT_JUSTIFY_RIGHT); // "p" for heart rate/pulse icon on top
        }
        
        // Draw heart rate value below the icon, centered under the icon
        var hrText = hasHeartRate ? heartRate.format("%d") : "--";
        var hrTextWidth = dc.getTextWidthInPixels(hrText, Graphics.FONT_XTINY);
        // Center the text under the heart rate icon at 3 o'clock position, with increased spacing
        // Approximate center of icon "p" when drawn at x=screenWidth-20
        var hrCenterX = screenWidth - 30; // Approximate center of icon
        dc.drawText(hrCenterX - hrTextWidth / 2, screenHeight / 2 + 15, Graphics.FONT_XTINY, hrText, Graphics.TEXT_JUSTIFY_LEFT);
    }
}