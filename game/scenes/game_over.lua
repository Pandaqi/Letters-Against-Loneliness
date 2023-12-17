local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")

local gameOverText = nil
local continueButton = nil
local restartButton = nil
local hintButton = nil

local weWon = false

local function handleButtonEvent(event)
  local id = event.target.id
  
  -- remove the overlay again => NOPE, now we just create it once at the start, and modify based on if we won
  -- (but recycle it)
  -- composer.hideOverlay(true)
  
  -- go somewhere different depending on the button
  if id == 'continueButton' then
    GLOBALS.map:restartToCampaign()
  elseif id == 'restartButton' then
    GLOBALS.map:restart()
  elseif id == "hintButton" then
    
    local adAvailable = GLOBALS.admob.isLoaded("rewardedVideo")
    if adAvailable then
      GLOBALS.targetAfterAd = "hint"
      print("Trying to show an ad")
      GLOBALS.admob.show("rewardedVideo")
    else
      GLOBALS.map:restartWithHint()
    end
  end
end

function scene:show(event)
  if event.phase == 'will' then
    -- The scene is created ONCE in the create() function
    -- Here, when we show it, we just update the values to show the right stuff
    -- IMPORTANT: The parameters (win/score/etc.) are given to us via "event.params"
    weWon = event.params.didWeWin
    
    -- change game over text properly
    gameOverText.text = 'GAME OVER!'
    if weWon then
      gameOverText.text = 'YOU WON!'
    end
    
    -- if we did not win, we don't get a continue button
    if weWon then
      continueButton.alpha = 1
      restartButton.alpha = 0
      hintButton.alpha = 0
    else
      continueButton.alpha = 0
      restartButton.alpha = 1
      hintButton.alpha = 1
    end
    
  end
end

function scene:hide(event)
  
end

function scene:create(event)
  -- create the modal image once
  local magnifier = 1
  local modalSize = { width = 320*magnifier, height = 480*0.5*magnifier }
  local modal = display.newImageRect(scene.view, 'assets/interface/modalOverlay.png', modalSize.width, modalSize.height)
  modal.x = display.contentCenterX
  modal.y = display.contentCenterY
  
  local bs = 2 -- bs = buttonScale
  
  local x = modal.x
  local y = modal.y - 0.2*modalSize.height
  local marginBetweenButtons = 4
  local buttonHeight = (16 + marginBetweenButtons)*bs
  
  -- and the main game over text
  local textOptions = {
      parent = scene.view,
      x = x,
      y = y,
      font = GLOBALS.pixelFont,
      text = 'GAME OVER',
      fontSize = 64,
      align='center'
  } 
      
  gameOverText = display.newEmbossedText(textOptions)
  gameOverText:setFillColor(0,0,0)
  
  
  
  --- CONTINUE button ---
  y = y + buttonHeight
  continueButton = widget.newButton(
    {
        width = 65*bs,
        height = 16*bs,
        id = "continueButton",
        defaultFile = "assets/interface/continueButtonWide.png",
        overFile = "assets/interface/continueButtonWideOver.png",
        onRelease = handleButtonEvent
    }
  )
  continueButton.x = x
  continueButton.y = y
  scene.view:insert(continueButton)
  
  -- RESTART button
  y = y + buttonHeight
  restartButton = widget.newButton(
    {
        width = 65*bs,
        height = 16*bs,
        id = "restartButton",
        defaultFile = "assets/interface/restartButtonWide.png",
        overFile = "assets/interface/restartButtonWideOver.png",
        onRelease = handleButtonEvent
    }
  )
  restartButton.x = x
  restartButton.y = y
  scene.view:insert(restartButton)
  
  -- HINT button
  y = y + buttonHeight
  hintButton = widget.newButton(
    {
        width = 65*bs,
        height = 16*bs,
        id = "hintButton",
        defaultFile = "assets/interface/hintButtonWide.png",
        overFile = "assets/interface/hintButtonWideOver.png",
        onRelease = handleButtonEvent
    }
  )
  hintButton.x = x
  hintButton.y = y
  scene.view:insert(hintButton)
  
end

function scene:destroy(event)
  
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

