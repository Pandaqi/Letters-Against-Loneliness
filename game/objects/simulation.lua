Simulation = Object:extend()

function Simulation:destroy()
  -- pass
end

function Simulation:registerMove(hex)
  table.insert(self.moves, hex)
end

function Simulation:endTurn()
  -- anything we need to register??
  
  -- find next move
  GLOBALS.map:simulateMove()
end

function Simulation:completeSimulation()
  print("SIMULATION DONE! Exhausted all possibilities.")
  
  -- print the best solution
  print("BEST SOLUTION || Length: ", self.bestLength)
  for i=1,self.bestLength do
    local s = self.bestSolution[i]
    print(s.x, s.y, s.z)
  end
end

function Simulation:findNextInSequence()
  -- work backwards from the end
  local maxSquares = #GLOBALS.map.mapList
  local foundRow = false
  for i=self.bestLength,1,-1 do
    -- if we find a row we can increase, do so
    if self.moveIndex[i] < maxSquares then
      self.moveIndex[i] = self.moveIndex[i] + 1
      foundRow = true
      break
    
    -- otherwise, reset each row to starting point
    -- (because, when we do eventually find something, there's a whole range of new possibilities we must all explore)
    else
      self.moveIndex[i] = 1
    end
  end
  
  -- if we found no row to change ...
  if not foundRow then
    -- start searching for solutions with a length that's one higher
    self.bestLength = self.bestLength + 1
    
    print("BUMPED BEST LENGTH TO ", self.bestLength)
    
    -- if this means we've exceeded the max moves, stop!
    if self.bestLength > self.maxMoves then
      return true
    end
  end
  
  return false
end

function Simulation:tryAgain()
  -- find next move index
  local simulationDone = self:findNextInSequence()
  
  -- if simulation is done (all possibilities exhausted) ...
  if simulationDone then
    -- complete it (save results, show them to me, etc.)
    self:completeSimulation()
    return
  end
  
  -- empty current move order
  self.moves = {}
  
  -- destroy map and interface
  GLOBALS.map:destroy()
  GLOBALS.interface:destroy()
  
  -- then recreate them
  -- (and set all the right variables and such)
  GLOBALS.map:new(self.scene)
  GLOBALS.interface:new(self.scene)
  
  self.numSimulations = self.numSimulations + 1

  -- every 100 simulations, take a short pause (to prevent stack overflow) and print update
  if self.numSimulations % 100 == 0 then
    print("SIMULATION COUNT: ", self.numSimulations)
    
    for i=1,#self.moveIndex do
      print("New move indices ", self.moveIndex[i])
    end
    
    -- and start again, but with the next possible move
    timer.performWithDelay(1, function() GLOBALS.map:simulateMove() end)
  else
    GLOBALS.map:simulateMove()
  end
end

function Simulation:completedLevel()
  print("YES! FOUND THE SOLUTION!")
  
  -- Copy the solution into the list of possible solutions
  local copySolution = {}
  for i=1,#self.moves do
    local m = self.moves[i]
    table.insert(copySolution, { m.x, m.y, m.z })
  end
  
  -- Remember how long it is
  self.bestSolution = copySolution
  self.bestLength = #self.moves
  
  -- complete the simulation
  self:completeSimulation()
end

function Simulation:new(scene)
  self.scene = scene
  self.sceneGroup = scene.view
  
  -- initialize variables for keeping track of current game state
  self.moves = {}
  
  local maxMoves = GLOBALS.interface.maxMoves
  
  self.bestSolution = nil
  self.bestLength = 2
  self.maxMoves = maxMoves
  
  -- this variable holds our current move indices
  -- (where key = move, value = index)
  -- we start trying the first thing we find on every turn, but as we hit roadblocks, these are incremented
  -- if all indices are out of range, we've exhausted all possibilities, and should stop
  self.moveIndex = {}
  for i=1,maxMoves do
    self.moveIndex[i] = 1
  end
  
  self.numSimulations = 0
  
  self.knownStates = {}
  
  return self
end