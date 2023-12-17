/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javasimulation;

import java.util.Arrays;

/**
 *
 * @author s148698
 */
public class JavaSimulation {
    
    public static Simulation sim;
    public static boolean solutionFound = false;

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        int size = 3;
        int maxMoves = 10;
        boolean generateOnly = false;
        
        int requireSpecialElement = 33;
        int totalNumCollectibles = 0;
        String oldSolution = "";
        GameState reuseState = null;
        
        // Continue trying new levels, until we find one with a succesfull solution
        while(!solutionFound) {
            // Create simulation
            sim = new Simulation(size, maxMoves);
            
            System.out.println("Stage 1");
            
            if(reuseState != null) {
                System.out.println("REUSE STATE SIZE BEGIN " + reuseState.getState().length);
            }
                    
            // Create game board
            // (re-use previous board if I want to check something)
            GameState gameBoard;
            if(reuseState != null) {
                // Add ourselves to the simulation (as the first state)
                sim.addState(reuseState, reuseState.hash);
                
                gameBoard = reuseState;
                sim.reuseState = true;
                sim.requireSpecialElement = requireSpecialElement;
                sim.totalNumCollectibles = totalNumCollectibles;
                sim.totalSize = reuseState.getTotalSize();
            } else {
                gameBoard = new GameState(size);
                sim.reuseState = false;
            }
            
            System.out.println("Stage 2");

            // Start simulation
            sim.startSimulation(generateOnly);
            
            System.out.println("Stage 3");
            
            // If we only want to generate A level, don't continue simulation
            if(generateOnly) {
                solutionFound = true;
            }
            
            // If the level is not interesting enough, continue
            if(sim.solution != null && !sim.solution.isInteresting()) {
                solutionFound = false;
            }
            
            // If we found a solution, but we REQUIRE a special element be used,
            // Try the same level again but without the special powers, and see if it is solvable
            if(reuseState == null) {
                if(solutionFound && requireSpecialElement > 0) {
                    // copy the original starting state
                    int[] copyArr = new int[JavaSimulation.sim.startingState.length];
                    for(int i = 0; i < copyArr.length; i++) {
                        copyArr[i] = JavaSimulation.sim.startingState[i];
                    }
                    
                    System.out.println("ORIGINAL STARTING STATE ");
                    System.out.println(Arrays.toString(copyArr));
                    
                    // Save that initial state of this simulation (to re-use the next time)
                    reuseState = new GameState(copyArr);
                    totalNumCollectibles = JavaSimulation.sim.totalNumCollectibles;
                    
                    solutionFound = false;
                    
                    System.out.println("MAYBE I FOUND A STATE; REUSING IT");
                }
            } else {
                // if the re-use was ALSO succesful, the state is useless
                // because it doesn't actually USE the elements we want it to use.
                if(sim.solution != null) {
                    solutionFound = false;
                } else {
                    solutionFound = true;
                    
                    System.out.println("YES! WE HAVE A WINNER! (Check previous solution.)");
                }
                
                // if this was already a re-use, just set this variable to null
                // if the re-use passes, the level is valid and should be returned automatically
                reuseState = null;
            }
            
            if(reuseState != null) {
                System.out.println("REUSE STATE SIZE END " + reuseState.getState().length);
            }
            
            
            
            System.out.println("Stage 4");
        }
    }
    
}
