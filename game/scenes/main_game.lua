-----------------------------------------------------------------------------------------
--
-- main_game.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include all objects (map, camera, interface, ??)
require("objects.map")
require("objects.camera")
require("objects.interface")
require("objects.editor")
require("objects.tutorial")

require("tools.timer2")

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

function scene:create( event )
	local sceneGroup = self.view
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
    -----
    -- grab level to load
    -----
    local allLevels = GLOBALS.loadTable('level_data.json')
    local customLevels = GLOBALS.loadTable('saved_levels.json', system.DocumentsDirectory)
    
    -- only take levels that convert to a number (otherwise it's a comment or something else in the JSON)
    allLevels["__comment"] = nil
    allLevels["__levelsilike"] = nil
    
    -- pick a random level (+ remember its index)
    local levelData, ind = math.randomChoice(allLevels)
    
    -------
    -- DEBUGGING: For grabbing a specific level
    --------
    --ind = "-1885458432"
    --ind = "-1137650688"
    ind = "campaign_screen"

    -- if we have a next level to load, load that instead!
    if GLOBALS.nextLevelToLoad then
      ind = GLOBALS.nextLevelToLoad
      GLOBALS.curLevel = ind
      GLOBALS.nextLevelToLoad = nil
    end
    
    -- TO DO: Find a better way to set/check this?
    GLOBALS.campaignScreen = false
    if ind == 'campaign_screen' then
      GLOBALS.campaignScreen = true
    end
    --GLOBALS.campaignScreen = false
    --GLOBALS.editorActive = true
    
    print("I want to load index ", ind)
    
    -------
    -- Actually grab the level data (once we've finally decided on the index)
    -------
    levelData = allLevels[ind]
    
    -- if a custom level exists with the same name, use that instead!
    if customLevels then
      if customLevels[ind] then 
        levelData = customLevels[ind] 
      end 
    end
    
    -- if we can't find any level data ... display an advertisment!
    if not levelData or not ind then
      print("ERROR! No level (data)")
      return
    end
    
    -- create map
    GLOBALS.map = Map(scene, levelData, ind)
    
    -- create camera
    GLOBALS.cam = Camera(scene)
    
    -- create interface
    GLOBALS.interface = Interface(scene, levelData, ind)
    
    -- create editor
    -- (second parameter = whether it's active or not)
    -- (third parameter = editor needs to know ind to set current filename properly)
    GLOBALS.editor = nil
    if GLOBALS.showEditorUI then
      GLOBALS.editor = Editor(scene, GLOBALS.editorActive, ind)
    end
    
    -- create tutorial object
    -- TO DO: Give it the correct tutorial data, or disable it if there's no tutorial!
    GLOBALS.tutorial = Tutorial(scene, ind)
    
    if GLOBALS.autoSolution then
      GLOBALS.map:simulateNextMove()
    end
	end
end

--[[
-- GOOD LEVELS
["-911334400", "-892758016", "1555020800", "2084269056", "-1312666624", "623511552",
 "351619072"]
 
 -- FIRST ONE WITH CORRECT ORDER (oldTowers -> newTower)
 "1243675648"
 
 -- FIRST GOOD ONE WITH TERRAIN
 "-1808200704"
 
 --]]

function math.randomChoice(t) --Selects a random item from a table
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table
    end
    index = keys[math.random(1, #keys)]
    return t[index], index
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then

	elseif phase == "did" then

	end	
	
end

function scene:destroy( event )
	local sceneGroup = self.view
  
  -- remove any focus from input elements
  native.setKeyboardFocus(nil)
  
  -- cancel all transitions
  transition.cancel()
  
  -- cancel all timers
  timer.cancel()
  
  -- destroy globals (but carefully)
  GLOBALS:destroy()
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene