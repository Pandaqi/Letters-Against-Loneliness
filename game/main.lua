-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- hide the status bar (iOS)
display.setStatusBar( display.HiddenStatusBar )

-- Removes status bar on Android
-- NOTE: Might want to include a setting to disable this, as it's annoying when it keeps popping up/going away!
if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
    native.setProperty( "androidSystemUiVisibility", "lowProfile" )
else
    native.setProperty( "androidSystemUiVisibility", "immersiveSticky" ) 
end

-- make window fullscreen (for windows version)
native.setProperty("windowMode", "fullscreen")

-- include admob (will initialize below)
local admob = require( "plugin.admob" )

-- REAL ID = ca-app-pub-7465988806111884/2643390960
-- TEST ID = ca-app-pub-3940256099942544/5224354917
local adTestMode = false
local adUnitId = "ca-app-pub-3940256099942544/5224354917"
if not adTestMode then
  adUnitId = "ca-app-pub-7465988806111884/2643390960"
end

-- include the Corona "composer" module
local composer = require "composer"

-- activate multitouch (WHY IS THIS OFF BY DEFAULT??)
system.activate( "multitouch" )

-- randomly seed math stuff
math.randomseed( os.time() )

-- use nearest neighbour filtering => makes pixel art look good, instead of smushing it
display.setDefault('minTextureFilter', 'nearest')
display.setDefault('magTextureFilter', 'nearest')

-- include basic OOP structure
Object = require("tools.classic")
require("objects.globals")
    
-- create GLOBALS object
-- (do this only ONCE at the start, so it stays persistent throughout the game)
GLOBALS = Globals()
GLOBALS:loadAllAudio()

local function preloadRewardedAd()
  local adLoadParams = {
    adUnitId=adUnitId,
    childSafe=true,
    designedForFamilies=true,
    hasUserConsent=true,
    maxAdContentRating="G"
  }
  admob.load("rewardedVideo", adLoadParams)
  
  print("Trying to load rewarded ad")
end

local function adListener(event)
  if ( event.phase == "init" ) then
    print("Admob Initialized")
    print( event.provider )
    
    preloadRewardedAd()
  
  elseif ( event.phase == "failed" ) then
    print( event.type )
    print( event.isError )
    print( event.response )
  end
  
  if event.type == "rewardedVideo" then
    if event.phase == "displayed" then
      preloadRewardedAd()
    end
    
    if event.phase == "reward" then
      if GLOBALS.targetAfterAd == "unlock" then
        GLOBALS:unlockNextWorldAndReload()
      elseif GLOBALS.targetAfterAd == "hint" then
        GLOBALS.map:restartWithHint()
      end
    end
  end
end

local adParams = { testMode = adTestMode }

admob.init(adListener, adParams)
GLOBALS.admob = admob

-- load menu screen
composer.gotoScene( "scenes.intermediate_scene" )