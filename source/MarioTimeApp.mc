using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;

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

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();

        try { marioNormalBitmap = WatchUi.loadResource(Rez.Drawables.mario_normal); } catch (e) { marioNormalBitmap = null; }
        try { marioJumpBitmap = WatchUi.loadResource(Rez.Drawables.mario_jump); } catch (e) { marioJumpBitmap = null; }
        try { blockBitmap = WatchUi.loadResource(Rez.Drawables.block); } catch (e) { blockBitmap = null; }
        try { backgroundDayBitmap = WatchUi.loadResource(Rez.Drawables.background_day); } catch (e) { backgroundDayBitmap = null; }
        try { backgroundNightBitmap = WatchUi.loadResource(Rez.Drawables.background_night); } catch (e) { backgroundNightBitmap = null; }
        try { backgroundUndergroundBitmap = WatchUi.loadResource(Rez.Drawables.background_underground); } catch (e) { backgroundUndergroundBitmap = null; }
        try { backgroundCastleBitmap = WatchUi.loadResource(Rez.Drawables.background_castle); } catch (e) { backgroundCastleBitmap = null; }

        return;
    }

    function onUpdate(dc) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        // Check for minute change - this is the correct way to detect minute changes
        if (now.min != lastMinute) {
            lastMinute = now.min;
            startMarioJump();
        }

        // Draw background (now 416x416, fills the screen)
        var hour = now.hour;
        var bg = backgroundDayBitmap;

        // Enhanced background switching logic
        if (hour >= 22 || hour < 6) {
            bg = backgroundNightBitmap;
        } else if (hour >= 6 && hour < 12) {
            bg = backgroundDayBitmap;
        } else if (hour >= 12 && hour < 18) {
            bg = backgroundUndergroundBitmap;
        } else {
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

        // Animate blocks when Mario jumps
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
        var textY = blockY + 30;  // Center text in block
        
        // Load custom pixel font
        var timeFont = WatchUi.loadResource(Rez.Fonts.pixel_font);
        
        // Original project uses brown color rgb(117, 58, 0)
        dc.setColor(0x753A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(blockX + blockSize/2, textY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(blockX + blockSize + blockSize/2, textY, timeFont, minStr, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw Mario (120x120)
        var marioBitmap = marioIsDown ? marioNormalBitmap : marioJumpBitmap;
        if (marioBitmap != null) {
            var marioX = (screenWidth - 120) / 2;
            // Position Mario on the ground (ground at Y=375, Mario height=120)
            var marioY = 375 - 120;  // Mario stands on ground at Y=375

            if (!marioIsDown) {
                var progress = getAnimationProgress();
                var jumpHeight = 60;
                var offset = (jumpHeight * Math.sin(progress * Math.PI)).toNumber();
                marioY = marioY - offset;  // Jump upward (negative offset)
            }

            dc.drawBitmap(marioX, marioY, marioBitmap);
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
}