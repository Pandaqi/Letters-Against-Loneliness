Globals = Object:extend()

-- FOR LOADING LEVEL DATA
local json = require( "json" )
local defaultLocation = system.ProjectDirectory

function Globals:destroy()
  --------
  -- Destroy and nil all big systems
  --------
  self.map:destroy()
  self.map = nil
  
  self.cam:destroy()
  self.cam = nil
  
  self.interface:destroy()
  self.interface = nil
  
  if self.editor then
    self.editor:destroy()
    self.editor = nil
  end
  
  self.tutorial:destroy()
  self.tutorial = nil
  
  --------
  -- NIL some other variables
  --------
  self.curLevelHex = nil
  self.prevLevelHex = nil
end

function Globals:new()
  -- DEBUGGING settings (toggle on/off while working on the game)
  -- global settings (campaign, editor, etc.)
  self.showEditorUI = false
  self.unlockAllLevels = false
  self.hintShowsFullSolution = false
  self.backgroundMusicOff = false
  
  -- these are set by the game itself, don't override here (and expect things to happen)
  self.autoSolution = false
  self.editorActive = false
  self.campaignScreen = false
  
  -- custom cutoff for when the game ends 
  -- (it's been too long, don't know how to _calculate_ this dynamically)
  -- additionally, I made a mistake and order/index is all messed up, as the "real" last level is actually level111 xD
  self.lastLevelID = "level110"
  
  -- global fonts
  self.pixelFont = 'assets/fonts/m6x11.ttf'
  
  return self
end

function Globals:loadAllAudio()
  local dir = "assets/audio/"
  
  self.audio = {
    bgmusic = audio.loadStream( dir .. "main_theme.mp3" ),
    postoffice = audio.loadSound( dir .. "postoffice.mp3" ),
    swoosh = {
      audio.loadSound( dir .. "swoosh1.mp3" ),
      audio.loadSound( dir .. "swoosh2.mp3" ),
      audio.loadSound( dir .. "swoosh3.mp3" ),
      audio.loadSound( dir .. "swoosh4.mp3" ),
      audio.loadSound( dir .. "swoosh5.mp3" ),
      audio.loadSound( dir .. "swoosh6.mp3" )
    },
    gamewin = audio.loadSound( dir .. "game_win.mp3" ),
    gameloss = audio.loadSound( dir .. "game_loss.mp3" ),
    letterdelivered = audio.loadSound( dir .. "letter_delivered.mp3" ),
    letterblock = audio.loadSound( dir .. "letter_block.mp3" ),
    dirswitch = audio.loadSound( dir .. "dir_switch.mp3" ),
    mover = audio.loadSound( dir .. "mover.mp3" ),
    builder = audio.loadSound( dir .. "builder.mp3" ),
    brickfalling = audio.loadSound( dir .. "brickfalling.mp3" ),
    textbeep = {
      audio.loadSound( dir .. "textbeep1.mp3" ),
      audio.loadSound( dir .. "textbeep2.mp3" ),
      audio.loadSound( dir .. "textbeep3.mp3" ),
      audio.loadSound( dir .. "textbeep4.mp3" )
    },
    forest = audio.loadSound( dir .. 'forest.mp3' ),
    door = audio.loadSound( dir .. 'door.mp3' )
  }
  
  if not self.backgroundMusicOff then
    -- always play bgmusic in channel 1 (allow nothing else)
    -- and loop indefinitely (loops = -1)
    audio.reserveChannels(1)
    audio.play(self.audio.bgmusic, { channel = 1, loops = -1 })
  end
  
  -- Use this for playing audio throughout the project: audio.play(self.audio.something, 
end

function Globals:tableHasValue(t, v)
  for i=1,#t do
    if t[i] == v then
      return true
    end
  end
  return false
end

-- given a JSON sheet (from Free Texture Packer), converts it to Lua that Corona can understand
function Globals:convertImageSheet(oldSheet)
  local newSheet = {}
  newSheet.sheet = {}
  newSheet.sheet.frames = {}
  newSheet.frameIndex = {}
  
  -- for all frames in the JSON file ...
  for k,v in pairs(oldSheet.frames) do
    -- save the link between current INDEX and frame NAME
    newSheet.frameIndex[k] = (#newSheet.sheet.frames + 1)
    
    -- convert frame to proper Lua table
    local tempFrame = {}
    
    tempFrame.x = v.frame.x
    tempFrame.y = v.frame.y
    tempFrame.width = v.frame.w
    tempFrame.height = v.frame.h
    
    tempFrame.sourceX = v.spriteSourceSize.x
    tempFrame.sourceY = v.spriteSourceSize.y
    tempFrame.sourceWidth = v.spriteSourceSize.w
    tempFrame.sourceheight = v.spriteSourceSize.h
    
    tempFrame.sourceWidth = 32
    tempFrame.sourceHeight = 32
    
    -- add new frame to frames list
    table.insert(newSheet.sheet.frames, tempFrame)
  end
  
  -- save sheet SIZE
  newSheet.sheet.sheetContentWidth = oldSheet.meta.size.w
  newSheet.sheet.sheetContentHeight = oldSheet.meta.size.h
  
  return newSheet
end

function Globals.loadTable(filename, location)
  local loc = location
  if not location then loc = defaultLocation end

  -- Path for the file to read
  local path = system.pathForFile( filename, loc )

  -- Open the file handle
  local file, errorString = io.open( path, "r" )

  if not file then
      -- Error occurred; output the cause
      print( "File error: " .. errorString )
      return false
  else
      -- Read data from file
      local contents = file:read( "*a" )
      -- Decode JSON data into Lua table
      local t = json.decode( contents )
      -- Close the file handle
      io.close( file )
      -- Return table
      return t
  end
end

function Globals.saveTable( t, filename, location )
    local loc = location
    if not location then loc = defaultLocation end
 
    -- Path for the file to write
    local path = system.pathForFile( filename, loc )
 
    -- Open the file handle
    local file, errorString = io.open( path, "w" )
 
    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
        return false
    else      
        -- Write encoded JSON data to file
        file:write( json.encode( t ) )
        -- Close the file handle
        io.close( file )
        return true
    end
end

function Globals:unlockNextWorldAndReload(dont_reload)
  -- update level counter!
  local saveData = self.map:getSaveData()
  local prevLastLevel = saveData.lastLevel
    
  saveData.lastLevel = math.max(self.nextLevelCampaignIndex + 1, saveData.lastLevel)
  self.map:setSaveData(saveData)

  -- remember where we came from, so we can animate the campaign screen
  self.prevLastLevel = prevLastLevel

  -- now restart to the campaign, if reload is true
  -- otherwise, just end here (we're on a game over screen, user decides whether to continue or not)
  if dont_reload then return end
  
  self.map:restartToCampaign()
end