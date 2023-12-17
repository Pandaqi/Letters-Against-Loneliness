local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")
local adAvailable = false
local lastLevel = false

local all_texts = {
  "When was the last time you went a complete day without looking at your phone?\n\nWould you survive if you didn't have a smartphone for a week?",
  "When was the last time you sent a letter to someone?\n\nCan you think of someone in your life who'd love to receive such a letter?",
  "When was the last time you received a letter?\n\nDid you send a letter back? If not, you can still do so!",
  "Research shows that you're more mindful about what you write if you write it by hand. You also read better when something's printed on paper.\n\nConclusion? Put away the screen sometimes and write/read the old way :)",
  "Do you have a pen pal? Young or old, having someone to talk to about anything, both troubles and happy thoughts, is one of the best ways to leave a healthy and fulfilling life.",
  "Have you been playing for more than 20 minutes? Take a break!\n\nGo outside, stretch your legs, look at something far away to give your eyes a rest!",
  "Can't find the solution to a hard puzzle? Press the Hint button to see the first half of the solution. Or just sleep on it, usually works as well.",
  "Enjoying the game? Check out other games by me (Pandaqi) or give me some feedback at askthepanda@pandaqi.com!",
  "Here's a general tip for this game: think in terms of TRIANGLES.\n\nWhen you place two post offices, place the third one so it forms a triangle, and you'll often get great results.",
  "Here's an idea: write a letter to your best friend, or (secret) lover, or whomever is important to you or could use some encouraging words.\n\nIn this day and age, a nice hand-written letter is sure to brighten anyone's day.",
  "If tomorrow the whole internet disappeared ... what would you do? How would you spend your day?\n\nWith what hobbies would you replace it? How would you 'Google' information?",
  "A general life tip from me: the next time you're about to spend money on the latest, powerful smartphone, spend it on your health instead.\n\nWith the same money, you can buy sports equipment, do activities with loved ones, or send, like, a gazillion letters."
}

local function handleButtonEvent(event)
  local id = event.target.id
  if id == 'continueButton' then
    GLOBALS:unlockNextWorldAndReload()
  
  elseif id == 'adButton' then
    GLOBALS.targetAfterAd = "unlock"
    GLOBALS.admob.show("rewardedVideo")
  end
end

function scene:nextCharacter(obj)
  -- update counter
  obj.splitTextCounter = obj.splitTextCounter + 1
  
  -- update text
  obj.text = obj.splitText[obj.splitTextCounter]
  
  local randBeep = GLOBALS.audio.textbeep[math.random(#GLOBALS.audio.textbeep)]
  local randVolume = math.random()*0.5
  local channel = (obj.splitTextCounter % 32) + 2
  
  local function beepCallback(ev)
    audio.setVolume(1.0, { channel = ev.channel })
  end
  
  if obj.splitTextCounter % 2 == 0 then
    audio.setVolume(randVolume, { channel = channel } )
    audio.play(randBeep, { channel = channel, onComplete = beepCallback })
  end
  
  -- if we've NOT reached the end yet, plan the next event
  if obj.splitTextCounter < obj.splitTextSize then
    local charDelay = 50
    timer.performWithDelay(charDelay, function() scene:nextCharacter(obj) end)
  
  -- otherwise, fire a finished event
  else
    scene:textFinished(obj)
  end
end

function scene:textFinished(obj)
  ----------
  -- Create button for continuing
  -- (if no ad is available, this simply unlocks the next level and returns to the campaign)
  -- (if an ad IS available, this starts the advertisment)
  ----------
  local bs = 2 -- buttonscale
  local bottomMargin = 4
  local buttonOptions = {
      width = 65*bs,
      height = 16*bs,
      id = "continueButton",
      defaultFile = "assets/interface/continueButtonWide.png",
      overFile = "assets/interface/continueButtonWideOver.png",
      onRelease = handleButtonEvent
  }
  
  if adAvailable then buttonOptions.id = 'adButton' end
  if lastLevel then buttonOptions.id = 'continueButton' end
  
  local continueButton = widget.newButton(buttonOptions)
  continueButton.x = display.contentCenterX
  continueButton.y = display.contentCenterY + 480*0.5*0.5 - (16 + bottomMargin)*bs
  scene.view:insert(continueButton)
end

function scene:show(event)
  if event.phase == 'will' then
    -- check if it's an ad or not
    adAvailable = event.params.adAvailable
    lastLevel = event.params.lastLevel
    
    ---------
    -- Create modal/BG
    ---------
    local modal = display.newImageRect(scene.view, 'assets/interface/modalOverlay.png', 320, 480*0.5)
    modal.x = display.contentCenterX
    modal.y = display.contentCenterY
        
    ---------
    -- Display text
    -- (one big title at the top, then body text underneath)
    --------
    local margin = 20
    local headerSize = 32
    
    local headerTextString = 'ASK YOURSELF ...'
    if adAvailable then headerTextString = 'UNLOCK NEW WORLD!' end
    if lastLevel then headerTextString = 'THE END!' end
    
    local textOptionsHeader = {
      parent = scene.view,
      x = modal.x,
      y = modal.y - 480*0.5*0.5 + margin + headerSize,
      text = headerTextString,
      font = GLOBALS.pixelFont,
      fontSize = 32,
      align = 'left',
    }
    

    local textOptionsBody = {
        parent = scene.view,
        x = modal.x,
        y = modal.y + headerSize,
        font = GLOBALS.pixelFont,
        width = 320 - 2*margin,
        height = 480*0.5 - 2*margin - headerSize,
        text = '',
        fontSize = 16,
        align='left'
    } 
    
    local headerText = display.newEmbossedText(textOptionsHeader)
    headerText:setFillColor(54/255.0, 31/255.0, 27/255.0)
        
    local actionCallText = display.newEmbossedText(textOptionsBody)
    actionCallText:setFillColor(54/255.0, 31/255.0, 27/255.0)
    
    -- grab random text from action calls
    local randText = all_texts[math.random(#all_texts)]
    
    -- if an advertisment is available, tell people that
    if adAvailable then
      randText = 'Unlock the next world for free by watching a short advertisment!'
    end
    
    if lastLevel then
      randText = "You've finished the game. Be proud of yourself!\n\nLet me know what you think at askthepanda@pandaqi.com. Or try any of my other games. Or just have a nice day."
    end
    
    -- save text in pieces, for displaying character for character later!
    local textSize = string.len(randText)
    actionCallText.splitText = {}
    actionCallText.splitTextCounter = 1
    actionCallText.splitTextSize = textSize
    for i=1,textSize do
      actionCallText.splitText[i] = string.sub(randText, 1, i)
    end
    
    -- now call this delayed character showing function!
    scene:nextCharacter(actionCallText)
  end
  
end

function scene:hide(event) end
function scene:create(event) end
function scene:destroy(event) end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

