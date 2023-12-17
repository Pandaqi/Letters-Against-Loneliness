/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javasimulation;

import java.util.ArrayList;
import java.util.Random;

import dk.ilios.asciihexgrid.*;
import dk.ilios.asciihexgrid.printers.*;
import java.util.Arrays;
import java.util.Collections;
import org.json.JSONObject;



/**
 *
 * @author s148698
 */
class GameState {
    
    private GameState parent;
    
    private int[] state;
    public int hash;
    
    private int totalSize;
    private int numCollected;
    
    private int letterMoveDir = 1;
    private int move = -1;
    public int tower;
    public int numEmptySpots = 0;
    
    public ArrayList<Integer> specialElementsUsed = new ArrayList<>();
    
    ArrayList<Integer> emptySpots;
    
    // Constructor for creating the INITIAL LEVEL
    // (Only used once; otherwise the constructor below is used to create a DERIVED game state)
    GameState(int size) {
        // Generate the first level
        this.generateLevel(size);
        
        // Generate first emptySpots array
        emptySpots = new ArrayList<>(); 
        for(int x = 0; x < state.length; x++) {
            if(isAvailable(state[x])) {
                emptySpots.add(x);
            }
        }
        
        // remember how many empty spots we had
        numEmptySpots = emptySpots.size();
        
        // Hash the level
        hash = JavaSimulation.sim.convertStateToHash(this);
        
        tower = -1;
        
        // Add ourselves to the simulation (as the first state)
        JavaSimulation.sim.addState(this, hash);
    }
    
    // Constructor for creating a new GameState that is an identical copy of an old one (given the state int[] array)
    GameState(int[] oldState) {
        totalSize = JavaSimulation.sim.totalSize;
        
        // deep copy map into state
        // AND generate first emptySpots array
        state = new int[oldState.length];
        emptySpots = new ArrayList<>(); 
        for(int x = 0; x < state.length; x++) {
            if(isAvailable(oldState[x])) {
                emptySpots.add(x);
            }
            
            state[x] = oldState[x];
        }
        
        System.out.println("WOOW MY OLD STATE SIZE " + state.length);
        
        numCollected = 0;
        tower = -1;
        
        // remember how many empty spots we had
        numEmptySpots = emptySpots.size();
        
        // Hash the level
        hash = JavaSimulation.sim.convertStateToHash(this);
    }
    
    // Constructor for creating a state from a previous state
    GameState(GameState parent, int numCollected, int hash, int letterMoveDir, int[] oldState) {
        this.parent = parent;
        this.numCollected = numCollected;
        this.hash = hash;
        this.letterMoveDir = letterMoveDir;
        
        totalSize = JavaSimulation.sim.totalSize;
        
        // create empty state array
        state = new int[totalSize*totalSize];
        emptySpots = new ArrayList<>();
                
        // In this case, we need to deep copy the state
        // TO DO: Find more optimized way to do this
        for(int x = 0; x < state.length; x++) {
            // as we're copying, also check for empty spots
            if(isAvailable(oldState[x])) {
                emptySpots.add(x);
            }
            
            state[x] = oldState[x];
        }
                
        // remember how many empty spots we had
        numEmptySpots = emptySpots.size();
    }
    
    /*
     * This function tries all moves (all empty spots on the current board)
     */
    
    public boolean tryAllMoves() {
        // loop through all available moves
        boolean shouldTerminate = false;
        for(int i = 0; i < emptySpots.size(); i++) {
            // Copy our current game state to a new one
            // Transfer ...
            //  -> Number collected
            //  -> List of MOVES made until now
            //  -> List of EMPTY SPOTS on the map, currently
            //  -> The HASH of the current game state
            //  -> The actual game state            
            GameState newState = new GameState(this, numCollected, hash, letterMoveDir, state);

            // Execute the right move on this new game state
            shouldTerminate = newState.executeMove( emptySpots.get(i) );
            
            // If this move means the end of the simulation, break here
            if(shouldTerminate) { break; }
        }
        
        // clear emptySpots array (we'll never need it again)
        emptySpots = null;
        
        return shouldTerminate;
    }
    
    /*
     * This function executes a single, specific move
     * @parameter hex = (x,y,z) location where a tower will be placed
     */
    
    private boolean executeMove(int movePos) {
        // Get the corresponding move (and remove it from array list as well)
        move = movePos;
        int curVal = state[move];
        
        if(!isAvailable(curVal)) {
            System.out.println("ERROR! Tried to place tower at unavailable location");
            return false;
        }

        
        /*
         * Execute effects of this tower
         */
        
        int towerToPlace = 5;
        
        // If this is an open spot, determine which tower to place
        if(isOpenSpot(curVal)) {
            towerToPlace = (curVal - 37 + 1) + 5;
        }
        
        // place tower at this location
        changePosition(move, curVal, towerToPlace);
        tower = move;
        
        // Add this move to our moves list
        int size = (int) Math.floor(totalSize / 2);
        int x = move % totalSize;
        int y = (move - x) / totalSize;
        int z = 3*size - x - y;

        // Reconstruct some variables
        // 1) How many moves we made
        // 2) List of all towers
        GameState node = this.parent;
        int numMoves = 1; // include this move
        ArrayList<Integer> towerList = new ArrayList<>();
        while(node != null) {
            numMoves++;
            if(node.tower >= 0) {
                towerList.add(node.tower);
            }
            node = node.parent; 
        }
        
        ArrayList<int[]> capitolLetters = new ArrayList<>();
        int switchBuildingsHit = 0;
        
       
        // move letters to all adjacent towers
        for(int t = 0; t < towerList.size(); t++) {
            int tempTower = towerList.get(t);
            
            // get the location of the tower
            int tX = tempTower % totalSize;
            int tY = (tempTower - tX) / totalSize;
            int tZ = 3*size - tX - tY;
            
            // get the type of tower
            int towerType = state[tempTower];
            
            // if the towers are NOT on the same line, continue
            if(!(x == tX || y == tY || z == tZ)) {
                continue;
            }

            //                
            // send a letter!
            // NOTE: We move FROM the old tower TO the new tower
            // (unless direction is reversed, of course)
            //

            // keep track of position + moving direction
            int copyX = tX, copyY = tY, copyZ = tZ;
            int targetX = x, targetY = y, targetZ = z;
            int steps = (int) Math.round(0.5*(Math.abs(tX - x) + Math.abs(tY - y) + Math.abs(tZ - z)));

            // if we move in reverse, use the end positions instead
            if(letterMoveDir == -1) {
                copyX = x;
                copyY = y;
                copyZ = z;

                targetX = tX;
                targetY = tY;
                targetZ = tZ;
            }

            // some special elements are not directly useful => they are only useful if they lead to something better
            // therefore, we keep track of "delayed special elements", and only apply them if they were useful
            ArrayList<Integer> buildingsHit = new ArrayList<>();
            ArrayList<Integer> delayedSpecialElementsUsed = new ArrayList<>();

            int dirX = (targetX-copyX) / steps, dirY = (targetY-copyY) / steps, dirZ = (targetZ-copyZ) / steps;
            int flatPos = -1;

            boolean doneMoving = false;
            boolean applyDelayed = false;

            // while we should keep moving 
            // (not arrived yet, special letter, whatever)
            while(!doneMoving) {
                // take another step
                copyX += dirX;
                copyY += dirY;
                copyZ += dirZ;

                // get value here
                // (if we're outside of range, break immediately)
                // we do a rudimentary check: anything outside flatPos cannot work, anything for which not x+y+z==0 cannot work
                flatPos = copyX + copyY*totalSize;
                if(flatPos >= state.length || flatPos < 0) { break; }
                if((copyX + copyY + copyZ) != 3*size) { break; }
                if(Math.abs(copyX-size) > size || Math.abs(copyY-size) > size || Math.abs(copyZ-size) > size) { break; }

                int val = state[flatPos];
                doneMoving = false;

                // If this is a state re-use, we must turn off certain special elements
                if(JavaSimulation.sim.reuseState) {
                    if(val == JavaSimulation.sim.requireSpecialElement) {
                        // still record this thing
                        specialElementsUsed.add(val);

                        // but don't do anything else
                        doneMoving = true;
                        break;
                    }
                }

                // if it's a collectible ...
                if(isCollectible(val)) {
                    // collect it
                    numCollected++;

                    // record it in special elements
                    // NOTE: We subtract collectibles when calculating ratio, as they need to be collected anyway
                    specialElementsUsed.add(val);

                    // by default, replace tile with standard grass
                    int replacementVal = 2;

                    // if it's a builder, replace with a (default) building
                    if(val == 15) {
                        replacementVal = 31;

                    // if it were stubborn people, replace with regular collectible
                    } else if(val == 16) {
                        replacementVal = 11;
                        numCollected--;

                    // if it's a mover, replace with empty land
                    } else if(val == 17) {
                        replacementVal = 0;
                    }

                    changePosition(flatPos, val, replacementVal);

                    // if it was a guard ... also remove the corresponding gate
                    if(isGuard(val)) {
                        // get gate position (from simulation object?)
                        int gatePos = JavaSimulation.sim.gatePositions[(val-12)];

                        // chagne position
                        changePosition(gatePos, state[gatePos], 2);
                    }

                    // stop letter (unless it came from an endless tower)
                    if(towerType != 7) {
                        doneMoving = true;
                    }

                    applyDelayed = true;

                // if it's a forest ... break it
                } else if(val == 3) {
                    changePosition(flatPos, 3, 2);

                    if(towerType != 7) {
                        doneMoving = true;
                    }

                    // record special element
                    specialElementsUsed.add(val);

                    applyDelayed = true;

                // if it's an enemy, you lose immediately!
                } else if(val == 30) {
                    // record special element
                    specialElementsUsed.add(val);

                    return true;

                // if it's a building, reflect the letter back
                } else if(val == 31) {
                    delayedSpecialElementsUsed.add(val);

                    // if we already hit this building, break out of here
                    // otherwise, record hitting this building
                    if(buildingsHit.contains(flatPos)) {
                        break;
                    }
                    buildingsHit.add(flatPos);

                    dirX *= -1;
                    dirY *= -1;
                    dirZ *= -1;

                    //System.out.println("Using building" + dirX + dirY + dirZ);
                    //System.out.println(" => " + copyX + copyY + copyZ);

                // if it's a ROTATED building, reflect letter back at angle
                } else if(val == 32) {
                    delayedSpecialElementsUsed.add(val);

                    if(buildingsHit.contains(flatPos)) {
                        break;
                    }
                    buildingsHit.add(flatPos);

                    // push z to the front (in vector; the rest pushes back)
                    // (to rotate, we invert the vector, but it was alread inverted because of the mirror, so we just stay as we are!)
                    int tempZ = dirZ;
                    dirZ = dirY;
                    dirY = dirX;
                    dirX = tempZ;

                // if it's a building switch, switch the direction (and stop moving)
                } else if(val == 33) {
                    specialElementsUsed.add(val);
                    switchBuildingsHit++;
                    doneMoving = true;

                // otherwise ...
                // if it's NOT an empty/passable tile, it must be an obstacle ...
                } else if(!isPassable(val)) {
                    // record special element
                    // (should we record this as well??)
                    specialElementsUsed.add(val);

                    doneMoving = true;
                }

                // if we've arrived at our target tower, stop moving
                // TO DO: Ideally, I'd check flatPos != tempTower, but somehow that doesn't work properly? 
                boolean reachedTargetTower = (copyX == targetX && copyY == targetY && copyZ == targetZ);                                        
                if(isTower(val) && reachedTargetTower) {
                    if(towerType != 7) {
                        doneMoving = true;
                    } else {
                        // record special element ( = using that special tower)
                        specialElementsUsed.add(towerType);
                    }
                }

                // if this is a HEIGHTENED tower ...
                if(towerType == 6) {
                    // we don't stop, unless it's a collectible or water
                    if(val != 0 && !isCollectible(val)) {
                        doneMoving = false;

                        // record special element
                        specialElementsUsed.add(towerType);
                    }
                }

                // if we should stop moving, STOP! (Break out of loop)
                if(doneMoving) {
                    break;
                }
            }

            // if we have delayed special elements to apply, do so
            if(applyDelayed) {
                for(Integer elem : delayedSpecialElementsUsed) {
                    specialElementsUsed.add(elem);
                }
            }

            // once our letter has arrived somewhere, check if it's a capitol
            if(flatPos >= 0 && flatPos < state.length) {
                if(state[flatPos] == 8) {
                    // if so, register it in the list of capitol letters
                    // (first three indices: center position, last three indices: relative vector)
                    capitolLetters.add(new int[]{copyX, copyY, copyZ, -dirX, -dirY, -dirZ});

                    // record special element
                    specialElementsUsed.add(8);
                }
            }
        }
        
        /*
         * TOWN MANAGEMENT
         * If we received capitol letters, grow the cities
        */
        if(capitolLetters.size() > 0){
            System.out.println("Capitol Letters " + capitolLetters.size());
        }
        for(int l = 0; l < capitolLetters.size(); l++) {
            // grab letter
            int[] letter = capitolLetters.get(l);
            
            // the relative vector should be the direction, but reversed
            // luckily, that's exactly what I save in this list :p
            
            // try all locations around center hexagon
            int numRotations = 0;
            boolean validPlacement = true;
            boolean outOfBounds = false;
            int[] oldLoc = {letter[3], letter[4], letter[5]};
            int flatPos = (letter[0] + oldLoc[0]) + (letter[1] + oldLoc[1])*totalSize;
            while(outOfBounds || !isAvailable(state[flatPos])) {
                // rotate RELATIVE location
                int[] newLoc = new int[3];
                for(int loc = 0; loc < 3; loc++) {
                    newLoc[loc] = -oldLoc[(loc+3-1)%3];
                }
                
                // get ABSOLUTE flat pos
                flatPos = (letter[0]+newLoc[0]) + (letter[1]+newLoc[1])*totalSize;
                
                // save the new location (for the next iteration, if it comes
                oldLoc = newLoc;
                
                // and keep track of the number of rotations
                numRotations++;
                if(numRotations >= 6) {
                    validPlacement = false;
                    break;
                }
                
                                            
                // if this location doesn't exist (probably outside grid/border),
                // reset to previous flat pos,
                // and then just continue
                outOfBounds = false;
                if(flatPos < 0 || flatPos >= state.length) {
                    outOfBounds = true;
                }
            }
            
            // if we find a valid placement, place the building!
            // (default building = 31 for now)
            if(validPlacement) {
                System.out.println("Placing a building! Relative vector: " + oldLoc[0] + " || " + oldLoc[1] + " || " + oldLoc[2]);
                
                changePosition(flatPos, state[flatPos], 31);
            }
            
        }
        
        // once all letters have been sent, check if movement direction needs to be switched
        if(switchBuildingsHit > 0) {
            letterMoveDir *= ((switchBuildingsHit-1) % 2)*2 - 1;
        }
        

        /*
         * check what to do with this tree branch
        */
        
        // Check against other hashes
        if(JavaSimulation.sim.hashExists(hash)) {
            JavaSimulation.sim.hashCollisions++;
            // If it already exists, no need to search this part of the tree any further
            return false;
        }
        
        // If we collected everything, stop simulation and remember the solution!
        if(numCollected >= JavaSimulation.sim.totalNumCollectibles) {
            // Terminate simulation
            JavaSimulation.sim.saveSolution(this);
            return true;
        }
        
        // If we have no moves left, stop!
        // (Don't insert this state to be examined further)
        if(emptySpots.size() <= 0) {
            return false;
        }
        
        // HEURISTICS: Discard potential solutions to find ANY solution faster
        // Can be turned on/off
        if(JavaSimulation.sim.heuristicsEnabled) {
            // If this is a very un-promising branch, stop here!
            // (What's un-promising? If our collection ratio is worse than 1 collectible per 2 moves
            if( numMoves > 3 && ( (float) numCollected / numMoves ) < (1.0/2.0)) {
                return false;
            }
        }
        
        // If we are above turn limit, stop!
        if(numMoves >= JavaSimulation.sim.maxMoves) {
            return false;
        }
        
        
     
        // If this is still a promising branch, insert it into the simulation queue
        // Also insert its hash
        JavaSimulation.sim.addState(this, hash);
        
        return false;
    }
    
    private void changePosition(int pos, int oldVal, int newVal) {
        // update grid
        state[pos] = newVal;

        // update hash as well
        hash = JavaSimulation.sim.removeFromHash(hash, oldVal, pos);
        hash = JavaSimulation.sim.addToHash(hash, newVal, pos);

        // if the old value was NOT available,
        // but the newValue IS available, add to empty spots
        if(!isAvailable(oldVal) && isAvailable(newVal)) {
            emptySpots.add(pos);
        } 
        
        // the reverse of the above: 
        // old value IS available,
        // but new value is NOT available,
        // remove from empty spots
        if(isAvailable(oldVal) && !isAvailable(newVal)){
            emptySpots.remove(Integer.valueOf(pos));
        }
    }
    
    private boolean isCollectible(int val) {
        // (11,26) is the integer range for all collectibles
        return (val >= 11 && val <= 26);
    }
    
    private boolean isPassable(int val) {
        // 0 = water/nothing
        // (3,4) = forest/mountain
        // 8 = capitol (exception; only tower not passable?)
        // (27,36) = obstacles
        return !(val == 0 || val == 3 || val == 4 || val == 8 || (val >= 27 && val <= 36));
    }
    
    private boolean isAvailable(int val) {
        // (1,2) = grass and beach
        // (37,46) = open spots
        return (val == 1 || val == 2 || (val >= 37 && val <= 46) );
    }
    
    private boolean isTower(int val) {
        return (val >= 5 && val <= 10);
    }
    
    private boolean isGuard(int val) {
        return (val >= 12 && val <= 14);
    }
    
    private boolean isGate(int val) {
        return (val >= 27 && val <= 29);
    }
    
    private boolean isOpenSpot(int val) {
        return (val >= 37 && val <= 46);
    }

    private void generateLevel(int size) {
        // initialize empty array(s)
        totalSize = 2*size + 1;
        state = new int[totalSize*totalSize];
        
        // create RNG
        Random rand = new Random();
        
        // grab perlin noise + seed it
        // Parameters:
        // 1) seed = random seed to use during calculation
        // 2) persistence = how quickly amplitudes diminish for subsequent octaves (HIGHER = ROUGHER NOISE)
        // 3) frequency = basically, how wildly the noise fluctuates => period = 1/f = determines the size of oceans/forests
        // 4) Amplitude = which range (-a, a) the values fall into
        // 5) Octaves = how many noise layers to overlay to get final value
        //
        // URL with Explanation: http://libnoise.sourceforge.net/glossary/#frequency
        Perlin p = new Perlin(rand.nextInt(1000000), 0.5, 4, 7, 3);

        
        
        // fill a hexagon with randomly generated terrain
        int emptyLocations = 0;
        for(int x = 0; x < totalSize; x++) {
            for(int y = 0; y < totalSize; y++) {
                for(int z = 0; z < totalSize; z++) {
                    if((x + y + z) == 3*size) {
                        // convert location to (x,y) coordinates
                        // (otherwise, we sample perlin noise with the "wrong"/skewed coordinates)
                        double realX = 1.5 * x;
                        double realY = Math.sqrt(3)*0.5 * x + Math.sqrt(3) * z;
                        double height = p.getHeight(realX, realY);
  
                        int randVal;
                        if(height > 3) {
                            // mountains
                            randVal = 4;
                        } else if(height > 2) {
                            // forest
                            randVal = 3;
                        } else if(height >= 0) {
                            // grass land
                            randVal = 2;
                            emptyLocations++;
                        } else if(height > -1) {
                            // beach
                            randVal = 1;
                            emptyLocations++;
                        } else {
                            // water
                            randVal = 0;
                        }
                        
                        // mountain chosen, but no mountain is available? push down to forest
                        if(randVal == 4 && !JavaSimulation.sim.mountainEnabled) {
                            randVal = 3;
                        }
                        
                        // forest chosen, but not forest is available? push down to grass
                        if(randVal == 3 && !JavaSimulation.sim.forestEnabled) {
                            randVal = 2;
                        }

                        int flatPos = x + y*totalSize;
                        state[flatPos] = randVal;
                    }
                }
            }
        }
        
        // Now that we have the terrain, add other stuff to it
        // To make sure we always get a reasonable number + good distribution,
        // we first create an array with everything we want, and then place those randomly
        int totalNumCollectibles = rand.nextInt(6) + 2;
        int[] collEnab = JavaSimulation.sim.collectiblesEnabled;
        ArrayList<Integer> wantedValues = new ArrayList<>();
     
        for(int i = 0; i < totalNumCollectibles; i++) {
            int randInd = rand.nextInt(collEnab.length);
            int randType = collEnab[randInd];
            wantedValues.add(randType);
            
            // If this is a GUARD (12,13,14)
            if(isGuard(randType)) {
                // Also insert a GATE (27,28,29)
                // (the corresponding one, of course
                wantedValues.add((randType - 12) + 27);
                
                // And remove this collectible; replace with default one
                collEnab[randInd] = 11;
            }
        }
        
        // If obstacles are enabled => add them as well!
        int[] obstEnab = JavaSimulation.sim.obstaclesEnabled;
        if(obstEnab.length > 0) {
            int totalNumObstacles = rand.nextInt(3) + 1;

            for(int i = 0; i < totalNumObstacles; i++) {
                int randInd = rand.nextInt(obstEnab.length);
                int randType = obstEnab[randInd];
                wantedValues.add(randType);
            }
        }
        
        // If open spots are enabled => add them as well!
        int[] spotsEnab = JavaSimulation.sim.openSpotsEnabled;
        if(spotsEnab.length > 0) {
            int totalNumSpots = rand.nextInt(3) + 1;
            
            for(int i = 0; i< totalNumSpots; i++) {
                int randInd = rand.nextInt(spotsEnab.length);
                int randType = spotsEnab[randInd];
                wantedValues.add(randType);
            }
        }
        
        // TO DO: Add modifiers, if they exist
        
        System.out.println("Empty Spots " + emptyLocations);
        System.out.println("Objects wanted to place " + wantedValues.size());
        

        // Finally, go through the list of all values we want to add
        for(int i = 0; i < wantedValues.size(); i++) {
            // Keep picking random locations until we find one that's available
            // (For now, that is any grass or beach land.)
            int wantedLocation;
            boolean locationAllowed;
            int newValue = wantedValues.get(i);
            int numTries = 0;
            do {
                wantedLocation = rand.nextInt(state.length);
                
                // default to true => but set to false on exceptions listed below
                locationAllowed = true;
                
                // check if this location is open for placement
                // which means: it's an empty grass/beach square
                if(state[wantedLocation] == 0 || state[wantedLocation] > 2) {
                    locationAllowed = false;
                    continue;
                }
                
                // If we've already tried thirty times, just take the best we can get
                // TO DO: Might just give up on this level entirely, as the chance of recovering something is low at this point
                if(numTries > 30) {
                    break;
                }
                
                // Collectibles can't go at the corners; makes unsolvable levels
                // Also don't place gates at corners; it's illogical (nothing to obstruct in a corner)
                // And don't place enemies at corners
                if(isCollectible(newValue) || isGate(newValue) || newValue == 30) {
                    int x = wantedLocation % totalSize;
                    int y = (wantedLocation - x) / totalSize;
                    int z = 3*size - x - y;
                    
                    if((Math.abs(x-size) + Math.abs(y-size) + Math.abs(z-size)) == 2*size) {
                        locationAllowed = false;
                    }
                }
                
                numTries++;
                
                //System.out.println("Trying to find location for " + newValue);
                
            } while(!locationAllowed);
            
            // Once we found a location, place the thing there
            state[wantedLocation] = newValue;
            
            // If we place a GATE, save its location for quick access during simulation
            if(isGate(newValue)) {
                JavaSimulation.sim.gatePositions[(newValue-27)] = wantedLocation;
            }
            
            // remember we have one less epmty location
            // and if this was the last one, break out of the loop6
            emptyLocations--;
            if(emptyLocations <= 0) {
                break;
            }
        }
        
        JavaSimulation.sim.totalSize = totalSize;
        JavaSimulation.sim.totalNumCollectibles = totalNumCollectibles;
    }
    
    public int[] getState() {
        return state;
    }
    
    public int getTotalSize() {
        return totalSize;
    }
    
    public GameState getParent() {
        return parent;
    }
    
    public boolean isInteresting() {
        // all variables for keeping track of specific elements
        int numForestsUsed = 0;
        int numGatesUsed = 0;
        int numGuardsUsed = 0;
        int numBuildingsUsed = 0;
        int numStubbornUsed = 0;
        int numRotatedBuildingsUsed = 0;
        int numMoversUsed = 0;
        int numSwitchUsed = 0;
        
        int numMoves = 0;
        int numSpaces = 0;
        int numSpecialElementsUsed = 0;
        
        GameState node = this;
        while(node != null && node.move >= 0) {
            // count total number of moves
            numMoves++;
            
            // do stuff with this node
            numSpecialElementsUsed += node.specialElementsUsed.size();
            
            // OPTIONAL: CHeck for the existence of specific elements
            // Number of forests used?
            for (Integer elUsed : node.specialElementsUsed) {
                if(elUsed == 3) {
                    numForestsUsed++;
                } else if(isGate(elUsed)) {
                    numGatesUsed++;
                } else if(isGuard(elUsed)) {
                    numGuardsUsed++;
                } else if(elUsed == 31) {
                    numBuildingsUsed++;
                } else if(elUsed == 16) {
                    numStubbornUsed++;
                } else if(elUsed == 32) {
                    numRotatedBuildingsUsed++;
                } else if(elUsed == 17) {
                    numMoversUsed++;
                } 
                
                // we only count the switch if there are at least X moves after it
                // otherwise, it wouldn't have had time to have an effect
                if(elUsed == 33 && numMoves >= 3) {
                    numSwitchUsed++;
                }
            }
            
            // count number of possible moves/open spaces at each stage
            numSpaces += node.numEmptySpots;
            
            // continue with parent
            node = node.parent;        
        }
        
        // METRIC #1: Number of options/possible moves per move (average)
        double numSpacesPerMove = (numSpaces + 0.0) / numMoves;
        
        // METRIC #2: Number of moves (numMoves)
        // METRIC #3: Size of board (totalSize)
        // METRIC #4: Number of collectibles
        int numCollectibles = JavaSimulation.sim.totalNumCollectibles;
        
        // METRIC #5: Number of special elements
        // (counted from the initial state)
        int numSpecialElements = 0;
        int[] ss = JavaSimulation.sim.startingState;
        for(int x = 0; x < ss.length; x++) {
            if(ss[x] > 2) {
                numSpecialElements++;
            }
        }
        
        // METRIC #6: Computer search time
        // (if the computer had to search more states/take more time, it's most likely harder to solve this level)
        int numStatesExamined = JavaSimulation.sim.numStatesExamined; // more states = more difficult level
        int hashCollisions = JavaSimulation.sim.hashCollisions; // more hash collisions = bad, as everything leads to the same board state
        
        // METRIC #7: How many special elements were used (numSpecialElementsUsed)
        
        // ACTUALLY USE THE METRICS to create a formula/cutoff for interestingness
        double finalMetric = numStatesExamined / (hashCollisions+1.0)*10 
                + numCollectibles 
                + numSpacesPerMove
                + numMoves
                + totalSize
                + numSpecialElements
                + (numSpecialElementsUsed / (numSpecialElements+1.0))*10;
        
        System.out.println(numStatesExamined / (hashCollisions+1.0)*10
                + " || " + numCollectibles 
                + " || " + numSpacesPerMove 
                + " || " + numMoves 
                + " || " + totalSize 
                + " || " + numSpecialElements
                + " || " + (numSpecialElementsUsed / (numSpecialElements+1.0))*10);
        System.out.println("INTERESTINGNESS? " + finalMetric);
        
        // IMPORTANT OBSERVATION:
        // Creating a single formula does not seem to hold much merit.
        // Instead, a good level usually has many special elements + uses them!
        // Additionally, because the game is built from a campaign (with new mechanics introduced),
        // it's good to check for these elements specifically (like "number of forests used must be greater than 2")
        
        double fractionElementsUsed = ((numSpecialElementsUsed - numCollectibles) / (numSpecialElements-numCollectibles+1.0));
        
        // at least two special elements
        // and at least half of the special elements (excluding collectibles) used
        return (numSpecialElements >= numCollectibles + 2 && fractionElementsUsed >= 0.5 && numSwitchUsed >= 1);

        /*
        if(numGuardsUsed >= 2 && numGatesUsed >= 2) {
            return true;
        } else {
            return false;
        }  */
        
        //return (numSwitchUsed >= 1);
    }
    
    public void printState() {
        // Reconstruct the moves we took
        // (starting with our own)
        GameState node = this;
        ArrayList<int[]> movesList = new ArrayList<>();
        int size = (int) Math.floor(totalSize / 2);
        while(node != null && node.move >= 0) {
            int tempMove = node.move;
            
            int x = tempMove % totalSize;
            int y = (tempMove - x) / totalSize;
            int z = 3*size - x - y;
            
            int[] pos = new int[]{x-size, y-size, z-size};
            
            movesList.add(pos);
            node = node.parent;        
        }
        
        // Reverse list (so we start with first move)
        Collections.reverse(movesList);
        
        // Use a pretty printer to get an actual hexagon board
        AsciiBoard board = new AsciiBoard(0, totalSize, 0, totalSize, new SmallFlatAsciiHexPrinter());
        
        //board.printHex("HX1","-B-", '#', 0, 0);
        //board.printHex("HX2","-W-", '+', 1, 0);
        //board.printHex("HX3","-W-", '-', 2, 0);
        //board.printHex("HX3","-B-", '•', 2, 1);
        
        for(int i = 0; i < state.length; i++) {
            int value = state[i];

            if(value != 0) {
                int x = i % totalSize;
                int y = (i - x) / totalSize;
                int z = 3*size - x - y;
                
                board.printHex(Integer.toString(value), "?", ' ', x, z);
                // System.out.println((x - size) + " | " + (y - size) + " | " + (z - size) + " >> " + value);
            }
        }
        
        // Actually print this shit
        System.out.println(board.prettPrint(true)); // supposed to be "prettyPrint", author made a typo probs
        
        // Turn into JSON
        JSONObject jo = new JSONObject();
        jo.put("level", JavaSimulation.sim.startingState);
        jo.put("mapSize", size);
        jo.put("solution", movesList);
        
        System.out.print("\"" + Integer.toString(hash) + "\"" + ": ");
        System.out.print(jo);
        //System.out.println("letterMoveDir: " + this.letterMoveDir);
        System.out.println();
        
    }
    
}
