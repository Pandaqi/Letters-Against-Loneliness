return {
  -- this is an array that holds everything we want to display (in sequence/correct order)
  
  ----------
  -- WORLD 1
  ----------
  level1 = {
    { objects = {{ what='text', x = 0, y = -3, text = 'Hey! This is Mark!' }}, delay = 4000 },
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = "He's been feeling a little lonely lately" }}, delay = 6000 },
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = "Why don't we send him a letter?" }}, delay = 6000 },
    { objects = {{ what='text', x = -2, y = -1, width = 9, text = "Click on this tile to place a post office" }}, forcedMove = { x = -1, y = 0, z = 1 } },
    { objects = {{ what='text', x = 2, y = -3, width = 9, text = "Now click here to place another one" }}, forcedMove = { x = 1, y = 0, z = -1 } },
    { objects = {{ what='text', x = 0, y = -3, text = "See what happened?" }}, delay = 3000 },
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = "A letter was sent from the OLD office to the NEW one." }}, delay = 7000 },
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = "It flew past Mark, so he collected it!" }}, delay = 5000 },
  },
  
  level2 = {
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = 'People connect more easily by sharing ...' }}, delay = 3000 },
    { objects = {{ what='text', x = 0, y = -3, width = 9, text = '... by matching each other\'s perspective ...' }}, delay = 3000 },
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = 'That\'s why letters are only sent between post offices ON THE SAME LINE' }}, delay = 7500 },
  },
  
  level3 = {
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = 'To solve each puzzle, send a letter to all people on the board' }}, delay = 7500 },
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = 'But be careful: you only get a limited number of moves' }}, delay = 6000 },
  },
  
  level4 = {
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = 'Got stuck? Just press the "?" button!' }}, delay = 5500 },
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = 'In exchange for watching a short ad ...' }}, delay = 3000, mobileOnly = true },
    { objects = {{ what='text', x = 0, y = -4.5, width = 9, text = '... the computer will show you the correct first moves!' }}, delay = 6500, mobileOnly = true },
  },
  
  ------------
  -- WORLD 2
  ------------
  
  level11 = {
    { objects = {{ what='image', imageName='tutorialMountain' }}, hasButton = true } 
  },
  
  level16 = {
    { objects = {{ what='image', imageName='tutorialForest' }}, hasButton = true } 
  },
  
  ------------
  -- WORLD 3
  ------------
  level26 = {
    { objects = {{ what='image', imageName='tutorialGuard' }}, hasButton = true } 
  },
  
  ------------
  -- WORLD 4
  ------------
  level43 = {
    { objects = {{ what='image', imageName='tutorialBuildingDefault' }}, hasButton = true } 
  },
  
  level50 = {
    { objects = {{ what='image', imageName='tutorialBuilder' }}, hasButton = true } 
  },
  
  ------------
  -- WORLD 5
  ------------
  level63 = {
    { objects = {{ what='image', imageName='tutorialStubborn' }}, hasButton = true } 
  },
  
  level67 = {
    { objects = {{ what='image', imageName='tutorialBuildingRotated' }}, hasButton = true } 
  },
  
  ------------
  -- WORLD 6
  ------------
  level87 = {
    { objects = {{ what='image', imageName='tutorialMover' }}, hasButton = true } 
  },
    
  level93 = {
    { objects = {{ what='image', imageName='tutorialBuildingSwitch' }}, hasButton = true } 
  },
}