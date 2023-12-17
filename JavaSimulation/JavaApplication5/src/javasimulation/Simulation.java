/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javasimulation;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Queue;

/**
 *
 * @author s148698
 */
class Simulation {
    private ArrayList<GameState> curStateList = new ArrayList<>();

    public GameState solution;
    
    private HashMap hashMap = new HashMap();
    private int curHash = 0;
    private int[][] bitStrings;
    
    public int maxMoves;
    
    public int numStatesExamined = 0;
    
    public int hashCollisions = 0;
    
    public int totalSize;
    public int totalNumCollectibles;
    
    public int[] startingState;

    public boolean heuristicsEnabled = true;
    
    public int[] gatePositions = new int[3];
    
    public boolean reuseState = false;
    public int requireSpecialElement = -1;
    
    /*
     * These variables determine which tile TYPES are included in the simulation
     * NOTE: The existence of some types guarantees the (implicit) existence of other types. 
     *       => If a certain open spot exist, then the possibility of placing a tower there exists as well
    */
    
    public boolean forestEnabled = true;
    public boolean mountainEnabled = true;
    
    // Full range: 37->46
    // Implemented: 37, 38, 39
    public int[] openSpotsEnabled = {};
    
    // Full range: 27->36
    // Implemented: 27, 28, 29 (gates), 30 (enemy?), 31 (default building), 32 (rotated building), 33 (building switch)
    public int[] obstaclesEnabled = {31,32,33};
    
    // Full range: 47->56
    // Implemented: -
    public int[] modifiersEnabled = {};
    
    // Full range: 11->26
    // Implemented: 11 (default), 12,13,14 (guards), 15 (builder), 16 (stubborn), 17 (mover)
    public int[] collectiblesEnabled = {11,12,13,14,15,16,17};
    
    Simulation(int size, int maxMoves) {
        this.maxMoves = maxMoves;
        
        // Determine maximum number of pieces and positions
        // A "piece" is a unique block/state a position can be in
        // Remember, "empty" is one of the states!
        // TO DO: Not all pieces are used within a level; can I bring this back to only the number of pieces used?
        //        Would require changing indices in other locations as well ... might be more trouble than gain
        int pieces = 60;
        
        // The total number of positions on the board
        // TO DO: Certainly not all these will be used; would it be more optimal to only track used positions?
        int positions = (size*2+1)*(size*2+1);
        
        // Initialize the zobrist hashing (just a table of random bitstrings for each piece/position)
        createZobristHashing(pieces, positions);
    }
      
    public void startSimulation(boolean generateOnly) {
        // print + save starting state
        startingState = curStateList.get(0).getState();
        curStateList.get(0).printState();
        
        // print number of collectibles;
        System.out.println("NUMBER OF COLLECTIBLES: " + totalNumCollectibles);
        
        if(generateOnly) {
            return;
        }

        // As long as the state list is NOT empty ...
        while(!curStateList.isEmpty()) {
            // Keep executing the next state
            executeNextState();
        }
    }
    
    public void saveSolution(GameState st) {
        solution = st;
    }
    
    public void addState(GameState st, int hash) {
        // add this state's hash to the map
        hashMap.put(hash, true);
        
        // add the state to the list of states to analyze (on next move)
        curStateList.add(st);
    }
    
    public boolean hashExists(int hash) {
        return hashMap.containsKey(hash);
    }

    
    public void executeNextState() {
        
        // get first state (this means a breadth-first search, because later states get tacked on at the back)
       GameState state = curStateList.remove(0);
       
       // execute it
       boolean shouldTerminate = state.tryAllMoves();
       
       if(shouldTerminate) {
           finishSimulation();
           return;
       }
       
        // For DEBUGGING
        numStatesExamined++;
        if(numStatesExamined % 100 == 0) {
            System.out.println("NUM STATES EXAMINED " + numStatesExamined);
            //System.out.println("CURRENT NUMBER OF MOVES " + state.movesList.size() );
            System.out.println("CURRENT LIST SIZE " + curStateList.size() );
        }
        
       
       // if state list is empty, we've exhausted all states and should finish simulation
       if(curStateList.isEmpty()) {
           finishSimulation();
           return;
       }
    }
    
    public void finishSimulation() {
        // clear the state list
        // (both to clear memory AND to terminate the simulation)
        curStateList.clear();
        
        // notify myself the simulation is done
        System.out.println(" === SIMULATION DONE === ");
        System.out.println("Hash Collisions: " + hashCollisions);
        
        // Print simulation results!
        if(solution != null) {
            solution.printState();
            
            /*
            // DEBUGGING: Print state of all nodes
            GameState node = solution;
            while(node != null) {
                node.printState();
                node = node.getParent();        
            }
            */
            
            JavaSimulation.solutionFound  = true;
        } else {
            System.out.println("NO SOLUTION :(");
        }
        
    }
    
    
    
    /*
     * ZOBRIST HASHING
    
     * URL (Wikipedia Explanation): https://en.wikipedia.org/wiki/Zobrist_hashing
     * URL (Java Implementation): https://github.com/avianey/bitboard4j/blob/master/bitboard4j/src/main/java/fr/avianey/bitboard4j/hash/ZobristHashing.java
    */
    
    /**
     * Initialize values for the given number of pieces and the given number of positions
     * @param pieces
     * @param positions
     */
    public void createZobristHashing(int pieces, int positions) {
        bitStrings = new int[pieces][positions];
        for (int i = 0; i < pieces; i++) {
            for (int j = 0; j < positions; j++) {
                bitStrings[i][j] = (int) (((long) (Math.random() * Long.MAX_VALUE)) & 0xFFFFFFFF);
            }
        }
    }
    
    // Convert the given state completely to a new hash
    public int convertStateToHash(GameState st) {
        // clear hash
        int tempHash = 0;
        
        int size = (int) Math.floor(totalSize/2);
        int[] state = st.getState();
        
        // loop through state
        for(int i = 0; i < state.length; i++) {
            int curVal = state[i];
                    
            // if there is SOMETHING here ...
            if(curVal != 0) {
                // add that "piece" (value in grid) to the hash
                // at the right position
                addToHash(tempHash, curVal, i);
            }
        }
        
        return tempHash;
    }
    
    public int removeFromHash(int hash, int piece, int position) {
        return xor(hash, piece, position);
    }
    
    public int addToHash(int hash, int piece, int position) {
        return xor(hash, piece, position);
    }
    
    public int xor(int hash, int piece, int position) {
        hash = hash ^ bitStrings[piece][position];
        return hash;
    }
}
