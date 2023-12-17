Map = Object:extend()

local composer = require('composer')
local animation = require("plugin.animation")

--[[
-- Amitp (Red Blob) on hexagonals: https://www.redblobgames.com/grids/hexagons/
--]]

function Map:reload()
  composer.gotoScene('scenes.intermediate_scene')
end

function Map:restart(autoSol)
  autoSol = autoSol or false
  
  GLOBALS.nextLevelToLoad = GLOBALS.map.ind
  GLOBALS.nextLevelCampaignIndex = GLOBALS.nextLevelCampaignIndex
  GLOBALS.autoSolution = autoSol
  GLOBALS.map:reload()
end

function Map:restartWithHint()
  -- do a regular restart, but turn on auto solution
  self:restart(true)
end

function Map:restartToCampaign()
  GLOBALS.nextLevelToLoad = 'campaign_screen'
  GLOBALS.nextLevelCampaignIndex = nil
  GLOBALS.autoSolution = false
  
  GLOBALS.map:reload()
end

function Map:backToMenu()
  -- pass
  -- TO DO => simply switch to menu scene
end

function Map:gameOver(didWeWin)
  -- if the tutorial isn't done, wait with displaying this modal
  -- save the win/lose variable on the tutorial, and it will call it when it has the time
  if not GLOBALS.tutorial.isDone then
    GLOBALS.tutorial.didWeWin = didWeWin
    return
  end
  
  -- save the result of current events!
  -- if current level is part of the campaign ...
  -- AND we won ...
  if self.nextLevelCampaignIndex and didWeWin then
    GLOBALS:unlockNextWorldAndReload(true)
  end
  
  -- play correct audio
  local audioKey = GLOBALS.audio.gamewin
  if not didWeWin then audioKey = GLOBALS.audio.gameloss end
  audio.play(audioKey)

  -- display overlay (+ pass parameters, like if we won)
  local overlayOptions = {
    isModal = true,
    effect = "fade",
    time = 400,
    params = {
      didWeWin = didWeWin
      },
  }
  
  composer.showOverlay("scenes.game_over", overlayOptions)
  
  -- to do: display overlay + if we won
  -- composer.gotoScene('scenes.intermediate_scene')
end

function Map:endTurn()
  -- remember turn is done
  self.turnActive = false
  
  -- increase move/turn counter
  self.curMoveCounter = self.curMoveCounter + 1
  
  -- check if we have all the collectibles
  -- if so, we win!
  if GLOBALS.interface:collectedEverything() then
    self:gameOver(true)
    return
  end
  
  -- check if there is still space on the board
  local stillSpace = false
  for k,v in pairs(self.mapList) do
    local hex = { x = v.x, y = v.y, z = v.z }
    if self:hexAvailable(hex) then
      stillSpace = true
      break
    end
  end
  
  -- check if we have moves left
  -- if not, it's game over
  if GLOBALS.interface:noMovesLeft() or not stillSpace then
    self:gameOver(false)
    return
  end
  
  -- if we have a level solution, keep executing it
  -- (but with some delay, so we can see it better)
  if GLOBALS.autoSolution then
    -- a hint/auto solution only executes HALF the moves
    -- (we have "greater than" because we check the fraction of moves that are LEFT, not the fraction that has already been USED)
    if GLOBALS.interface:getMovesFraction() > 0.5 or GLOBALS.hintShowsFullSolution then
      timer.performWithDelay(1000, function() self:simulateNextMove() end)
    
    -- otherwise, we stop auto solutioning
    else
      GLOBALS.autoSolution = false
    end
  end
end

function Map:setType(cell, ind)
  -- if this cell has an overlay, start animation to remove it
  -- essentially, we SWAP immediately, making the old overlay disconnected from the tile
  -- but, the transition will remember the object it works on, thus we can use it to destroy accordingly
  if cell.overlay then
    local target = { x = cell.overlay.x, y = cell.overlay.y - self.hexSize*0.3 }
    
    -- to tell the swapType function it shouldn't removeSelf() this overlay object
    cell.overlay.inTransition = true
    
    local transitionTime = self.tilePlacementDuration
    local transitionType = easing.outBounce
    if cell.isCollectible then
      cell.overlay:setSequence("success")
      cell.overlay:play()
      
      transitionTime = transitionTime * 5
      transitionType = easing.linear
    end
    
    -- create transition, remove itself once done
    transition.to(cell.overlay, { alpha = 0.0, y = target.y, time = transitionTime, transition= transitionType, onComplete = function(obj) obj:removeSelf() end })
  end
  
  self:swapType({ cell = cell, ind = ind})
end

function Map:levelIndicatorTapped(event)
  local obj = event.target
  local tb = obj.myTextBox
  
  if GLOBALS.editor and GLOBALS.editor:isActive() then
    -- toggle text box to be editable (or not)
    tb.isEditable = not tb.isEditable
    
    -- if editing is on, focus input on this box
    if tb.isEditable then
      native.setKeyboardFocus(tb)
    end
    
    -- allow input events or not, based on editability
    -- TO DO: DOES THIS EVEN DO WHAT I THINK IT DOES?!
    return tb.isEditable
  else
    -- grab list of campaign levels
    -- (need to check propert allLevels, because JSON doesn't support flat arrays)
    local campaignLevels = GLOBALS.loadTable('campaign_levels.json').allLevels
    
    -- grab id of level we clicked
    local levelID = campaignLevels[tonumber(tb.text)]
    GLOBALS.nextLevelCampaignIndex = tb.text
    GLOBALS.nextLevelToLoad = levelID
        
    -- If this is a lock, switch to displaying the ad (or action call)
    -- (otherwise, load level like normally)
    if tb.isLocked then
      local adAvailable = GLOBALS.admob.isLoaded("rewardedVideo")
      local lastLevel = (levelID == GLOBALS.lastLevelID)
      
      print("Is ad available?")
      print(adAvailable)
 
      local overlayOptions = {
          isModal = true,
          effect = "fade",
          time = 400,
          params = {
            adAvailable = adAvailable,
            lastLevel = lastLevel
          }
        }
        
        composer.showOverlay("scenes.action_call", overlayOptions)
      
      -- any way, return out of this function
      return
    end

    print("LOAD LEVEL ", tb.text, levelID)
    
    -- reload this scene (with the new level)
    self:reload()
    
    return true
  end
end

function Map:swapType(obj)
  local cell = obj.cell
  local ind = obj.ind
  
  local flatPos = (cell.hex.x + self.mapSize) + (cell.hex.y + self.mapSize) * self.totalMapSize
  
  --------
  -- if it's a level indicator, remove it from list
  -- (also remove its text box)
  --------
  if cell.isLevelIndicator then
    cell.overlay.myTextBox:removeSelf()
    self.levelIndicators[tostring(flatPos)] = nil
  end
  
  --------
  -- remove current overlay, if it (still) exists
  --------
  if cell.overlay then
    if not cell.overlay.inTransition then
      cell.overlay:removeSelf()
    end
    
    cell.overlay = nil
  end

  --------
  -- change/remove current cell if needed
  -- (if initialize hexagon returns something, that is our new cell)
  -- (if it doesn't return something, we don't need to update this)
  --------
  local oldIndex = nil
  if self.mapList[flatPos] then
    oldIndex = self.mapList[flatPos]
    self.mapList[flatPos].num = ind -- we need to do this because initialize hexagon already needs to know what it's going to be
  end
  
  -- if index is 0, we just need to remove everything and be done with it
  if ind == 0 then
    self:removeHexagon(self.mapList[flatPos])
    return
  end

  -- if there WAS an old index for this cell, it means we might have to remove something
  local updateSort = false
  if oldIndex then
    local resultCell = self:initializeHexagon(self.mapList[flatPos], cell)
    if resultCell then
      cell = resultCell
      updateSort = true
    end
  end
  
  ---------
  -- update properties
  ---------
  
  --[[
  
  == TERRAIN (4 types + "no terrain") ==
  0 = Water
  1 = Beach
  2 = Grass
  3 = Forest
  4 = Mountain
  
  == TOWERS (6 types) ==
  5 = Default
  6 = Heightened tower
  7 = Endless Tower ( = duplicator)
  8 = Capitol ( = city/town)
  9 = (Frozen Tower????)
  10 = (Frozen Tower-1????)
  
  == COLLECTIBLES (16 types) ==
  11 = Default
  12 = Guard 1
  13 = Guard 2
  14 = Guard 3
  15 = Builder
  16 = ??
  17 = ??
  18 = ??
  19 = ??
  20 = ??
  21 = ??
  22 = ??
  23 = ??
  24 = ??
  25 = ??
  26 = ??
  
  == OBSTACLES (10 types) ==
  27 = Gate 1
  28 = Gate 2
  29 = Gate 3
  30 = Enemy
  31 = Building 1 ()
  32 = ??
  33 = ??
  34 = ?? 
  35 = ??
  36 = ??
  
  == OPEN SPOTS (10 types) ==
  37 = Plateau
  38 = Duplicator/endless
  39 = Fertile spot
  40 = ??
  41 = ??
  42 = ??
  43 = ??
  44 = ??
  45 = ??
  46 = ??
  
  == MODIFIERS (9 types) ==
  47 = ??
  48 = ??
  49 = ??
  50 = ??
  51 = ??
  52 = ??
  53 = ??
  54 = ??
  55 = ??
  
  == LEVEL INDICATOR ==
  56 = Level Indicator
  
  
  --]]

  local propTable = {
    -- TERRAIN (0 omitted; that's water and has no tiles associated)
    { isPassable = true, isAllowed = true, isTerrain = true },
    { isPassable = true, isAllowed = true, isTerrain = true },
    { isPassable = true, isTerrain = true, isBreakable = true },
    { isTerrain = true },
    
    -- TOWERS
    { isPassable = true, isTower = true },
    { isPassable = true, isTower = true },
    { isPassable = true, isTower = true },
    { isPassable = false, isTower = true },
    { },
    { },
    
    -- COLLECTIBLES
    { isPassable = true, isCollectible = true, customAnchorY = 1.0 },
    { isPassable = true, isCollectible = true, guardNum = 1 },
    { isPassable = true, isCollectible = true, guardNum = 2 },
    { isPassable = true, isCollectible = true, guardNum = 3 },
    { isPassable = true, isCollectible = true, spriteName = 'overlayBuilder' },
    { isPassable = true, isCollectible = true, spriteName = 'overlayStubborn' },
    { isPassable = true, isCollectible = true, spriteName = 'overlayMover', customAnchorY = 0.75 },
    { }, 
    { },
    { },
    { },
    { },
    { },
    { }, 
    { },
    { },
    
    -- OBSTACLES
    { gateNum = 1 },
    { gateNum = 2 },
    { gateNum = 3 },
    { isEnemy = true },
    { isBuilding = true, isPassable = true },
    { isBuilding = true, isPassable = true, spriteName = 'overlayBuildingRotated' },
    { isEffect = true, isPassable = true, spriteName = 'overlayBuildingSwitch' },
    { },
    { },
    { },
    
    -- OPEN SPOTS
    { wantedTower = 6, isSpot = true, isAllowed = true, isPassable = true },
    { wantedTower = 7, isSpot = true, isAllowed = true, isPassable = true },
    { wantedTower = 8, isSpot = true, isAllowed = true, isPassable = true },
    { },
    { },
    { },
    { }, 
    { },
    { },
    { },
    
    -- MODIFIERS
    { },
    { },
    { },
    { }, 
    { },
    { },
    { },
    { },
    { },
    
    -- LEVEL INDICATOR
    { isLevelIndicator = true },
  }
  
  -- go through all properties ...
  local allProperties = { 
    'spriteName',
    'customAnchorY',
    
    'isPassable', 
    'isAllowed', 
    'isCollectible', 
    'isTower', 
    'isTerrain',
    'isEffect',
    
    'isBreakable', 
    'gateNum', 'guardNum',
    'isEnemy',
    'isSpot',
    'wantedTower',
    'isBuilding',
    'isLevelIndicator'
  }
  
  for i=1,#allProperties do
    -- get key and value from propTable
    local propKey = allProperties[i]
    local propValue = propTable[ind][propKey]
    
    -- if this value exists, copy it
    if propValue then
      cell[propKey] = propValue
    
    -- otherwise, default to false
    else
      cell[propKey] = false
    end
  end
  
  if cell.isCollectible then
    self.numCollectibles = self.numCollectibles + 1
  end

  ---------
  -- create new overlay (if needed)
  ---------
  local newOverlay = nil
  local size = self.hexSize*2.0
  if cell.isTerrain then
    -- newOverlay = display.newPolygon(self.mapGroup, cell.centerX, cell.centerY, cell.points)
    local overlays = {nil, nil, 'overlayForest', 'overlayMountain'}
    if overlays[ind] then
      --local randX, randY = (math.random()-0.5)*size*0.2, (math.random()-0.5)*size*0.2
      local randX, randY = 0,0
      
      local frameInfo = self.mainSheetInfo.frameIndex[overlays[ind]]
      newOverlay = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height )
      newOverlay:scale(size / 32, size / 32)
      self.mapGroup:insert(newOverlay)
      
      --newOverlay = display.newImageRect(self.mapGroup, overlays[ind], size, size)
      newOverlay.x = cell.centerX + randX
      newOverlay.y = cell.centerY + randY
      
      -- DEBUGGING: Checking if anchors are the cause of the weird sorting issues
      -- newOverlay.anchorY = 0.0
    end
 
  elseif cell.isTower then
    local frameInfo = self.mainSheetInfo.frameIndex["overlayPostOffice"]
    newOverlay = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height )
    newOverlay:scale(size / 32, size / 32)
    self.mapGroup:insert(newOverlay)
    
    -- newOverlay = display.newImageRect(self.mapGroup, 'assets/textures/overlayPostOffice.png', size, size)
    newOverlay.x =  cell.centerX
    newOverlay.y = cell.centerY
    
    newOverlay.ind = cell.ind
    newOverlay.myHeight = 0
    newOverlay.isTower = true
    
    print("Tower created with index " .. ind)
    
    -- heightened towers have height 1; otherwise you default to height 0
    if ind == 6 then
      newOverlay.myHeight = 1
    
    -- endless towers create endless letters :p
    elseif ind == 7 then
      newOverlay.isEndless = true
    
    -- capitols should be registered as such
    elseif ind == 8 then
      newOverlay.isCapitol = true
    end
    
  elseif cell.isCollectible then
    
    -- is it a guard? 
    local spriteName = "overlayTestPerson"
    if cell.guardNum then
      spriteName = "overlayGuard" .. cell.guardNum
    end
    
    -- if this cell has a spritename property, copy it
    if cell.spriteName then
      spriteName = cell.spriteName
    end
    
    local frameInfo = self.mainSheetInfo.frameIndex[spriteName]
    local frameInfo2 = self.mainSheetInfo.frameIndex[spriteName .. "Idle"]
    local frameInfo3 = self.mainSheetInfo.frameIndex[spriteName .. "Success"]
    
    local sequences = {
      {
          name = "idle",
          frames = { frameInfo, frameInfo2 },
          time = 500,
          loopCount = 0,
          loopDirection = "forward"
      },
      
      { 
        name = "success",
        frames = { frameInfo3, frameInfo3 },
        time = 2000,
        loopCount = 0,
        loopDirection = "forward"
      }
    }
    
    newOverlay = display.newSprite( self.mainImageSheet, sequences)
    newOverlay:setSequence("idle")
    newOverlay:play()
    
    -- with 50% chance, flip the collectible to look the other way
    local randScale = 1
    if math.random() <= 0.5 then randScale = -1 end
    
    -- because it's a sprite(sheet) now, we must scale it down
    newOverlay:scale(randScale * (size / 32), size / 32)
    self.mapGroup:insert(newOverlay)
    
    newOverlay.x = cell.centerX
    newOverlay.y = cell.centerY
    
    newOverlay.anchorY = 0.5
    if cell.customAnchorY then
      newOverlay.anchorY = cell.customAnchorY
    end

  elseif cell.gateNum then
    local frameInfo = self.mainSheetInfo.frameIndex["overlayGate" .. cell.gateNum]
    newOverlay = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height )
    
    newOverlay:scale(size / 32, size / 32)
    self.mapGroup:insert(newOverlay)
    
    newOverlay.x = cell.centerX
    newOverlay.y = cell.centerY
    
    newOverlay.anchorY = 0.9
    
  elseif cell.isEnemy then
    newOverlay = display.newCircle(self.mapGroup, cell.centerX, cell.centerY, self.hexSize*0.3)
    newOverlay.fill = {1,0,0}
  elseif cell.isSpot then
    newOverlay = display.newRect(self.mapGroup, cell.centerX, cell.centerY, self.hexSize*0.3, self.hexSize*0.3)
    
    -- plateau/heightened
    if ind == 37 then
      newOverlay.fill = {1,0,0}
    
    -- endless/duplicator
    elseif ind == 38 then
      newOverlay.fill = {0,0,1}
    
    -- fertile spot
    elseif ind == 39 then
      newOverlay.fill = {1,0,1}
    end
  elseif cell.isBuilding or cell.isEffect then
    local spriteName = 'overlayBuildingDefault'
    if cell.spriteName then
      spriteName = cell.spriteName
    end
    
    local frameInfo = self.mainSheetInfo.frameIndex[spriteName]
    newOverlay = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height )
    
    newOverlay:scale(size / 32, size / 32)
    self.mapGroup:insert(newOverlay)
    
    newOverlay.x = cell.centerX
    newOverlay.y = cell.centerY  
  elseif cell.isLevelIndicator then
    
    local userData = GLOBALS.loadTable('user_data.json', system.DocumentsDirectory)
    local indicatorText = self.levelIndicators[tostring(flatPos)]
    local size = self.hexSize*2
    
    local isCurrentLevel = (userData.lastLevel == tonumber(indicatorText))
    
    -- If it's the current level, use the bouncy flag animation, instead of the static one
    if isCurrentLevel then
      local sheetOptions =
      {
          width = 128/4,
          height = 48,
          numFrames = 4,
          
          sheetContentWidth = 128,
          sheetContentHeight = 48,
      }
      
      local sequences = {
          {
              name = "bouncyJump",
              start = 1,
              count = 4,
              time = 400,
              loopCount = 0,
              loopDirection = "forward"
          }
      }
      
      local imageSheet = graphics.newImageSheet('assets/textures/levelFlagAnimation.png', sheetOptions)
      newOverlay = display.newSprite(self.mapGroup, imageSheet, sequences)
      newOverlay:scale(size / 32, size / 32)
      
      newOverlay:setSequence("bouncyJump")
      newOverlay:play()
      
      self.mapGroup:insert(newOverlay)
    else
      
      local frameInfo = self.mainSheetInfo.frameIndex["levelFlag"]
      newOverlay = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height)
      newOverlay:scale(size / 32, size / 32)
      self.mapGroup:insert(newOverlay)
      
      -- create level flag and place it somewhat in the center (with its Y-anchor, not its own center)
      -- newOverlay = display.newImageRect(self.mapGroup, 'assets/textures/levelFlag.png', size, size)
    end
    
    newOverlay.anchorY = 0.9
    newOverlay.x = cell.centerX
    newOverlay.y = cell.centerY
    
    -- if we are EDITING the map, display the input text box
    if GLOBALS.editorActive then
      -- create text box on top of flag
      local tb = native.newTextField( newOverlay.x, newOverlay.y, size*0.5, size*0.5)

      local defaultText = '0'
      local existingValue = self.levelIndicators[tostring(flatPos)]
      if existingValue then defaultText = tostring(existingValue) end
      tb.text = defaultText
      
      tb.align = 'center'
      tb.inputType = "number"
      self.mapGroup:insert(tb)
      
      -- ... and link it with the overlay
      newOverlay.myTextBox = tb
    
    -- if we're NOT editing the map ...
    else
      -- simply display the number of the level indicator on the flag
      -- (why the x + 1 and y + 4? Well, these are just some offsets/inaccuracies in the flag sprite, and we need to offset these to center the text)
      local textOptions = {
          parent = self.mapGroup,
          x = newOverlay.x + 1,
          y = newOverlay.y - 0.5*newOverlay.height*newOverlay.yScale - 16*0.5 + 4, 
          text = indicatorText,
          font = GLOBALS.pixelFont,
          fontSize = 16
      } 
      
      if isCurrentLevel then
        textOptions.y = newOverlay.y - 0.5*32*newOverlay.yScale 
      end
      
      local offset = 1.5
      
      textOptions.y = textOptions.y + offset
      
      local textShadow = display.newText(textOptions)
      textShadow:setFillColor(54/255.0, 31/255.0, 27/255.0)
      textShadow.isShadow = true
      textShadow.isText = true
      textShadow.offset = offset
      
      textOptions.y = textOptions.y - offset
      local tb = display.newText(textOptions)
      tb.isText = true
      tb:setFillColor(1,1,1)
      
      newOverlay.myTextBox = tb
      
      -- add BOUNCING animation to text, if this is the current level
      if isCurrentLevel then
        local spriteListener = function(event)
          local obj = event.target
          obj.myAnimation:setPosition(obj.frame*100)
          obj.myAnimation2:setPosition(obj.frame*100)
        end
        
        newOverlay:addEventListener( "sprite", spriteListener )
        
        local timelineParams = {
         tweens = {
              { startTime=0, tween={ tb, { y = tb.y }, { time=100 } } },
              { startTime=100, tween={ tb, { y = tb.y + 5 }, { time=100 } } },
              { startTime=200, tween={ tb, { y= tb.y }, {time = 100}} },
              { startTime=300, tween={ tb, { y= tb.y - 15 }, {time = 100}} },
          },
          
          autoPlay = false,
        }
        
        newOverlay.myAnimation = animation.newTimeline( timelineParams )
        
        timelineParams.tweens = 
        {
              { startTime=0, tween={ textShadow, { y = textShadow.y }, { time=100 } } },
              { startTime=100, tween={ textShadow, { y = textShadow.y + 5 }, { time=100 } } },
              { startTime=200, tween={ textShadow, { y= textShadow.y }, {time = 100}} },
              { startTime=300, tween={ textShadow, { y= textShadow.y - 15 }, {time = 100}} },
          }
        
        
        newOverlay.myAnimation2 = animation.newTimeline( timelineParams )
      end
      
      -- check if a level is connected
      -- TO DO: Perhaps load data only once and save it (in GLOBALS), as this is an expensive operation
      local levelData = GLOBALS.loadTable('level_data.json')      
      local campaignLevels = GLOBALS.loadTable('campaign_levels.json').allLevels
       
      -- add particles to CURRENT (last) LEVEL
      if isCurrentLevel then 
        local emitterParams = require("particles.levelIndicator")
        local emitter = display.newEmitter( emitterParams )
        self.mapGroup:insert(emitter)
        
        emitter.x = newOverlay.x
        emitter.y = newOverlay.y - 0.45*newOverlay.height
      end
      
      -- use campaign index to get level string name => check string name in full list of levels
      -- if not available ...
      local levelID = campaignLevels[tonumber(tb.text)]
      if not levelData[levelID] or (levelID == GLOBALS.lastLevelID) then
        -- hide text
        tb.isVisible = false
        textShadow.isVisible = false
        
        -- show lock symbol
        local lockSymbol = display.newImageRect(self.mapGroup, 'assets/textures/levelFlagBridge.png', size, size)
        lockSymbol.x = newOverlay.x
        lockSymbol.y = newOverlay.y
        lockSymbol.anchorY = newOverlay.anchorY
        lockSymbol.isText = true -- trick to make it appear in front
        
        tb.isLocked = true
      end
    end
    
    -- listen for tap events
    newOverlay:addEventListener("tap", function(event) self:levelIndicatorTapped(event) end)
    
    -- DEBUGGING
    --newOverlay:removeSelf()
    --newOverlay = nil
  end

  if newOverlay then
    cell.overlay = newOverlay
    cell.overlay.hex = cell.hex
    
    local target = { x = newOverlay.x, y = newOverlay.y }
    local start = { x = newOverlay.x, y = newOverlay.y - self.hexSize*0.5 }
    
    newOverlay.y = start.y
    newOverlay.alpha = 0.0
 
    transition.to(newOverlay, { y = target.y, alpha = 1.0, time = self.tileRemovalDuration, transition=easing.outBounce, onComplete=function(obj) self:finalizeType(obj) end })
  end
  
  -- also update values in the list
  -- (although we won't be accessing that often)
  -- (and if it doesn't exist yet, insert an entry!)
  if not self.mapList[flatPos] then
    self.mapList[flatPos] = { x = cell.hex.x, y = cell.hex.y, z = cell.hex.z, num = ind }
  else
    self.mapList[flatPos].num = ind
  end
  
  -- if it's a level indicator, save it separately
  if cell.isLevelIndicator then
    self.levelIndicators[tostring(flatPos)] = cell
  end
  
  -- if we (for whatever reason) need to update the sorting, do so
  if updateSort then
    self:performYSort()
  end
  
  -- finally, return any new object we created, for use by the function that called us
  return cell.overlay
end

function Map:finalizeType(obj)
  if obj.isTower then
    self:executeTower(obj)
  end
end

function math.round(x)
  if x%2 ~= 0.5 then return math.floor(x+0.5) end
  return x-0.5
end

function Map:destroy()
  self.map = nil
  self.mapList = nil
  self.towers = nil
  
  self.mapGroup:removeSelf()
  self.mapGroup = nil
end

function Map:simulateNextMove()
  local solutionMove = self.levelData.solution[self.curMoveCounter]
  local hex = { x = solutionMove[1], y = solutionMove[2], z = solutionMove[3] }
  self:placeTower(hex)
end

--[[
function Map:simulateMove()
  -- look for a free spot to place a tower
  -- but do so in a fixed order, so we try something different every time
  local curMoveIndex = GLOBALS.sim.moveIndex[self.curMoveCounter]
  local hex = nil
  local tryAgain = false
  
  -- keep looking until we find a possible move
  while not self:hexAvailable(hex) do
    local spot = self.mapList[curMoveIndex]
    hex = { x = spot.x, y = spot.y, z = spot.z }
    
    curMoveIndex = curMoveIndex + 1
    
    -- if we've exhausted the full set for this move ...
    if curMoveIndex > #self.mapList then
      tryAgain = true
      -- break out of loop
      break
    end
  end
  
  -- update move index to this value
  -- this way, we can "skip" large stretches of impossible/identical moves
  GLOBALS.sim.moveIndex[self.curMoveCounter] = (curMoveIndex - 1)
  
  if tryAgain then
    GLOBALS.sim:tryAgain()
    return
  end

  -- place tower there
  self:placeTower(hex)
  
  -- register move in simulation
  GLOBALS.sim:registerMove(hex)
end
--]]

function Map:flatToHex(flatPos)
  local x = flatPos % self.totalMapSize
  local y = (flatPos - x) / self.totalMapSize
  local z = 3*self.mapSize - x - y
  
  return x - self.mapSize, y - self.mapSize, z - self.mapSize
end

function Map:hexToFlat(hex)
  return (hex.x + self.mapSize) + (hex.y + self.mapSize)*self.totalMapSize
end

-- This calculates the CENTER of a hex in pixel coordinates, 
-- given (x,y,z) hex from the grid
function Map:hexToPixel(hex)
  return { x = self.hexSize * (3/2 * hex.x), y = self.hexSize * (math.sqrt(3)/2 * hex.x  +  math.sqrt(3) * hex.z) }
end

function Map:pixelToHex(x, y)
  -- translate against mapGroup translation (camera panning)
  -- (this already depends on scale, so we need to use this BEFORE adjusting for scale, rather than after)
  x = x - self.mapGroup.x
  y = y - self.mapGroup.y
  
  -- undo any scaling of the mapGroup (camera zooming)
  x = x / self.mapGroup.xScale
  y = y / self.mapGroup.yScale
  
  -- translate to 0,0 origin
  x = x - self.mapCenter.x
  y = y - self.mapCenter.y
  
  -- reconstruct hex (X,Y,Z) from pixels
  local hexX = x * 2 / (3*self.hexSize)
  local hexZ = y / (math.sqrt(3)*self.hexSize) - x / (3*self.hexSize)
  local hexY = -hexX - hexZ
  
  -- round these, return
  return { x = math.round(hexX), y = math.round(hexY), z = math.round(hexZ) }
end

function Map:sendLine(t1, t2)
  -- if move direction is reversed, make the start the end and vice versa
  if self.letterMoveDir == -1 then
    local tempT = t1
    t1 = t2
    t2 = tempT
  end
  
  -------
  -- step between the two towers (to find out how far we can travel)
  -------
  local h1 = t1.hex
  local h2 = t2.hex
  
  -- this difference automatically gives the number of steps
  local steps = (math.abs(h2.x - h1.x) + math.abs(h2.y - h1.y) + math.abs(h2.z - h1.z))/2
  
  -- vector is "how much to move to next hex every timestep"
  local vec = { x = (h2.x - h1.x)/steps, y = (h2.y - h1.y)/steps, z = (h2.z - h1.z)/steps }
  
  -- TO DO: Is it necessary to calculate this beforehand? It's only needed for nice and correct line drawings between towers!
  local validSteps = 0
  for i=1,steps do
    local newHex = { x = h1.x + vec.x * i, y = h1.y + vec.y * i, z = h1.z + vec.z * i }
    local nextCell = self.map[newHex.x][newHex.y][newHex.z]

    -- if this letter has height 0
    if t1.myHeight <= 0 then
      -- if this square is not passable ...
      if not nextCell or not nextCell.isPassable then
        -- we are stuck
        break
      end
    end
    
    -- otherwise, remember we made another valid step
    validSteps = validSteps + 1
  end
  
  -- if we're at least allowed one step
  -- we must send a letter/line as far as we can
  if validSteps > 0 then
    local letter = {}

    local validEndPos = { x = t1.x + (validSteps/steps)*(t2.x - t1.x), y = t1.y + (validSteps/steps)*(t2.y - t1.y) }
  
    -- create line between two towers
    local line = display.newLine(self.mapGroup, t1.x, t1.y, validEndPos.x, validEndPos.y)
    line:setStrokeColor(1, 0, 0)
    line.strokeWidth = 2
    line.alpha = 0.3
    
    -- "send a letter" (transition) between towers
    local letterSizeMultiplier = 2
    letter = display.newImageRect(self.mapGroup, 'assets/textures/singleLetter.png', 5*letterSizeMultiplier, 4*letterSizeMultiplier)
    letter.x = t1.x
    letter.y = t1.y
    --letter.fill = {1,1,1}
    
    -- record every property we might need on the letter
    -- (number of steps, start/end tower, direction vector, letter height)
    letter.curHex = { x = h1.x, y = h1.y, z = h1.z }
    letter.hexVec = vec
    letter.pixelVec = self:hexToPixel(vec)
    letter.t1 = t1
    letter.t2 = t2
    letter.myHeight = t1.myHeight
    letter.isEndless = t1.isEndless
    
    letter.buildingsHit = {}

    -- remember we send out this letter
    self.lettersSendOut = self.lettersSendOut + 1
    
    -- play audio (with random delay, so multiple letters don't create one HUGE swoosh sound)
    local function playSwooshAudio( event )
      local randSwoosh = GLOBALS.audio.swoosh[math.random(#GLOBALS.audio.swoosh)]
      audio.play(randSwoosh)
    end
    
    local randDelay = math.random()*0.5
    timer.performWithDelay(randDelay, playSwooshAudio)
    
    -- finally, start moving it
    self:moveLetter(letter)
  end
end

function Map:sendCampaignLetter()
  -- create letter
  local letterSizeMultiplier = 2*2
  local letter = display.newImageRect(self.mapGroup, 'assets/textures/singleLetter.png', 5*letterSizeMultiplier, 4*letterSizeMultiplier)
  
  local cX, cY = display.contentCenterX, display.contentCenterY
  
  -- place at start
  local pos1 = self:hexToPixel(GLOBALS.prevLevelHex)
  letter.x = pos1.x + cX
  letter.y = pos1.y + cY
  
  -- animate it towards end
  -- (and bounce there, then delete once finished)
  local pos2 = self:hexToPixel(GLOBALS.curLevelHex)
  transition.to(letter, { x = pos2.x + cX, y = pos2.y + cY, time = 1000 })
  transition.to(letter, { xScale = 0.01, yScale = 0.01, delay = 1000, time = 1000, transition = easing.inElastic, onComplete = function(obj) obj:removeSelf() end })
end

function Map:moveLetter(obj)
  -------
  -- Check for any effects on the NEXT hexagon
  -------
  local doneMoving = false
  
  -- get next hexagon (in X,Y,Z coordinates)
  local nextHex = { 
    x = obj.curHex.x + obj.hexVec.x,
    y = obj.curHex.y + obj.hexVec.y,
    z = obj.curHex.z + obj.hexVec.z,
  }
  
  -- Check if this hexagon even exists
  -- (if it's in the map list, which uses 0-indexed flat positions, it should exist)
  local flatPos = self:hexToFlat(nextHex)
  
  -- OLD CHECK: if not self.mapList[flatPos] or self.mapList[flatPos].num <= 0
  if not self:hexExists(nextHex) then
    print("LETTER DONE MOVING BECAUSE HEXAGON DOESN'T EXIST")
    self:registerLetterDone(obj)
    return
  end

  -- If it exists, then we can grab the corresponding cell!
  local nextCell = self.map[nextHex.x][nextHex.y][nextHex.z]
  
  -- is this spot impassable?
  if obj.myHeight == 0 then
    if not nextCell.isPassable then
      print("LETTER DONE MOVING BECAUSE NEXT CELL IMPASSABLE")
      doneMoving = true
    end
  end
  
  -- start transition
  -- (but only if we're not done moving yet)
  if not doneMoving then
    -- if we passed all checks, save the new hex as the current hex
    obj.curHex = nextHex
    
    -- calculate next position (in PIXELS)
    local nextPos = { x = obj.x + obj.pixelVec.x, y = obj.y + obj.pixelVec.y }
    
    transition.to(obj, { x = nextPos.x, y = nextPos.y, time = 200, onComplete = function(obj) self:letterFinished(obj) end })
  else
    self:registerLetterDone(obj)
  end
end

function Map:letterFinished(obj)
  -------
  -- Check for any effects on the CURRENT hexagon
  -------
  local curHex = obj.curHex
  local flatPos = self:hexToFlat(curHex)
  local cell = self.map[curHex.x][curHex.y][curHex.z]
  local doneMoving = nil
  
  -- if the cell doesn't even exist
  -- (it could have been removed in the meantime, e.g. with a mover)
  -- just finish the letter and be done with it
  if not cell then
    self:registerLetterDone(obj)
    return
  end
    
  -- is this an enemy? 
  -- Instant loss!
  if cell.isEnemy then
    self:gameOver(false)
  end
  
  if cell.spriteName == "overlayGate1" or cell.spriteName == "overlayGate2" or cell.spriteName == "overlayGate3" then
    audio.play(GLOBALS.audio.door)
  end
  
  -- is this a collectible?
  if cell.isCollectible then
    -- is this a guard?
    if cell.guardNum then
      print("Open the gates!")
      
      -- then open its gate!
      if self.gates[cell.guardNum] then
        self:setType( self.gates[cell.guardNum], 2 )
      else
        print("Oh no! There's no gate to open!")
      end
    end
    
    -- then update the collectibles counter
    GLOBALS.interface:updateCollectibles(1)
    
    -- and reset to empty grass cell
    -- (some collectibles reset to something else, that's why we go via a targetCell
    local targetCell = 2
    if cell.spriteName == 'overlayBuilder' then
      audio.play(GLOBALS.audio.builder)
      targetCell = 31 -- builder resets to default building
    elseif cell.spriteName == 'overlayStubborn' then
      audio.play(GLOBALS.audio.brickfalling)
      targetCell = 11 -- stubborn people go from BUILDING => default COLLECTIBLE
      GLOBALS.interface:updateCollectibles(-1)
    elseif cell.spriteName == 'overlayMover' then
      audio.play(GLOBALS.audio.mover)
      targetCell = 0
    end
    
    self:setType(cell, targetCell)
    
    -- and stop moving
    doneMoving = true
    
    print("DONE MOVING BECAUSE OF COLLECTIBLE")
  end
  
  -- is this a breakable object (such as a forest)?
  -- If so, stop moving, but only after removing this thing
  if cell.isBreakable and not doneMoving then
    self:setType(cell, 2)
    doneMoving = true
    
    if cell.spriteName == 'overlayForest' then
      audio.play(GLOBALS.audio.forest)
    end
    
    print("DONE MOVING BECAUSE OF BREAKABLE")
  end
  
  if cell.isEffect then
    if cell.spriteName == 'overlayBuildingSwitch' then
      -- reverse letter direction
      self.letterMoveDir = self.letterMoveDir * -1
      
      -- update icon
      GLOBALS.interface:updateIcon('letterSwitch', (self.letterMoveDir == -1))
      
      -- play audio
      audio.play(GLOBALS.audio.brickfalling)
      audio.play(GLOBALS.audio.dirswitch)
      
      -- stop moving
      doneMoving = true
    end
  end
  
  if cell.isBuilding and not doneMoving then
    -- check if we already hit this building; if so, stop here
    if GLOBALS:tableHasValue( obj.buildingsHit, flatPos ) then
      doneMoving = true
    else
      -- deflect letter
      -- invert hexagon vector AND pixel vector
      local newVec = { x = -obj.hexVec.x, y = -obj.hexVec.y, z = -obj.hexVec.z }
      local newPixelVec = { x = -obj.pixelVec.x, y = -obj.pixelVec.y }

      -- if it's a rotated building, also rotate these new vectors
      if cell.spriteName == 'overlayBuildingRotated' then
        -- push z to the front
        newVec = { x = -newVec.z, y = -newVec.x, z = -newVec.y }

        -- rotate the pixel vector
        local angle = (1/3)*math.pi
        newPixelVec.x = math.cos(angle) * -obj.pixelVec.x - math.sin(angle) * -obj.pixelVec.y
        newPixelVec.y = math.sin(angle) * -obj.pixelVec.x + math.cos(angle) * -obj.pixelVec.y
        
        -- play audio
        audio.play(GLOBALS.audio.brickfalling)
      end
      
      obj.hexVec = newVec
      obj.pixelVec = newPixelVec
      
      -- save that we hit this building
      table.insert(obj.buildingsHit, flatPos)
      
      -- remember to keep moving
      doneMoving = false
    end
  end
  
  --------
  -- Now check if the letter is done moving, or should continue doing so
  --------
  
  -- if we haven't yet received a trigger to stop, check if we're at the target tower
  if doneMoving == nil then
    doneMoving = (cell.ind == obj.t2.ind)
    if doneMoving then
      print("DONE MOVING BECAUSE REACHED TARGET")
    end
  end
  
  -- if we're an endless letter, none of that matters: we won't stop anyway
  -- (only obstacles + non-existent tiles (such as water) can stop us)
  if obj.isEndless then
    doneMoving = false
  end
  
  -- if this was the final step of the letter movement ...
  if doneMoving then
    -- stop moving (just don't plan the next transition)
    self:registerLetterDone(obj)
  else 
    -- plan next transition
    self:moveLetter(obj)
  end
end

function Map:removeLetter(obj)
  obj:removeSelf()
end

function Map:registerLetterDone(obj) 
  --------
  -- Check for capitols (cities/towns)
  --------
  local ch = obj.curHex
  local finalCell = self.map[ch.x][ch.y][ch.z]
  
  -- if final cell (still) EXISTS, and it is a tower, and it's even a capitol ...
  if finalCell and finalCell.isTower and finalCell.overlay.isCapitol then
    -- move back one square
    local prevHex = { 
      x = ch.x - obj.hexVec.x,
      y = ch.y - obj.hexVec.y,
      z = ch.z - obj.hexVec.z
    }
    
    -- while the current hexagon is unavailable ...
    local numRotations = 0
    local validPlacement = true
    while not self:hexAvailable(prevHex) do
      -- rotate the hexagon (center = current hexagon, hexagon to rotate = previous hexagon)
      -- (it rotates 1/6 by default)
      prevHex = self:rotateHexagon(ch, prevHex) 
      
      -- increment rotations
      numRotations = numRotations + 1
      
      -- if rotated 6 times, break
      -- there is no place for this building
      if numRotations >= 6 then
        validPlacement = false
        break
      end
    end
    
    print(ch.x, ch.y, ch.z)
    print(prevHex.x, prevHex.y, prevHex.z)
    print("Trying to place a building")
    
    -- found something?
    -- (if nothing found, we just do nothing)
    if validPlacement then
      print("Found place for a building!")
      
      -- place building there!
      local cell = self.map[prevHex.x][prevHex.y][prevHex.z]
      self:setType(cell, 31)
    end
  end
  
  -- make letter vanish + check if all letters have arrived
  local completeFunction = function(obj) 
    self:removeLetter(obj) 

    -- record that this letter has arrived
    self.lettersArrived = self.lettersArrived + 1
    
    -- if all letters have arrived, end this turn
    if self.lettersArrived >= self.lettersSendOut then
      self:endTurn()
    end
  end
  
  transition.to(obj, { alpha = 0, onComplete = completeFunction, time = 750 })
  
  -- play blocking audio effect
  audio.play(GLOBALS.audio.letterblock)

end

function Map:rotateHexagon(center, hex)
  -- get relative vector (so we rotate around 0)
  local relativeVec = {
    hex.x - center.x,
    hex.y - center.y,
    hex.z - center.z
  }
  
  local newVec = {}
  
  -- rotate them clockwise
  -- (which means shifting them to the right)
  for i=1,3 do
    local previousIndex = (i-1)
    if previousIndex < 1 then previousIndex = 3 end
    newVec[i] = -relativeVec[previousIndex]
  end
  
  return {
    x = center.x + newVec[1],
    y = center.y + newVec[2],
    z = center.z + newVec[3]
  }
end
    

function Map:placeTower(hex)
  -- find corresponding grid cell
  local obj = self.map[hex.x][hex.y][hex.z]
  local towerInd = 5
  
  -- check current value
  -- if this hexagon wants a specific tower, use that
  if obj.wantedTower then
    towerInd = obj.wantedTower
  end
  
  -- PLACE THE TOWER
  local newTower = self:setType(obj, towerInd)
  
  -- Update Y-sorting
  self:performYSort()
  
  -- play sound effect
  audio.play(GLOBALS.audio.postoffice)
  
  -- We're now in an active turn!
  self.turnActive = true
  
  -- properties to keep track of all the letters
  -- (so we know when the turn is done)
  self.lettersArrived = 0
  self.lettersSendOut = 0
end

function Map:executeTower(newTower)
  local hex = newTower.hex
  
  -- send lines to all other towers which share a coordinate
  -- IDEA: In some levels, starting tower/location is fixed??
  for t=1,#self.towers do
    local oldTower = self.towers[t]

    if oldTower.hex.x == hex.x or
       oldTower.hex.y == hex.y or
       oldTower.hex.z == hex.z then
      self:sendLine(oldTower, newTower)
    end
  end
  
  -- now update tower list
  -- (not before, because then you send a letter to yourself :p)
  table.insert(self.towers, newTower)
  
  -- deduct a move
  GLOBALS.interface:updateMoves(-1)
  
  -- if there are no towers that need a letter, the turn immediately ends
  if self.lettersSendOut <= 0 then
    self:endTurn()
  end

end

function Map:removeHexagon(hex)
  -- remove actual (visual) sprite (+ anything attached, such as overlay)
  local cell = self.map[hex.x][hex.y][hex.z]
  
  -- if cell doesn't exist anyway, return immediately
  if not cell or not cell.removeSelf then return end
  
  local levelIndicator = cell.isLevelIndicator
  
  if cell.overlay then cell.overlay:removeSelf() end
  if levelIndicator then cell.overlay.myTextBox:removeSelf() end
  cell:removeSelf()
  
  -- remove reference in map
  self.map[hex.x][hex.y][hex.z] = nil
  
  -- remove reference in mapList
  local flatPos = (cell.hex.x + self.mapSize) + (cell.hex.y + self.mapSize) * self.totalMapSize
  self.mapList[flatPos] = nil
  
  if levelIndicator then self.levelIndicators[tostring(flatPos)] = nil end
end

function Map:updateHexagon(hex, ind)
  -- if this hexagon isn't even part of the world, we can't update anything
  if not self:hexExists(hex) then
    return 
  end
  
  -- if index is 0 (or lower), we simply remove whatever is in this location
  if ind <= 0 then
    self:removeHexagon(hex)
    return
  end
  
  local cell = self.map[hex.x][hex.y][hex.z]
  hex.num = ind

  -- if no hexagon exists here yet, create it!
  -- (this function automatically swaps type)
  if not cell or not cell.hex then
    cell = self:initializeHexagon(hex)
  else
    -- now swap this cell to the new (given) index
    self:swapType({ cell = cell, ind = ind })
  end
  
  -- now update the Y-sorting
  self:performYSort()
end

function Map:clickHexagon(x, y)
  -- if a turn is active, we can't do anything
  if self.turnActive then return end
  
  -- or if the tutorial is active and we DON'T have a forcedMove
  if not GLOBALS.tutorial.isDone and not self.forcedMove then return end
  
  -- get the hex at this location
  local hex = self:pixelToHex(x, y)
  
  -- check if the editor is active
  if GLOBALS.editor and GLOBALS.editor:isActive() then
    -- if so, update current hex to reflect the chosen hexagon type
    self:updateHexagon(hex, GLOBALS.editor:getSelectedType() )
    
    -- return out of this function (don't execute default game code, such as placing a tower)
    return
  end
    
  -- if we're at the campaign screen, also don't allow placing towers
  if GLOBALS.campaignScreen then return end

  -- if that hex is not available (for whatever reason), stop here
  if not self:hexAvailable(hex) then return false end
  
  -- if a forced move is active, only pass this check if the move matches!
  if self.forcedMove then
    local m = self.forcedMove
    if m.x ~= hex.x or m.y ~= hex.y or m.z ~= hex.z then
      return false
    end
    
    -- reset the forced move, as we've now used it
    self.forcedMove = nil 
    
    -- update the tutorial
    -- (TO DO: Might want to do this later, once turn is actually over??)
    GLOBALS.tutorial:loadNext()
  end
  
  -- if all checks are passed, place the tower
  self:placeTower(hex)
end

function Map:hexExists(hex)
  if math.abs(hex.x) > self.mapSize or 
     math.abs(hex.y) > self.mapSize or
     math.abs(hex.z) > self.mapSize then
       return false
  end
  
  if (hex.x + hex.y + hex.z) ~= 0 then
    return false
  end
  
  return true
end

function Map:hexAvailable(hex)
  -- if hex is a nil value, return immediately
  if not hex then return false end

  -- check if this hex even exists
  -- if not, return immediately
  if math.abs(hex.x) > self.mapSize or 
     math.abs(hex.y) > self.mapSize or
     math.abs(hex.z) > self.mapSize then
       return false
  end

  local cell = self.map[hex.x][hex.y][hex.z]
  if not cell then return false end

  -- check if it's empty (as in: we can place something here)
  -- if not, return immediately
  if not cell.isAllowed then
    return false
  end
  
  -- if all checks have passed, return true => the hex is available!
  return true
end

function Map:panCamera(dx, dy)
  self.mapGroup:translate(dx, dy)
end

function Map:initializeHexagon(hex, currentCell)
  currentCell = currentCell or nil
  
  -- determine center and radius
  local c = self:hexToPixel(hex)
  
  local spriteName = 'tileGrass'
  if hex.num == 1 then
    spriteName = 'tileBeach'
  elseif hex.num == 4 then
    spriteName = 'tileMountain'
  elseif hex.num == 17 then
    spriteName = 'tileWater'
  end
  
  -- if the current cell is set, check if the new value is DIFFERENT
  if currentCell then
    -- if so, remove this current cell, and allow creating a new one
    if currentCell.mySpriteName ~= spriteName then
      currentCell:removeSelf()
    else
      return nil
    end
  end
  
  -- create sprite from image!
  local frameInfo = self.mainSheetInfo.frameIndex[spriteName]
  local hexSprite = display.newImageRect( self.mainImageSheet, frameInfo, self.mainSheetInfo.sheet.frames[frameInfo].width, self.mainSheetInfo.sheet.frames[frameInfo].height )
  hexSprite:scale(self.hexSize * 2 / 32, self.hexSize * 2 / 32)
  
  hexSprite.x = self.mapCenter.x + c.x
  hexSprite.y = self.mapCenter.y + c.y

  self.mapGroup:insert(hexSprite)
  
  -- remember some properties for quick access 
  -- (so we don't need to re-calculate them any time later)
  hexSprite.centerX = self.mapCenter.x + c.x
  hexSprite.centerY = self.mapCenter.y + c.y
  hexSprite.points = true
  hexSprite.hex = hex
  hexSprite.mySpriteName = spriteName
  
  -- assign a unique hexagon ID for quick (and distinct) reference
  self.curHexagonID = self.curHexagonID + 1
  hexSprite.ind = self.curHexagonID
  
  -- set correct hex type (+visuals)
  -- (if there's no current cell set, we need to do this ourselves)
  -- (otherwise, the function that's calling us is responsible for that)
  if not currentCell then
    self:setType(hexSprite, hex.num)
  end
  
  -- is this a gate? Then save it
  if hexSprite.gateNum then
    self.gates[hexSprite.gateNum] = hexSprite
  end
  
  -- set the right map location to the sprite
  self.map[hex.x][hex.y][hex.z] = hexSprite
  
  -- return the cell we just created (for whoever calls us might want to do something with it)
  return hexSprite
end

function Map:growWorld()
  -- remember old size (for copying later)
  local oldMapSize = self.mapSize
  local oldTotalMapSize = self.totalMapSize
  
  -- increase map size variables
  self.mapSize = self.mapSize + 1
  self.totalMapSize = self.totalMapSize + 2
  
  -- create new variables (both GRID and mapList)
  local newMap = {}
  local newMapList = {}
  local newIndicators = {}
  for x=-self.mapSize,self.mapSize do
    newMap[x] = {}
    for y=-self.mapSize,self.mapSize do
      newMap[x][y] = {}
      for z=-self.mapSize,self.mapSize do
        -- if this one is within the grid ...
        if (x + y + z) == 0 then
          -- calculate both old and new position
          local oldFlatPos = (x + oldMapSize) + (y + oldMapSize) * oldTotalMapSize
          local newFlatPos = (x + self.mapSize) + (y + self.mapSize) * self.totalMapSize
         
          -- check if this cell already exists; if so, copy old info
          if self.mapList[oldFlatPos] and (math.abs(x) ~= self.mapSize and math.abs(y) ~= self.mapSize and math.abs(z) ~= self.mapSize) then
              newMap[x][y][z] = self.map[x][y][z]
              newMapList[newFlatPos] = self.mapList[oldFlatPos]
              
              if self.levelIndicators[tostring(oldFlatPos)] then
                newIndicators[tostring(newFlatPos)] = self.levelIndicators[tostring(oldFlatPos)]
              end
            
          -- otherwise, initialize with new variables
          else          
            -- initialize an empty object;
            newMap[x][y][z] = {} 
            
            -- NOT NECESSARY THIS
            --  remember it in the map list so we can place a random element here later
            -- self.mapList[flatPos] = { x = x, y = y, z = z, num = 0 }
          end
        end
      end
    end
  end
  
  -- now swap old variables for new ones!
  -- TO DO: Might need to update links between gates? Or are they automatically copied over?
  -- TO DO: Might need to update num collectible counter if you place a new collectible (in edit mode)
  
  self.map = newMap
  self.mapList = newMapList
  self.levelIndicators = newIndicators
  
  -- update some editor properties
  if GLOBALS.editor then
    GLOBALS.editor:updateBoundsHexagon()
  end
end

function Map:buildLevelArray()
  local maxSize = self.totalMapSize * self.totalMapSize
  local levelArray = {}
  local levelIndicatorArray = {}
  
  -- simply convert the level to a 1D array
  -- where water/empty spots are 0, and the rest has the right associated index
  -- REMEMBER: We shifted mapList to start at 0, as that is easier for flatPos calculations
  for i=0,(maxSize-1) do
    local actualIndex = (i+1)
    if self.mapList[i] then
      levelArray[actualIndex] = self.mapList[i].num
    else
      levelArray[actualIndex] = 0
    end
  end
  
  return levelArray
end

function Map:performYSort()
  local temp = {}
	local objs = self.mapGroup.numChildren
  
  -- copy all objects from display group to new (temporary) array
	for i = 1, objs do
		temp[ i ] = self.mapGroup[ i ]
	end
  
  -- remove all objects from current display group
	for i = self.mapGroup.numChildren, 1, -1 do
		self[ i ] = nil
	end
  
  -- now sort the temporary array
  -- (we want to sort on Y-anchors => the place where a certain object would hit the ground
  local function compare( a, b )
    local aY, bY = a.y, b.y
    
    -- if the object is a terrain tile
    if a.points then aY = aY - (0.5*a.height*a.yScale) end
    if b.points then bY = bY - (0.5*b.height*b.yScale) end

    -- if the object is a piece of text, then we must make sure to pull it in front of our own tile
    if a.isText then 
      aY = aY + self.hexSize 
      
      if a.isShadow then
        aY = aY - (a.offset+1)
      end
    end
    
    if b.isText then 
      bY = bY + self.hexSize 
    
      if b.isShadow then
        bY = bY - (b.offset+1)
      end
    end
    
    -- make sure lines are also on top
    if a.campaignPath then aY = a.lowerY end
    if b.campaignPath then bY = b.lowerY end
    
    return aY < bY 
  end
	table.sort( temp, compare )

	-- Reinsert all objects into the group, now in order
	for i = 1, #temp, 1 do
		self.mapGroup:insert( temp[ i ] )
	end
end

function Map:getSaveData()
  -- grab our save data
  local saveData = GLOBALS.loadTable('user_data.json', system.DocumentsDirectory)
  
  -- if it doesn't exist, create one (start at level 1) and save it
  if not saveData then
    saveData = { lastLevel = 1 }
    self:setSaveData(saveData)
  end
  
  -- return save data
  return saveData
end

function Map:setSaveData(t)
  GLOBALS.saveTable(t, 'user_data.json', system.DocumentsDirectory)
end

----------
-- CONSTRUCTOR FUNCTION
----------
function Map:new(scene, levelData, ind)
  self.sceneGroup = scene.view
  self.levelData = levelData
  self.ind = ind
  self.nextLevelCampaignIndex = GLOBALS.nextLevelCampaignIndex
  
  ------------
  -- create the background
  ------------
  --self.bgColor = {60/255.0, 90/255.0, 90/255.0} -- water color
  
  -- WATER COLORS:
  -- LIGHT: 41,192,246
  -- MEDIUM: 24,174,228
  -- DARK: 11,88,158
  
  
  self.bgColor = {11/255.0, 88/255.0, 158/255.0}
  self.emptyHexColor = {161 / 255.0, 214/255.0, 110/255.0} -- grass color
  
  
  local bg = display.newRect(self.sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  bg.fill = self.bgColor
  
  ------------
  -- create the map display group
  ------------
  self.mapGroup = display.newGroup()
  self.sceneGroup:insert(self.mapGroup)
  
  ------------
  -- some properties/parameters I'll need often
  ------------
  self.curMoveCounter = 1
  self.tilePlacementDuration = 200
  self.tileRemovalDuration = 200
  
  self.letterMoveDir = 1
  
  ------------
  -- initialize many important parameters
  ------------
  self.towers = {}
  self.hexSize = 30
  self.mapCenter = { x = display.contentCenterX, y = display.contentCenterY }
  self.gates = {}
  self.forcedMove = nil
  
  self.curHexagonID = 0
  
  -----------
  -- Load spritesheet(s) I'll use for EVERYTHING
  -----------
  local spritesheetTable = GLOBALS.loadTable("assets/spritesheets/texture.json") 
  self.mainSheetInfo = GLOBALS:convertImageSheet(spritesheetTable)
  
  --[[
  DEBUGGING IMAGE SHEET
  for k,v in pairs(self.mainSheetInfo.sheet.frames) do
    for k2,v2 in pairs(v) do
      print(k2, v2)
    end
  end
  --]]
  
  -- OLD: With the Texture Packer PRO
  -- self.mainSheetInfo = require("assets.spritesheets.spritesheetData-0")
  
  
  self.mainImageSheet = graphics.newImageSheet( "assets/spritesheets/texture.png", self.mainSheetInfo.sheet )

  ------------
  -- create the map
  ------------
  -- NOTE 1:
  -- we represent these hexagonals using CUBE coordinates (x,y,z)
  -- to convert them to 2D, they must satisfy one condition: x + y + z = 0
  
  -- NOTE 2:
  -- We track the map using two different methods: grid (3d array) and list (with all tiles)
  -- Which one we use depends on what's faster for that thing
  
  self.mapSize = 2 -- map bounds
  if levelData then
    self.mapSize = levelData.mapSize
  end
  local totalSize = self.mapSize*2 + 1
  self.totalMapSize = totalSize
  
  self.map = {}
  self.mapList = {}
  for x=-self.mapSize,self.mapSize do
    self.map[x] = {}
    for y=-self.mapSize,self.mapSize do
      self.map[x][y] = {}
      for z=-self.mapSize,self.mapSize do
        -- if this one is within the grid ...
        if (x + y + z) == 0 then
          -- initialize an empty object;
          self.map[x][y][z] = {} 
          
          -- convert to unique integer id
          local flatPos = (x + self.mapSize) + (y + self.mapSize) * totalSize

          --  remember it in the map list so we can place a random element here later
          -- self.mapList[flatPos] = { x = x, y = y, z = z, num = 0 }
        end
      end
    end
  end
  
  self.numCollectibles = 0
  self.levelIndicators = {}
  
  -- if no level was given, generate one randomly
  if not levelData then
    -- seed math stuff
    -- math.randomseed( 2000 )
    math.randomseed( os.time() )
    
    ------------
    -- place special stuff randomly on the map
    ------------
    local wantedCollectibles = math.random(1,3)
    local wantedObstacles = math.random(7,13)
    
    local specialStuff = {}
    for i=1,wantedCollectibles do
      table.insert(specialStuff, 3)
    end
    
    for i=1,wantedObstacles do
      table.insert(specialStuff, 4)
    end
    
    for i=1,#specialStuff do
      -- keep picking random hexagons, until we find one that's allowed
      local wantedCell = { isTaken = true }
      while wantedCell.isTaken do
        wantedCell = self.mapList[math.random(#self.mapList)]
      end
      
      -- then insert the collectible here
      wantedCell.num = specialStuff[i]
      wantedCell.isTaken = true
    end

  -- if we DO have level data ...
  else
    -- run through the data
    
    -- if this level has any levelIndicators, save them for later use
    if levelData.levelIndicators then
      self.levelIndicators = levelData.levelIndicators
    end
    
    -- convert each level indicator's position to hex format, save that 
    -- (will make the algorithm a bit quicker later)
    -- Re-use this array later for drawing lines between the different indicators
    local indicatorArray = {}
    local fogThreshold = 2
    local lastLevel = self:getSaveData().lastLevel
    if GLOBALS.unlockAllLevels then lastLevel = 1000000 end
    
    if GLOBALS.campaignScreen and not GLOBALS.editorActive then
      for k,v in pairs(self.levelIndicators) do
        -- NOTE: We add ALL indicators to the array
        --       but, later on, we prune anything that's below lastLevel when it comes to index
        --       we can do this because the list is SORTED
        local x,y,z = self:flatToHex(tonumber(k))
        local num = tonumber(v)
        local obj = { x = x, y = y, z = z, num = num }
        
        table.insert(indicatorArray, obj)
        
        -- if this is our current hex, save it, because we want to focus the camera on it
        if num == lastLevel then
          GLOBALS.curLevelHex = obj
        elseif num == (lastLevel - 1) then
          GLOBALS.prevLevelHex = obj
        end
      end
      
      -- sort this table
      table.sort(indicatorArray, function(a,b) return a.num < b.num end)
      
      -- so we can draw lines between all of them
      local cX, cY = display.contentCenterX, display.contentCenterY
      local numValidIndicators = math.min(lastLevel, #indicatorArray)
      for i=2,numValidIndicators do
        local p1 = self:hexToPixel(indicatorArray[i-1])
        local p2 = self:hexToPixel(indicatorArray[i])
        
        -- we need to compensate for the offset through the center of the screen
        -- why?? I actually don't know
        local line = display.newLine(self.mapGroup, p1.x + cX, p1.y + cY, p2.x + cX, p2.y + cY)
        line.strokeWidth = 5
        line:setStrokeColor(0.5, 0.5, 0.5, 0.5)
        line.campaignPath = true
        line.lowerY = math.max(p1.y + cY, p2.y + cY)
      end
    end

    -----
    -- VERY IMPORTANT! REMEMBER! 
    -- Our "flatPos" starts at 0. But Lua arrays start at 1. So we must subtract 1 when calculating position
    -----
    local l = levelData.level
    for i=1,#l do
      local val = l[i]
      if val ~= 0 then
        -- get (x,y,z) from integer id
        local ii = (i-1)
        local x,y,z = self:flatToHex(ii)
        local dist = 1000
        
        -- at campaign screen, implement a "fog of war"
        -- go through all level indicators and check if any of them is within range
        if GLOBALS.campaignScreen and not GLOBALS.editorActive then
          for j=1,#indicatorArray do
            local ind = indicatorArray[j]
            
            -- if the distance is 0, it means our current hex is an indicator
            if (x == ind.x and y == ind.y and z == ind.z) then
              -- check if it should be shown; if not, increase distance to some huge number and break
              if ind.num > lastLevel then
                dist = 1000
                break
              end
            end
            
            -- only check distance for indicators that are VISIBLE/UNLOCKED
            if j <= lastLevel then
              local tempDist = (math.abs(x - ind.x) + math.abs(y - ind.y) + math.abs(z - ind.z)) * 0.5
              dist = math.min(dist, tempDist)
            end
          end
        else
          dist = 0
        end
        
        if dist <= fogThreshold then
          -- print(x-self.mapSize,y-self.mapSize,z-self.mapSize)
          -- update map with right value
          self.map[x][y][z] = val
          self.mapList[ii] = { x = x, y = y, z = z, num = val }
        end
      end
    end
  end

  ------------
  -- display the map
  ------------
  -- for each hexagon ...
  self.tileTypes = {}
  for k,v in pairs(self.mapList) do
    -- initialize it!
    self:initializeHexagon(v)
    
    -- also, keep track of which TILE TYPES are in the level
    self.tileTypes[v.num] = true
  end
  
  -- now sort everything
  self:performYSort()
  
        
  -- if both previous and current level exist, send a letter animation!
  -- NOTE: We do this _after_ sorting, so the letter is clearly visible
  if GLOBALS.curLevelHex and GLOBALS.prevLevelHex then
    self:sendCampaignLetter()
  end
  

  
  return self
end