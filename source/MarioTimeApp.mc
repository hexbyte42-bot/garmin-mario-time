using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;
using Toybox.Activity;
using Toybox.ActivityMonitor;

class MarioTimeApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new MarioTimeView()]; }
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
            if (System.getTimer() - animationStartTime > animationDuration + 500) {
                stopAnimation();
            }
        }
    }

    private function drawBackground(dc, hour) {
        var bgKey = :bg_day;
        if (selectedBackground == 0) {
            if (hour >= 22 || hour < 6) { bgKey = :bg_night; }
            else if (hour >= 12 && hour < 18) { bgKey = :bg_under; }
            else if (hour >= 18) { bgKey = :bg_castle; }
        } else {
            var map = {1 => :bg_day, 2 => :bg_night, 3 => :bg_under, 4 => :bg_castle};
            bgKey = map[selectedBackground];
        }

        if (bitmaps[bgKey] != null) {
            dc.drawBitmap(0, 0, bitmaps[bgKey]);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
            dc.clear();
        }
    }

    private function drawBlocks(dc, now, sinProgress) {
        var blockX = (screenWidth - 200) / 2;
        var blockY = 80 - (15 * sinProgress).toNumber();

        if (bitmaps[:block] != null) {
            dc.drawBitmap(blockX, blockY, bitmaps[:block]);
            dc.drawBitmap(blockX + 100, blockY, bitmaps[:block]);
        }

        var h = now.hour;
        if (!is24Hour) { h = (h > 12) ? h - 12 : (h == 0 ? 12 : h); }
        
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + 50, blockY + 30, timeFont, h.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + 150, blockY + 30, timeFont, now.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawCharacter(dc, sinProgress) {
        var bmp = getCharacterBitmap();
        if (bmp != null) {
            var charX = (screenWidth - 120) / 2;
            var charY = (375 - 120) - (60 * sinProgress).toNumber();
            dc.drawBitmap(charX, charY, bmp);
        }
    }

    function getCharacterBitmap() {
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
            if (jumpTimer == null) { jumpTimer = new Timer.Timer(); }
            jumpTimer.start(method(:onJumpUpdate), 33, true);
            WatchUi.requestUpdate();
        } catch (e) { stopAnimation(); }
    }

    function stopAnimation() {
        marioIsDown = true;
        animationStartTime = 0;
        if (jumpTimer != null) {
            try { jumpTimer.stop(); } catch (e) {}
            jumpTimer = null;
        }
        WatchUi.requestUpdate();
    }

    function onJumpUpdate() {
        if (System.getTimer() - animationStartTime >= animationDuration) {
            stopAnimation();
        } else {
            WatchUi.requestUpdate();
        }
    }

    function getAnimationProgress() {
        if (animationStartTime == 0) { return 0.0; }
        var elapsed = System.getTimer() - animationStartTime;
        return (elapsed >= animationDuration) ? 1.0 : elapsed.toFloat() / animationDuration;
    }

    function onEnterSleep() { inLowPower = true; stopAnimation(); }
    function onExitSleep() { inLowPower = false; WatchUi.requestUpdate(); }
    function onSettingsChanged() { loadSettings(); WatchUi.requestUpdate(); }

    function drawFitnessMetrics(dc, now) {
        if (iconsFont == null) { return; }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Battery
        var stats = System.getSystemStats();
        var batIcon = (stats.battery > 90) ? "h" : (stats.battery < 20 ? "k" : "m");
        if (stats.charging) { batIcon = "l"; }
        dc.drawText(screenWidth / 2, 15, iconsFont, batIcon, Graphics.TEXT_JUSTIFY_CENTER);

        // Steps
        var info = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        dc.drawText(35, screenHeight / 2 - 25, iconsFont, "s", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(35 + 7, screenHeight / 2 + 15, Graphics.FONT_XTINY, steps.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);

        // HR
        var hr = "--";
        var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
        var hrSample = hrIter.next();
        if (hrSample != null && hrSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
            hr = hrSample.heartRate.format("%d");
        }
        dc.drawText(screenWidth - 20, screenHeight / 2 - 25, iconsFont, "p", Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(screenWidth - 30, screenHeight / 2 + 15, Graphics.FONT_XTINY, hr, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
