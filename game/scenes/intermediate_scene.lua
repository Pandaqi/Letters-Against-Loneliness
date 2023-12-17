local composer = require("composer")
local scene = composer.newScene()

function scene.loadActualGame()
  -- NOTE VERY IMPORTANT!!!!
  -- If we don't set the second parameter to true, local variables (to main_game.lua) are deleted upon restart/removal
  -- We don't want that, as we rely on some of those variables (such as nextLevelToLoad)
  composer.removeScene( "scenes.main_game", true)
    
  -- with a fancy transition (need to learn how those work...)
  composer.gotoScene( "scenes.main_game", { time = 500, effect = "crossFade" })
end

function scene:show(event)
  if event.phase == 'did' then
  
    local delayVal = 500
    if system.getInfo( "environment" ) == "simulator" then
      delayVal = 0
    end
    
    --  Only apply this delay if we're outside of corona simulator!
    timer.performWithDelay(delayVal, scene.loadActualGame)
  end
end

function scene:hide(event)
  
end

function scene:create(event)
  
end

function scene:destroy(event)
  
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

