using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;

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
    var marioNormalBitmap;
    var marioJumpBitmap;
    var luigiNormalBitmap;
    var luigiJumpBitmap;
    var bowserNormalBitmap;
    var bowserJumpBitmap;
    var blockBitmap;
    var backgroundDayBitmap;
    var backgroundNightBitmap;
    var backgroundUndergroundBitmap;
    var backgroundCastleBitmap;

    var marioIsDown = true;
    var animationStartTime = 0;
    var animationDuration = 400;
    var jumpTimer = null;

    var screenWidth = 0;
    var screenHeight = 0;
    var lastMinute = -1;
    
    // Settings variables
    var selectedCharacter = 0;  // 0=Mario, 1=Luigi, 2=Bowser
    var selectedBackground = 0; // 0=Auto, 1=Day, 2=Night, 3=Underground, 4=Castle

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();

        try { marioNormalBitmap = WatchUi.loadResource(Rez.Drawables.mario_normal); } catch (e) { marioNormalBitmap = null; }
        try { marioJumpBitmap = WatchUi.loadResource(Rez.Drawables.mario_jump); } catch (e) { marioJumpBitmap = null; }
        try { luigiNormalBitmap = WatchUi.loadResource(Rez.Drawables.luigi_normal); } catch (e) { luigiNormalBitmap = null; }
        try { luigiJumpBitmap = WatchUi.loadResource(Rez.Drawables.luigi_jump); } catch (e) { luigiJumpBitmap = null; }
        try { bowserNormalBitmap = WatchUi.loadResource(Rez.Drawables.bowser_normal); } catch (e) { bowserNormalBitmap = null; }
        try { bowserJumpBitmap = WatchUi.loadResource(Rez.Drawables.bowser_jump); } catch (e) { bowserJumpBitmap = null; }
        try { blockBitmap = WatchUi.loadResource(Rez.Drawables.block); } catch (e) { blockBitmap = null; }
        try { backgroundDayBitmap = WatchUi.loadResource(Rez.Drawables.background_day); } catch (e) { backgroundDayBitmap = null; }
        try { backgroundNightBitmap = WatchUi.loadResource(Rez.Drawables.background_night); } catch (e) { backgroundNightBitmap = null; }
        try { backgroundUndergroundBitmap = WatchUi.loadResource(Rez.Drawables.background_underground); } catch (e) { backgroundUndergroundBitmap = null; }
        try { backgroundCastleBitmap = WatchUi.loadResource(Rez.Drawables.background_castle); } catch (e) { backgroundCastleBitmap = null; }

        // Load settings
        loadSettings();

        return;
    }

    function loadSettings() {
        selectedCharacter = WatchUi.getConfigurationValue(Properties.character, 0).toNumber();
        selectedBackground = WatchUi.getConfigurationValue(Properties.background, 0).toNumber();
    }

    function onUpdate(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        // Check for minute change - this is the correct way to detect minute changes
        if (now.min != lastMinute) {
            lastMinute = now.min;
            startMarioJump();
        }

        // Draw background based on settings
        var hour = now.hour;
        var bg = backgroundDayBitmap;

        if (selectedBackground == 0) { // Auto mode
            if (hour >= 22 || hour < 6) {
                bg = backgroundNightBitmap;
            } else if (hour >= 6 && hour < 12) {
                bg = backgroundDayBitmap;
            } else if (hour >= 12 && hour < 18) {
                bg = backgroundUndergroundBitmap;
            } else {
                bg = backgroundCastleBitmap;
            }
        } else if (selectedBackground == 1) { // Day
            bg = backgroundDayBitmap;
        } else if (selectedBackground == 2) { // Night
            bg = backgroundNightBitmap;
        } else if (selectedBackground == 3) { // Underground
            bg = backgroundUndergroundBitmap;
        } else if (selectedBackground == 4) { // Castle
            bg = backgroundCastleBitmap;
        }

        if (bg != null) {
            dc.drawBitmap(0, 0, bg);
        } else {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.fillRectangle(0, 0, screenWidth, screenHeight);
        }

        // Calculate block positions (blocks are 100x100)
        var blockSize = 100;
        var blockX = (screenWidth - blockSize * 2) / 2;
        var blockY = 80;

        // Animate blocks when character jumps
        if (!marioIsDown) {
            var progress = getAnimationProgress();
            var bounceHeight = 15;
            blockY = blockY - (bounceHeight * Math.sin(progress * Math.PI)).toNumber();
        }

        // Draw blocks
        if (blockBitmap != null) {
            dc.drawBitmap(blockX, blockY, blockBitmap);
            dc.drawBitmap(blockX + blockSize, blockY, blockBitmap);
        }

        // Draw time in blocks (centered in each 100x100 block)
        var hourVal = now.hour;
        var minVal = now.min;
        var is24Hour = System.getDeviceSettings().is24Hour;
        if (!is24Hour) {
            if (hourVal > 12) { hourVal = hourVal - 12; } else if (hourVal == 0) { hourVal = 12; }
        }
        var hourStr = hourVal.format("%d");
        var minStr = minVal.format("%02d");

        // Draw time in blocks using custom pixel font
        var timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font);
        var textY = blockY + 30;  // Center text in block
        
        // Original project uses brown color rgb(117, 58, 0)
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + blockSize/2, textY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + blockSize + blockSize/2, textY, timeFont, minStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw selected character (120x120)
        var characterBitmap = getCurrentCharacterBitmap();
        if (characterBitmap != null) {
            var charX = (screenWidth - 120) / 2;
            // Position character on the ground (ground at Y=375, character height=120)
            var charY = 375 - 120;  // Character stands on ground at Y=375

            if (!marioIsDown) {
                var progress = getAnimationProgress();
                var jumpHeight = 60;
                var offset = (jumpHeight * Math.sin(progress * Math.PI)).toNumber();
                charY = charY - offset;  // Jump upward (negative offset)
            }

            dc.drawBitmap(charX, charY, characterBitmap);
        }
    }

    function getCurrentCharacterBitmap() {
        var isJumping = !marioIsDown;
        if (selectedCharacter == 1) { // Luigi
            return isJumping ? luigiJumpBitmap : luigiNormalBitmap;
        } else if (selectedCharacter == 2) { // Bowser
            return isJumping ? bowserJumpBitmap : bowserNormalBitmap;
        } else { // Mario (default)
            return isJumping ? marioJumpBitmap : marioNormalBitmap;
        }
    }

    function getAnimationProgress() {
        if (animationStartTime == 0) { return 0.0; }
        var elapsed = System.getTimer() - animationStartTime;
        if (elapsed >= animationDuration) { return 1.0; }
        return elapsed.toFloat() / animationDuration.toFloat();
    }

    function startMarioJump() {
        if (!marioIsDown) { return; }
        marioIsDown = false;
        animationStartTime = System.getTimer();
        if (jumpTimer == null) { 
            jumpTimer = new Timer.Timer(); 
        }
        jumpTimer.start(method(:onJumpUpdate), 33, true); // ~30 FPS
        WatchUi.requestUpdate();
    }

    function onJumpUpdate() {
        var elapsed = System.getTimer() - animationStartTime;
        if (elapsed >= animationDuration) {
            marioIsDown = true;
            animationStartTime = 0;
            if (jumpTimer != null) {
                jumpTimer.stop();
                jumpTimer = null;
            }
        }
        WatchUi.requestUpdate();
    }

    // Handle partial updates to ensure smooth animation
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
}