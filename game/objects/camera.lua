Camera = Object:extend()

local MAX_MOVE_DIST_FOR_CLICK = 35

function math.dist(x1, y1, x2, y2)
  return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y2))
end

function math.clamp(val, lower, upper)
  return math.max( math.min(val, upper), lower)
end

function Camera:destroy()
  -- pass
end

function Camera:onTouchEvent(event)
  local p = event.phase
  local curTouch = self.touches[event.id]
  
  if p == 'began' then
    -- register this touch
    self.touches[event.id] = { x = event.x, y = event.y, moved = false, id = event.id, moveDist = 0 }
    self.numTouches = self.numTouches + 1
    
    -- if we have more than a single touch ...
    if self.numTouches > 1 then
      -- determine the radius between first two touches we find
      -- (using current touch as touch1)
      -- this is used for zooming in/out with pinch gestures
      self.touch1 = event.id
      self.touch2 = nil
      for k,v in pairs(self.touches) do
        -- if we found a second (not-the-same) touch ...
        if v.id ~= self.touch1 then
          -- save it
          self.touch2 = v.id
          
          -- save radius
          local obj1 = self.touches[self.touch1]
          local obj2 = self.touches[self.touch2]
          self.previousRadius = math.dist(obj1.x, obj1.y, obj2.x, obj2.y)
          
          -- stop loop
          break
        end
      end
    end
  
  elseif p == 'moved' then
    -- if we moved, either PAN the camera or ZOOM (pinch gesture)
    
    ------
    -- if we have more than two touches, ZOOM 
    ------
    if self.numTouches > 1 then
      self:zoomCamera()
      
      curTouch.moveDist = 1000
  
    ------
    -- if we have only one touch, PAN
    ------
    elseif self.numTouches == 1 then
      if curTouch and not curTouch.usedToZoom then
        -- get moved distance
        local dx = event.x - curTouch.x
        local dy = event.y - curTouch.y
        
        curTouch.moveDist = curTouch.moveDist + math.abs(dx) + math.abs(dy)
        
        -- pan camera
        self:panCamera(dx, dy)
      end
    
    -- if we have no touches, abort
    else
      return
    end
    
    -- update touch registry
    curTouch.x = event.x
    curTouch.y = event.y
    curTouch.moved = true
  end
  
  -- ANNOYING: If you hold mouse clicked, then move off-screen, it doesn't END the click!
  if p == 'ended' or p == 'canceled' or (p == 'moved' and self:eventOutsideScreen(event) ) then
    -- if this touch doesn't exist,
    -- this means the touch started in the PREVIOUS scene, but only ended here
    -- so, return
    if not self.touches[event.id] then
      return false
    end
    
    -- if this touch did not move
    -- or we moved only by a tiny amount (10 pixels?)
    -- and it's NOT part of a panning movement (TO DOOO)
    local partOfZoom = self.touches[event.id].usedToZoom
    if (not curTouch.moved or curTouch.moveDist < MAX_MOVE_DIST_FOR_CLICK) and
        not partOfZoom then
      -- then pretend we clicked a hexagon
      -- (the map will handle which one, if one at all, etc.)
      self:clickHexagon(event.x, event.y)
    end
    
    -- un-register the touch
    self.touches[event.id] = nil
    self.numTouches = self.numTouches - 1
  end
  
  return false
end

function Camera:eventOutsideScreen(ev)
  return ev.x <= display.screenOriginX or ev.x >= (display.contentWidth - display.screenOriginX) or ev.y <= display.screenOriginY or ev.y >= (display.contentHeight - display.screenOriginY)
end

function Camera:zoomCamera(scrollEvent)
  scrollEvent = scrollEvent or false
  
  -------
  -- DETERMINE how much to zoom (and in which direction)
  -- (different between desktop/device)
  -------
  local diff = 0 -- how much to zoom
  local touch = {} -- where the user zoomed
  local rad = 0
  if scrollEvent then
    diff = scrollEvent.scrollY * 0.05
    touch = { x = scrollEvent.x, y = scrollEvent.y }
  else
    -- if either of the touches is undefined, return
    if not self.touch1 or not self.touch2 then
      return
    end
    
    local obj1 = self.touches[self.touch1]
    local obj2 = self.touches[self.touch2]
    
    -- remember we used these touches to zoom in/out
    obj1.usedToZoom = true
    obj2.usedToZoom = true
    
    -- get radius between touches
    rad = math.dist(obj1.x, obj1.y, obj2.x, obj2.y)
    
    -- get difference with previous radius
    -- convert it to a relative zoom factor (much easier for good scaling)
    diff = (self.previousRadius - rad) / self.previousRadius
    
    -- get average touch position
    touch =  { x = (obj1.x + obj2.x)*0.5, y = (obj1.y + obj2.y)*0.5 }
  end
  
  -------
  -- ACTUALLY ZOOM!
  -------
  local mapGroup = GLOBALS.map.mapGroup
  
  -- add zoom factor to current zoom
  local oldZoom = mapGroup.xScale
  local newZoom = math.clamp(mapGroup.xScale - diff*0.3, 0.5, 2.0)

  -- use/apply that to zoom
  mapGroup.xScale = newZoom
  mapGroup.yScale = newZoom
  
  ----------
  -- move camera to keep same point underneath zoom
  ----------
  
  -- get change in distance within screen frame
  local screen = { x = display.contentWidth, y = display.contentHeight }
  local oldDist = { x = touch.x * oldZoom, y = touch.y * oldZoom }
  local newDist = { x = touch.x * newZoom, y = touch.y * newZoom }
  
  -- determine movement needed => then move camera
  local movementNeeded = { x = oldDist.x - newDist.x, y = oldDist.y - newDist.y }
  mapGroup:translate(movementNeeded.x, movementNeeded.y)
  
  -- remember current radius for next frame
  self.previousRadius = rad
  
  
  ----
  -- Update text fields of indicators
  -- (only when editing campaign screen)
  ----
  if GLOBALS.editorActive and GLOBALS.campaignScreen then
    local inds = GLOBALS.map.levelIndicators
    for k,v in pairs(inds) do
        v.overlay.myTextBox:resizeFontToFitHeight()
    end
  end
end

function Camera:panCamera(dx, dy)
  GLOBALS.map:panCamera(dx, dy)
end

function Camera:clickHexagon(x, y)
  print("Clicked a hexagon at", x, y)
  GLOBALS.map:clickHexagon(x, y)
end

function Camera:keyEvent(event)
  if event.phase == 'up' and event.keyName == 'up' then
    print("KEY EVENT")
    if self.touches.blabla then
      self.touches.blabla = nil
      self.numTouches = self.numTouches - 1
    else
      self.touches['blabla'] = { x = display.contentCenterX, y = display.contentCenterY, moved = false, id = 'blabla' }
      self.numTouches = self.numTouches + 1
    end
  end
  
  print(self.numTouches)
end

function Camera:mouseEvent(event)
  if math.abs(event.scrollY) >= 0.1 then
    self:zoomCamera(event)
  end
  
  return false
end

function Camera:new(scene)
  self.sceneGroup = scene.view
  self.mapGroup = GLOBALS.map.mapGroup

  -- create big rectangle to intercept touch events
  local rect = display.newRect(self.sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  rect.isVisible = false
  rect.isHitTestable = true
  
  rect:addEventListener("touch", function(event) self:onTouchEvent(event) end )
  
  -- Runtime:addEventListener("key", function(event) self:keyEvent(event) end )
  
  -- create variables for controlling panning / zooming
  self.touches = {}
  self.numTouches = 0
  self.previousRadius = 0
  
  -- determine if game is running on desktop or not
  -- (simulator = always desktop, otherwise = check name)
  self.isRunningOnDesktop = false
  if system.getInfo( "environment" ) == "simulator" then
    self.isRunningOnDesktop = true
  elseif (system.getInfo("environment") == "device") then
    local platformName = system.getInfo("platformName")
    if (platformName == "Win") or (platformName == "Mac OS X") then
      self.isRunningOnDesktop = true
    end
  end
    
  -- if on DESKTOP, activate zooming in/out using mouse scrolling
  if self.isRunningOnDesktop then
    self.mouseEventListener = function(event) self:mouseEvent(event) end
    Runtime:addEventListener( "mouse", self.mouseEventListener )
  end
  
  -------
  -- Center camera on last level, if available
  -------
  if GLOBALS.campaignScreen then
    if GLOBALS.curLevelHex then
      -- get pixel location of wanted position
      local pos = GLOBALS.map:hexToPixel(GLOBALS.curLevelHex)
      
      -- get difference vector
      local dx = self.mapGroup.x - pos.x
      local dy = self.mapGroup.y - pos.y
      
      -- move according to vector
      self:panCamera(dx, dy)
    end
  end
  
  return self
end