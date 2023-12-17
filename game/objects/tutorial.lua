Tutorial = Object:extend()

local widget = require("widget")

function Tutorial:destroy()
  -- pass
end

function Tutorial:loadNext()
  print("LOAD NEXT TUTORIAL")
  self.isDone = false
  
  ---------
  -- DESTROY old tutorial stuff
  ---------
  for i=1,#self.tutorialObjects do
    self.tutorialObjects[i]:removeSelf()
  end
  self.tutorialObjects = {}
  
  --------
  -- READ tutorial data
  --------
  self.tutIndex = self.tutIndex + 1
  local d = self.tutData[self.tutIndex]
  
  if d and d.mobileOnly and (system.getInfo("platform") ~= "android") then
    d = nil
  end
  
  -- if this value doesn't exist ...
  if not d then
    -- then the tutorial is over!
    self.isDone = true
    
    -- if we should display a modal, do so
    if self.didWeWin ~= -1 then
      GLOBALS.map:gameOver(self.didWeWin)
    end
    
    -- return out of the function
    return
  end

  --------
  -- DISPLAY new tutorial objects
  --------
  local textObjects = {}
  for i=1,#d.objects do
    local o = d.objects[i]
    local newObj
    
    if o.what == 'text' then
      -- create new text field
      -- NOTE: All parameters (x,y,width,...) are relative to hex size
      local textOptions = {
          parent = self.mapGroup,
          x = self.mapCenter.x + o.x*self.hexSize,
          y = self.mapCenter.y + o.y*self.hexSize, 
          font = GLOBALS.pixelFont,
          text = o.text,
          fontSize = 32,
          align = 'center'
      } 
      
      -- OPTIONAL: if a width has been set, copy it
      if o.width then
        textOptions.width = o.width * self.hexSize
      end
      
      -- create the new object!
      newObj = display.newEmbossedText(textOptions)
      
      -- split text into characters
      -- (so we can reveal characters one at a time
      local textSize = string.len(o.text)

      newObj.splitText = {}
      newObj.splitTextCounter = 1
      newObj.splitTextSize = textSize
      for i=1,textSize do
        newObj.splitText[i] = string.sub(o.text, 1, i)
      end
      
      -- add object to full table of text objects
      table.insert(textObjects, newObj)
    
    elseif o.what == 'image' then
      -- display default modal background
      local bg = display.newImageRect(self.sceneGroup, 'assets/interface/modalOverlay.png', 320, 480*0.5)
      bg.x = display.contentCenterX
      bg.y = display.contentCenterY
      table.insert(self.tutorialObjects, bg)
    
      -- display image
      newObj = display.newImageRect(self.sceneGroup, 'assets/tutorials/' .. o.imageName .. '.png', 320, 480*0.5)
      newObj.x = display.contentCenterX
      newObj.y = display.contentCenterY
      
      -- and a button to progress
      local bs = 1 -- buttonscale
      local buttonOptions = {
        width = 65*bs,
        height = 16*bs,
        id = "continueButton",
        defaultFile = "assets/interface/continueButtonWide.png",
        overFile = "assets/interface/continueButtonWideOver.png",
        onRelease = function(event) self:loadNext() end
      }
      
      local continueButton = widget.newButton(buttonOptions)
      continueButton.x = newObj.x
      continueButton.y = newObj.y + 0.5*newObj.height - 32

      self.sceneGroup:insert(continueButton)
      table.insert(self.tutorialObjects, continueButton)
    end
    
    -- save object (for easy removal later)
    table.insert(self.tutorialObjects, newObj)
  end
  
  -- plan the next load event (but only if a delay is set)
  -- NOTE: This plans the event, without taking into account how long text takes to show => so I need to compensate myself
  if d.delay then
    timer.performWithDelay(d.delay, function() self:loadNext() end)
  end
  
  -- start writing characters for each text object
  -- (why am I generalizing this?? I'll never need more than one text object xD)
  for i=1,#textObjects do
    self:nextCharacter(textObjects[i])
  end
  
  -- wait for a forced move (if it has been set)
  if d.forcedMove then
    GLOBALS.map.forcedMove = d.forcedMove
  end
end

function Tutorial:nextCharacter(obj)
  -- update counter
  obj.splitTextCounter = obj.splitTextCounter + 1
  
  -- update text
  obj.text = obj.splitText[obj.splitTextCounter]
  
  -- play "beep" sound for each letter (or some other "letter appear" sound)
  local randBeep = GLOBALS.audio.textbeep[math.random(#GLOBALS.audio.textbeep)]
  local randVolume = math.random()*0.5
  local channel = (obj.splitTextCounter % 32) + 2
  
  local function beepCallback(ev)
    audio.setVolume(1.0, { channel = ev.channel })
  end
  
  audio.setVolume(randVolume, { channel = channel } )
  audio.play(randBeep, { channel = channel, onComplete = beepCallback })
  
  -- if we've NOT reached the end yet, plan the next event
  if obj.splitTextCounter < obj.splitTextSize then
    local charDelay = 66
    timer.performWithDelay(charDelay, function() self:nextCharacter(obj) end)
  end
end

function Tutorial:new(scene, ind)
  self.sceneGroup = scene.view
  self.mapGroup = GLOBALS.map.mapGroup -- cache reference to mapGroup
  self.mapCenter = GLOBALS.map.mapCenter
  self.hexSize = GLOBALS.map.hexSize
  
  self.isDone = true
  self.didWeWin = -1
  
  -- grab tutorial data from list, using correct level index
  self.tutData = require("tools.tutorialData")[ind]
  
  -- if there is no tutorial data, return
  if not self.tutData then
    return self
  end
  
  -- if we're working with autoSolution, display no tutorial as well
  if GLOBALS.autoSolution then
    return self
  end
  
  -- this array holds all tutorial objects that are currently active
  self.tutorialObjects = {}
  self.tutIndex = 0

  -- start tutorial
  self:loadNext()
  
  return self
end