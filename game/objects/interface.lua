Interface = Object:extend()

local widget = require("widget")

function Interface:destroy()
  -- pass
end

-----------
-- Stuff for MOVES
-----------
function Interface:setMoves(m)
  self.movesLeft = m
  self:updateMoves(0)
end

function Interface:noMovesLeft()
  return (self.movesLeft <= 0)
end

function Interface:getMovesFraction()
  return (self.movesLeft / self.maxMoves)
end

function Interface:updateMoves(dm)
  self.movesLeft = self.movesLeft + dm
  
  self.moveCounter.text = 'Moves left: ' .. tostring(self.movesLeft)
end

-----------
-- Stuff for COLLECTIBLES
-----------
function Interface:updateCollectibles(dc)
  self.numCollected = self.numCollected + dc
  
  if dc > 0 then 
    audio.play(GLOBALS.audio.letterdelivered)
  end
  
  self.collectibleCounter.text = 'Letters Delivered: ' .. tostring(self.numCollected)
end

function Interface:collectedEverything()
  return (self.numCollected >= self.totalNumCollectibles)
end

function Interface:setCollectibles(c)
  self.totalNumCollectibles = c
  self:updateCollectibles(0)
end

-----------
-- Stuff for interface with current MODIFIERS/EFFECTS
-- (update their position, their status, etc.)
-----------
function Interface:updateIcon(name, active)
  local obj = self.modifierIcons[name]
  
  if active then
    obj.fill.effect = nil
    obj.alpha = 1.0
  else
    obj.fill.effect = 'filter.grayscale'
    obj.alpha = 0.0
  end
end

function Interface:new(scene, levelData, ind)
  self.sceneGroup = scene.view

  local margin = 10
  
  local x = display.screenOriginX + margin
  local y = display.screenOriginY + margin
  
  
  ---------
  -- Create ICONS (modifiers/currently active effects)
  ---------
  self.iconGroup = display.newGroup()
  self.sceneGroup:insert(self.iconGroup)
  
  local defaultIconValues = {false}
  self.iconNames = {'letterSwitch'}
  self.iconTypes = {33}
  self.modifierIcons = {}
  
  local typesPresent = GLOBALS.map.tileTypes
  local iconsPresent = 0
  
  local iconX = 0
  for i=1,#self.iconNames do
    local myType = self.iconTypes[i]
    if typesPresent[myType] then
    
      local name = self.iconNames[i]
      local obj = display.newImageRect(self.iconGroup, 'assets/interface/' .. name .. '.png', 64, 32)
      
      obj.x = iconX
      iconX = iconX + obj.width
      
      self.modifierIcons[name] = obj
      
      self:updateIcon(name, defaultIconValues[i])
      
      iconsPresent = iconsPresent + 1
    end
  end
  
  self.iconGroup.x = display.contentCenterX
  self.iconGroup.y = display.screenOriginY + 10 + 0.5*32
  
  if iconsPresent > 0 and not GLOBALS.campaignScreen then
    -- finally, add some text above it, to show this is the powerup/modifier section
    local iconTextOptions = { 
      parent = self.iconGroup, 
      text = 'MODIFIERS', 
      x = 0, 
      y = -0.5*32, 
      font = GLOBALS.pixelFont, 
      fontSize = 12, 
      align = 'center' 
    }
    local iconText = display.newText(iconTextOptions)
    
    iconText.fill = {0.2,0.2,0.2,0.5}
  end
  
  --------
  -- Create CAMPAIGN/BACK button
  -------
  -- which function this button calls, depends on whether we're at the campaign screen or a regular level
  local connectedFunction = function(event) GLOBALS.map:restartToCampaign() end
  if GLOBALS.campaignScreen then
    connectedFunction = function(event) os.exit() end
  end
  
  local imageKey = 'assets/interface/backButton.png'
  local imageKeyOver = 'assets/interface/backButtonOver.png'
  if GLOBALS.campaignScreen then 
    imageKey = 'assets/interface/exitButton.png'
    imageKeyOver = 'assets/interface/exitButtonOver.png'
  end
  
  local backButton = widget.newButton(
    {
        width = 32,
        height = 32,
        defaultFile = imageKey,
        overFile = imageKeyOver,
        onRelease = connectedFunction,
    }
  )

  backButton.anchorX = 0
  backButton.anchorY = 0
  
  backButton.x = x
  backButton.y = y
  self.sceneGroup:insert(backButton)
  
  -- on the campaign screen, there is of course no need for the restart/hint buttons
  -- and also no need for the move/score counters
  if GLOBALS.campaignScreen then
    return self
  end
  
  -- I used to load the number of moves and collectibles from data
  -- BUT! That's not necessary. We can deduce that easily from the rest of the data
  --      "Number of moves" = "Length of solution array"
  if levelData.solution then
    self.maxMoves = #levelData.solution
  else
    -- if no solution is present, listen for the numMoves property
    if levelData.numMoves then
      self.maxMoves = levelData.numMoves
    
    -- if that's not even present, default to 6 (shouldn't happen, ever, but hey)
    else
      self.maxMoves = 6
    end
  end
  
  -- the map already counts the number of collectibles: use that!
  self.numCollectibles = GLOBALS.map.numCollectibles
  
  -- if it doesn't exist, or it's empty, set to default values
  if not self.maxMoves or self.maxMoves <= 0 then self.maxMoves = 10 end
  if not self.numCollectibles or self.numCollectibles <= 0 then self.numCollectibles = 10 end

  -- create move counter
  local options = { 
    parent = self.sceneGroup, 
    text = 'Letters Delivered: X', 
    x = display.contentWidth - display.screenOriginX - margin, 
    y = display.screenOriginY + margin, 
    font = GLOBALS.pixelFont, 
    fontSize = 16, 
    align = 'right' 
  }
  
  self.moveCounter = display.newText(options)
  self.moveCounter.anchorX, self.moveCounter.anchorY = 1, 0
  
  -- create collectible counter
  self.numCollected = 0

  options.y = options.y + 16 + 0.5*margin
  
  self.collectibleCounter = display.newText( options )
  self.collectibleCounter.anchorX, self.collectibleCounter.anchorY = 1, 0
  
  -- create ID displayer
  -- (so I know which level I'm playing, and can easily remove boring ones or save favourites)
  --[[
  self.idDisplay = display.newText(self.sceneGroup, 'ID Here', display.screenOriginX + margin, display.contentHeight - margin, native.systemFont, 16)
  self.idDisplay.anchorX, self.idDisplay.anchorY = 0,1
  self.idDisplay.text = "#" .. tostring(ind)
  --]]
  
  -- update both
  self:setMoves(self.maxMoves)
  self:setCollectibles(self.numCollectibles)
  
  -------
  -- Create restart button
  -------
  local restartButton = widget.newButton(
    {
        width = 32,
        height = 32,
        defaultFile = "assets/interface/restartButton.png",
        overFile = "assets/interface/restartButtonOver.png",
        onRelease = function(event) GLOBALS.map:restart() end
    }
  )

  restartButton.anchorX = 0
  restartButton.anchorY = 0
  
  x = x + 32 + 0.5*margin

  restartButton.x = x
  restartButton.y = y
  self.sceneGroup:insert(restartButton)
  
  --------
  -- Create HINT button
  -------
  local function hintBtnListener()
    local adAvailable = system.getInfo("platform") == "android" and GLOBALS.admob.isLoaded("rewardedVideo")
    if adAvailable then
      GLOBALS.targetAfterAd = "hint"
      GLOBALS.admob.show("rewardedVideo")
    else
      GLOBALS.map:restartWithHint()
    end
    
  end
  
  local showHintButton = (GLOBALS.curLevel ~= 'level1' and GLOBALS.curLevel ~= 'level2' and GLOBALS.curLevel ~= 'level3')
  
  print("CUR LEVEL")
  print(GLOBALS.nextLevelToLoad)
  
  if showHintButton then
  
    local hintButton = widget.newButton(
      {
          width = 32,
          height = 32,
          defaultFile = "assets/interface/hintButton.png",
          overFile = "assets/interface/hintButtonOver.png",
          onRelease = hintBtnListener
      }
    )

    hintButton.anchorX = 0
    hintButton.anchorY = 0
    
    x = x + 32 + 0.5*margin

    hintButton.x = x
    hintButton.y = y
    self.sceneGroup:insert(hintButton)
    
    -- ad indicator for mobile
    if system.getInfo("platform") == "android" then
      local adIndicator = display.newImage(self.sceneGroup, "assets/interface/ad_hint.png")
      x = x + 32 + 0.5*margin
      
      adIndicator.anchorX = 0
      adIndicator.anchorY = 0
      
      adIndicator.x = x
      adIndicator.y = y
      
      adIndicator.alpha = 0.75
    
    end
  end
  
  return self
end