Editor = Object:extend()

local widget = require("widget")

function Editor:destroy()
  self.levelNameInput:removeSelf()
  self.levelNameInput = nil
end

function Editor:isActive()
  return self.active
end

function Editor:getSelectedType()
  return self.selectedType
end

function Editor:tileTapped(event)
  -- TO DO: Besides scaling, also add some highlighting and stuff
  
  -- **un**-highlight previous tile
  if self.curTileTapped then
    self:unHighlightTapTile(self.curTileTapped)
  end
  
  -- highlight the new tile
  -- (NOTE: scale is a RELATIVE action, not absolute scale)
  self.curTileTapped = event.target
  
  self:highlightTapTile(self.curTileTapped)
  
  -- update selected type
  self.selectedType = event.target.myType
end

function Editor:highlightTapTile(obj)
  obj.xScale = 1.0
  obj.yScale = 1.0
  
  obj.fill.effect = nil
  obj.alpha = 1.0
end

function Editor:unHighlightTapTile(obj)
  obj.xScale = 0.75
  obj.yScale = 0.75
  
  obj.fill.effect = 'filter.grayscale'
  obj.alpha = 0.75
end

function Editor:loadEvent(event)
  -- save the level we want to load
  GLOBALS.nextLevelToLoad = self.levelNameInput.text
  
  -- now reload the map
  GLOBALS.map:reload()
end

function Editor:saveEvent(event)
  -- grab name from input
  local name = self.levelNameInput.text
  
  print("Want to save under name", name)
  
  -- grab the current level in a presentable format
  local curLevel = {}
  local m = GLOBALS.map
  
  curLevel.mapSize = m.mapSize
  curLevel.solution = {} -- TO DO???
  curLevel.level = m:buildLevelArray()
  
  ------
  -- LEVEL INDICATORS
  -------
  -- convert to actual array (instead of table)
  local tempArray = {}
  local levelIndicatorsExist = false
  for k,v in pairs(m.levelIndicators) do
    -- TO DO: For now, just save the number (might need more later)
    tempArray[k] = tonumber(v.overlay.myTextBox.text)
    
    levelIndicatorsExist = true
  end
  
  -- and save them
  curLevel.levelIndicators = tempArray
  if not levelIndicatorsExist then
    curLevel.levelIndicators = nil
  end
  
  -- grab the save file
  -- (if it doesn't exist, create empty one)
  local saveFile = GLOBALS.loadTable('saved_levels.json', system.DocumentsDirectory)
  if not saveFile then saveFile = {} end
  
  -- append (or overwrite) the current level
  saveFile[name] = curLevel
  
  -- save the file again
  GLOBALS.saveTable(saveFile, 'saved_levels.json', system.DocumentsDirectory)
  
  print("SAVING SUCCESFUL")
end

function Editor:growEvent(event)
  if not self.active then return end
  
  GLOBALS.map:growWorld()
end

function Editor:editorToggle(event)
  -- toggle main variable (self.active)
  self.active = event.target.isOn
  
  -- update global variable
  GLOBALS.editorActive = self.active
  
  -- change other properties
  if self.boundsHexagon then
    self.boundsHexagon.isVisible = self.active
  else
    self:updateBoundsHexagon()
  end
end

function Editor:updateBoundsHexagon()
  local m = GLOBALS.map -- quick reference to map
  
  -- if hexagon doesn't exist yet, create it
  if not self.boundsHexagon then
    -- create all the points
    local points = {}

    local size = m.hexSize
    for p=1,6 do
      local angle = math.rad(30 + 60 * p)
      points[p*2 - 1] = size * math.cos(angle) --  x coordinate
      points[p*2] = size * math.sin(angle) -- y coordinate
    end
  
  -- create the background hex sprite
    local newObj = display.newPolygon(m.mapGroup, m.mapCenter.x, m.mapCenter.y, points)
    newObj:toBack()
    newObj.fill = {0,0,0,0}

    -- add dashed stroke/outline
    newObj.strokeWidth = 1
    newObj:setStrokeColor(1, 0, 0, 0.5)
    newObj.stroke.effect = "generator.marchingAnts"
    
    self.boundsHexagon = newObj
  end
  
  -- now update its size
  local newScale = m.totalMapSize - 1 + 0.5
  
  self.boundsHexagon.xScale = newScale
  self.boundsHexagon.yScale = newScale
  
end

function Editor:new(scene, active, ind)
  self.sceneGroup = scene.view
  
  self.active = active
  self.selectedType = 0
  self.curTileTapped = nil
  
  local margin = 20
  local x = 0
  local y = 0
  
  local scrollViewMargin = 5
  local scrollViewHeight = 32+2*scrollViewMargin
  
  x = display.screenOriginX + margin
  y = display.contentHeight - display.screenOriginY - scrollViewHeight - margin
  
  ---------
  -- Create "ON/OFF" switch for the editor
  ---------
  local options = {
    width = 64,
    height = 32,
    numFrames = 2,
    sheetContentWidth = 64*2,
    sheetContentHeight = 32
  }
  local checkboxSheet = graphics.newImageSheet( "assets/interface/editorToggle.png", options )
   
  -- Create the widget
  local editorToggle = widget.newSwitch(
      {
          style = "checkbox",
          id = "Checkbox",
          width = 64,
          height = 32,
          onPress = function(event) self:editorToggle(event) end,
          sheet = checkboxSheet,
          initialSwitchState = self.active,
          frameOff = 2,
          frameOn = 1
      }
  )
  
  editorToggle.anchorX = 0
  editorToggle.anchorY = 1
  self.sceneGroup:insert(editorToggle)

  editorToggle.x = x
  editorToggle.y = y
  
  -- Create horizontal scroll view that holds all hexagon types
  --        (and allow selecting a certain type by clicking on it)
  local tileSelector = widget.newScrollView(
      {
          top = display.contentHeight - display.screenOriginY - scrollViewHeight,
          left = display.screenOriginX,
          width = display.actualContentWidth,
          height = scrollViewHeight,
          verticalScrollDisabled = true,
          horizontalScrollDisabled = false,
          backgroundColor = {0, 0, 0, 0.5}
      }
  )
  self.sceneGroup:insert(tileSelector)
  
  -- Populate scroll view with all the tiles
  local maxTiles = 56
  local offset = 1
  local startingTile = nil
  
  -- TO DO: At some point, when I have enough images, it will be more useful/easier to create a single array for this
  -- (instead of line-by-line statements
  local tileImages = {}
  tileImages[0] = 'tileDelete'
  
  tileImages[1] = 'tileBeach'
  tileImages[3] = 'overlayForest'
  tileImages[4] = 'overlayMountain'
  
  tileImages[11] = 'overlayTestPerson'
  tileImages[12] = 'overlayGuard1'
  tileImages[13] = 'overlayGuard2'
  tileImages[14] = 'overlayGuard3'
  tileImages[15] = 'overlayBuilder'
  tileImages[16] = 'overlayStubborn'
  tileImages[17] = 'overlayMover'
  
  tileImages[27] = 'overlayGate1'
  tileImages[28] = 'overlayGate2'
  tileImages[29] = 'overlayGate3'
  -- 30 is the enemy
  tileImages[31] = 'overlayBuildingDefault'
  tileImages[32] = 'overlayBuildingRotated'
  tileImages[33] = 'overlayBuildingSwitch'
  
  tileImages[56] = 'levelFlag'
  
  for i=-1,maxTiles do
    local myType = i
    if i == -1 then
      myType = 56
    end
    
    -- towers are NOT allowed to be placed in edit mode
    if not (i >= 5 and i <= 10) then
      
      local wantedImage = 'tileGrass'
      if tileImages[myType] then
        wantedImage = tileImages[myType]
      end
      
      local sheetInfo = GLOBALS.map.mainSheetInfo
      local frameInfo = sheetInfo.frameIndex[wantedImage]
      local size = 32
      local tileBasic = display.newImageRect( GLOBALS.map.mainImageSheet, frameInfo, sheetInfo.sheet.frames[frameInfo].width, sheetInfo.sheet.frames[frameInfo].height )
    
      tileBasic:scale(size / 32, size / 32)
      tileSelector:insert(tileBasic)
      
      -- determine position
      tileBasic.x = offset*(32+scrollViewMargin)
      tileBasic.y = scrollViewMargin + 0.5*32
      offset = offset + 1
      
      -- determine type + highlighting
      tileBasic.myType = myType
      
      self:unHighlightTapTile(tileBasic)
      
      -- if this is the default/starting type, highlight it already
      if self.selectedType == tileBasic.myType then
        startingTile = tileBasic
      end
      
      -- listen to tap events
      tileBasic:addEventListener("tap", function(event) self:tileTapped(event) end)
      
    end
  end
 
  self:tileTapped({ target = startingTile })

  --------
  -- Create "GROW WORLD" button that adds 1 size to the whole world
  --------
  local growButton = widget.newButton(
    {
        width = 64,
        height = 32,
        defaultFile = "assets/interface/growButton.png",
        overFile = "assets/interface/growButtonOver.png",
        onRelease = function(event) self:growEvent(event) end
    }
  )
  
  growButton.anchorX = 0
  growButton.anchorY = 1
  self.sceneGroup:insert(growButton)
  
  x = x + 32 + margin*2
  
  growButton.x = x
  growButton.y = y
  
  -- Create the hexagon that shows outer bounds of world
  -- (if editor is not active, don't do this of course)
  if active then
    self:updateBoundsHexagon()
  end
  
  ---------
  -- TEXT FIELD for inputting level name
  ---------
  x = display.contentWidth - display.screenOriginX - 0.5*margin
  local textWidth = 150
  local textBox = native.newTextField( x, y, textWidth, 32 )
  textBox.text = "Level Name Here"
  textBox.isEditable = true
  
  textBox.anchorX = 1
  textBox.anchorY = 1
  
  textBox.text = ind -- set name to current saved name
  
  self.levelNameInput = textBox
  self.sceneGroup:insert(textBox)
  
  --------
  -- Create "SAVE" button (to save the current level)
  --------
  local saveButton = widget.newButton(
    {
        width = 64,
        height = 32,
        defaultFile = "assets/interface/saveButton.png",
        overFile = "assets/interface/saveButtonOver.png",
        onRelease = function(event) self:saveEvent(event) end
    }
  )

  saveButton.anchorX = 1
  saveButton.anchorY = 1

  x = x - textWidth - 0.5*margin
  saveButton.x = x
  saveButton.y = y
  self.sceneGroup:insert(saveButton)
  
  --------
  -- Create "LOAD" button (to load a new level)
  --------
  local loadButton = widget.newButton(
    {
        width = 64,
        height = 32,
        defaultFile = "assets/interface/loadButton.png",
        overFile = "assets/interface/loadButtonOver.png",
        onRelease = function(event) self:loadEvent(event) end
    }
  )

  loadButton.anchorX = 1
  loadButton.anchorY = 1

  x = x - 64 - 0.5*margin
  loadButton.x = x
  loadButton.y = y
  self.sceneGroup:insert(loadButton)
  
  
  return self
end