**Computer-generated puzzles**

**Part 1: Naïve algorithms & Slightly Less Naïve ones**

This is a (long and technical) article about making a computer generate **interesting and solvable** puzzles. If you don't know what a simulation even is, look away and never come back :p If you do know, I hope you find this article interesting and inspiring, and that it might even help you with your own games/projects.

**The problem**

I like creating puzzle games. I like designing levels. That, however, does not mean that I am actually *good* at either of those.

In previous game projects, I noticed it was very hard to come up with new and surprising ideas after 10-20 levels. On the other hand, people who played my games demanded more and more levels!

(Though, at some point this can become absurd. I've seen games on the Play Store with 100+ levels, where people were like "2 stars, because not enough levels".)

In an attempt to bridge the gap between my *design skill* and *demand*, I thought:

> **Wouldn't it be possible to make a computer generate puzzles?**

Such an algorithm would need to have three parts:

-   Generate a random level. (Preferably with some aspects known to be interesting or aesthetically pleasing, such as *symmetry* or *Perlin noise* for a map.)

-   Check if this level is solvable. (And if so, return the moves used.)

-   Generate some measures for *difficulty* and *interestingness* of each solvable puzzle.

If I could get this to work, I could just let the computer run for a few hours and I'd have a bunch more levels!

Of course, the levels would still need manual review (and improvement). The computer will most likely find many boring or ugly levels. But it would already be a huge help if I had a pool of say 1000 levels, out of which I could create a "best-of" selection and put in the game.

So, let's try it out!

**The mechanic**

Almost ten years ago, I made a little game. (It's still online under an old alias of mine, but I'm too ashamed to link to it.)

> **What can you do?** You get X number of moves, and each move means placing a *tower* somewhere on the board.
>
> **What does a tower do?** Each new tower shoots a line towards all previous towers. If this line crosses a collectible, you collect it!
>
> **The objective of the game?** Collect all *collectibles* (before you run out of towers to place).

Of course, there are walls/obstacles on the field that block your lines, there were mirrors that deflect your line, et cetera. But for the purposes of this article, I'm going to keep it simple.

GIF HERE?

Besides the fact that my old game was buggy as hell, looked bad, and only had 10 levels ... the underlying mechanic was actually solid!

So I decided to remake this game, with the following changes to the core idea:

-   The grid becomes hexagonal. It's more interesting, and it allows the following rule ...

-   Towers only shoot lines to towers *on the same line as them*.

GIF/IMAGE HERE?

Now the core question of this article becomes:

> **How do I make the computer solve a (randomly generated) level according to these rules?**

**Some comments**

I might sometimes call a level a **board** or **game board**, because that's how these algorithms are usually applied: to find the best move in a board game, like chess.

When I talk about level **size**, I mean the radius of the level. So size = 2, means the level is a hexagon with a width of 1+2\*2 = 5 tiles.

IMAGE HERE

Also note that I chose this game idea because it seemed feasible:

-   Levels aren't large.

-   The computer can literally only do one thing: place a tower.

-   With each move, the number of options shrinks (because towers take up space).

For these reasons, I thought it must be possible to make computer-generated levels. For more complex puzzle games, this will most likely not work.

**The "naïve" approach**

The "naïve" approach would be to brute force it: try all possible moves, save the solution with the shortest length.

I implemented this, just to see what would happen. I'm actually creating this game in the Corona game engine, which means this simulation was written directly inside the game, using the language **Lua**.

As you might have guessed ... this was waaaaay too slow.

Even after all optimizations I could think of, it took 3 minutes to try 10,000 moves. After about 4 or 5 minutes, it ran out of memory, became slower and slower, until it crashed.

Now, if the game board is very small (or has a quick solution), the algorithm only took a minute or so and always returned the correct solution. But that's certainly not enough for my purposes.

**Switching to Java**

So I decided to rewrite the simulation in **Java**. Why? Because I've done many simulations in Java before, it's much faster than Lua, and because it's messy to write the game simulation within the game engine itself.

This already made a HUGE difference. On small boards (size = 1 or 2), the solution was found in 0 seconds. On larger boards (size \> 2) however ... it crashed almost immediately. There are just too many possibilities to go through.

For example, let's say I have a level with 10 possible locations for towers, and I tell the computer it may take (at most) 5 moves. This already means it has to go through: 10\*9\*8\*7\*6 = 30,240 possibilities. And that's the best case scenario. When you collect something, that space opens up, giving you even more options. In most cases, levels will have more options and need more moves.

**Optimization #1: BFS**

So far, I just blindly ran through all possibilities. This is "stupid", because

-   We're looking for the shortest solution

-   And we don't know if there's a solution *at all*

If I set maxMoves = 5, it's quite probable that the algorithm terminates before it finds the actual solution which needs maybe 6 or 7 moves.

If I set maxMoves to a much higher number, like maxMoves = 20, it will need to go through more options than any computer could handle in its lifetime.

(Besides, a puzzle where you need 20 moves is usually not a good puzzle. It's too complicated to execute or calculate for a human.)

Instead, I switched to a "(naïve) breadth first search". First, it checks all states that need a single move. Once it's done with all of that, it checks all states that need two moves. Done? Check all states with three moves, and so on.

Once it finds *any solution*, it's guaranteed to be the shortest one, and it can quit immediately.

The results?

-   Any small board (size = 1 or 2) immediately returned a solution.

-   Some larger boards (size = 3 or 4) returned a solution within 0-20 seconds.

-   But most larger boards ... continued for a minute before throwing an error.

The error said the following: "Hey, your program is spending more time in garbage collection, than actually doing calculations."

In other words: I was creating and destroying so many game states, the program spent more time cleaning it up than actually calculating the next state.

I could see that happening: the first 50,000 simulations were done within a matter of seconds, then it slowed down to a crawl, until this error hit.

**Optimization #2: Mixing BFS and DFS**

If you apply a breadth first search in this way, it keeps all siblings (states with the same move depth) in memory. At first, this is fine. But after 5-7 moves, this means over 100,000 objects are stored in the queue for further consideration.

This is not the case with a *depth first search*, where you first check all states in one path, before going to the next. In that case, only all possibilities within that path are saved at any given time, which reduces memory consumption.

So I tried a mix: whenever a branch seems promising, it decides to search a bit further within that branch. If it doesn't find anything, it just backtracks and tries the next one. Doing this softened the problem: in many cases, just when the queue was getting too large, it started shrinking again because a load of states were thrown away because they didn't work.

**TO DO? BETTER WAY?**

**Optimization #3: Zobrist Hashing**

When I was visualizing the simulations (because hey, I already had a game engine that could display these game states!), I noticed something:

> In 99% of the cases, there's no difference between the moves A-\>B and B-\>A.

It's quite rare that a *different order of placement*, results in a different game board. (If it happens, it's usually part of the solution, because it's so hard to find :p)

So, I don't need to check every state that is identical to one that came before it!

To allow for quick comparisons between states, I used **Zobrist hashing**.

-   It generates a hash (integer) from the initial game board.

-   Every time I add/remove something from the board, I perform a XOR operation to add/remove that piece from the hash.

-   If I already saw this hash before, terminate and don't search this branch any further.

-   If not, save this hash in the list of all hashes.

This was huge.

Example 1: I have a random board with size 3 and 4 collectibles to get. It took the simulation 0 seconds to get the solution, and in that time it already had 6674 states thrown away because of duplicates.

Example 2: another random board with size = 3, collectibles = 4. Eventually, it took 5 moves to solve it. It threw 18380 states away because of duplicates.

Yes, there is a slight overhead to calculating and keeping track of the hashes. But the fact that thousands of entries are removed from the tree, even within a tree with only 4 moves, more than makes up for it.

**Optimization #4: Just Being Smarter**

It was, however, still not enough!

If a board was especially big or hard to solve, the simulation could run through all possible moves until it reached a move depth of 6. (Roughly. Sometimes it was 5, sometimes 7.)

When I checked the profiler, I saw that the garbage collector was still spending 98% of all processing power. I also saw that the program was using absolutely insane amounts of memory (and classes).

That's when I knew that naïve approaches would not do anymore.

**Dumb Thing #0:** I didn't do some obvious checks for solvability. For example, if a collectible is in the corner of the map, there's no way to shoot a line through it. (Because you can't place something on both sides.) That puzzle would never be solvable, so don't even bother.

(**Dumb Thing #0.5:** I passed around some variables to every new state, such as the total number of collectibles in the level. Of course, this information was identical for all states. So I could just make it accessible somewhere and NOT duplicate that information each time. Must admit I didn't predict how much of a difference this made: after implementing this, I could already get up to move depth 8 on most boards.)

**Dumb Thing #1:** I kept two separate lists in the simulation. One with all the states with N moves I still needed to check. One with all the states with (N+1) moves I still needed to check. Whenever the first list was exhausted, I transferred the second into the first and continued.

I thought this was necessary to "divide" states based on depth (how many moves they considered). I thought this was necessary to do a breadth first search.

It's not. I switched to a single list, tacked new states on at the end, and just grabbed the first element each time.

(This meant I did NOT have to regularly copy arrays of potentially 100,000 elements, and then clear the original arrays. Which gives the garbage collector some extra time off.)

**Dumb Thing #2:** I created my own "hexagon" class to store the locations of hexagons. It's nothing fancy, just the equivalent of a Vector3 in other (game) engines. However, if you go through thousands and thousands of states, these extra classes quickly add up.

And I don't need it. A 2D hexagon map follows the rule that x + y + z = 0. This means that I only need to know the x and y coordinate. And because I know the maximum map size, I can condense that into a single unique integer: x + y\*mapSize.

And that's when things become even MORE interesting. Large parts of the map are empty, currently. I store the map as a 3D array (int\[\]\[\]\[\]), which means I usually reserve roughly ten times more memory than I use.

So I switched to a flat array, using those unique integer indices above to store what's where. The code becomes a little less obvious/familiar to me, but it makes a ton of difference.

**TO DO:**

-   Switch other stuff (movesList) to integers as well

-   Ditch array lists; create array\[previousSize+1\] in each new state

-   Research if we can ditch all of THAT with linked lists, or backtracking

**How are we doing so far?**

The simulation could go through 500,000 states within a minute. Boards with size = 3, maxMoves = 8 were fine: it did not crash, or run out of memory.

If a solution was possible, though, usually it took only 0-5 seconds to find it.

If a solution was NOT possible, it only took 5-10 seconds to exhaust all possibilities and try a new level. (Usually, if a solution is not present, this also means there aren't many states to consider, so it goes through them very quickly.)

These are acceptable results :p

There are just a few issues left:

-   Does performance hold up when I introduce all the other mechanics in the game? For example, calculating the effect of MIRRORS will probably eat performance.

-   Does performance hold up for more irregular levels? (Now, levels are a tight grid. What if levels become a large irregular landscape with many holes?)

-   Completely random levels aren't interesting => I'd like to be smarter with the level generation.

**To part 2 and beyond!**

At this moment in time, I was confident this would work, so I switched back to working on the actual game. (Implementing the mechanics and interface, graphics, et cetera.)

I thought that would be a natural time to break this article into two parts.

Once I had most of the mechanics ready, I returned to the Java simulation, implemented these, and then started improving the simulation again.

**Computer-generated puzzles**

**Part 2: Better randomness, better trees**

**Measuring Interestingness**

Many of the levels that the computer outputs are just ... not interesting. They are too easy and boring, or they don't use any of the special mechanics I have implemented.

First, I tried to overcome this with some sort of "interestingness formula". The idea was as follows: pick a few good metrics for *complexity* and *diversity* of a level (such as "number of moves" and "number of special elements"), combine them into a formula, then sort all levels based on this value.

The metrics I chose to calculate were:

-   Board size (bigger board = more options and more complex)

-   Number of moves

-   Number of people ( = collectibles)

-   How long it took the computer to find a solution (longer search = solution must be harder to find)

-   Number of special elements in the level

-   Number of special elements *that were actually used* *in the solution*

-   Average number of possible moves (per turn)

IMAGE HERE?

As you might have already noticed by my way of writing: this method didn't work. The metrics were fine indicators, but I just couldn't string them together into a formula or a single value. How much more important is metric A over metric B? What is a good cut-off value, below which levels are too boring or uninteresting?

This process, however, did yield some interesting observations which eventually solved the problem.

This puzzle game we're making has a sort of campaign. Every 10-15 levels, you enter a new world where one (or several) new mechanic is explained. As usual with these kinds of games, when I explain a new mechanic, I want to create a few very *simple* levels that specifically use this mechanic. This helps teach the mechanic to players and ensures the difficulty curve isn't too steep.

So, I started keeping track of specific elements that were being used. Not the overall number of special elements, but *specifically* the element that I wanted to teach.

Then, I could create a certain threshold, and only levels that passed it would be interesting enough.

IMAGE HERE?

For example: the first mechanic you learn is the "forest" tile. What does it do? Well, the first time a letter tries to go through it, it can't. (The forest is too dense to pass through.) But, the second time, and all times thereafter, you *can* send a letter through it!

So, I made the computer count *how many times* a forest tile was used in the solution to the current level. If a forest tile was never used or only used once, this level is not good enough. But if the level used a forest tile at least twice, we got something interesting!

Almost all levels generated this way could be copied 1-to-1 to the actual game, because they did exactly what I needed them to do: exclusively use this new mechanic in some way or another.

Knowing this, it was easy to take the next step towards more complex and diverse levels. Instead of checking a specific element, we also check the total number of special elements.

In my case, I've found a good threshold to be "#special elements \>= 2 and fraction of elementsUsed \>= 0.5"

Why?

-   If the level has 0 or 1 special elements, it's unlikely to be difficult or interesting.

-   A higher value for that fraction (elementsUsed/totalElements), is always better. It means we've used more special tiles in the solution.

-   However, requiring a value near 1.0 would be unhelpful. The computer would take way too long to get an answer (as it would reject almost all levels). Also, it's good to have "decoy" elements (that fool the player into thinking they need to use them) and to have some decoration.

**Optimization #5: Linked Lists?**

**Dumb Thing #3:** Whenever I created a new state, I copied all information from its parent state into it. Yes, a deep copy, so I actually created large arrays for *every new state*. Yes, this is stupid and I should have known there would be problems.

Instead I switched to a "changes only" system. I save the game board as it is as the start.

Then, I only pass the *changes* from state to state.

Within the state itself, when we execute a move, we basically "reconstruct" the game board from the changes.

This adds considerably more calculations to each state. But as it stands, computations are not the issue in the simulation, memory is. So it's the right trade-off.

**TO DO**

**Thinking the other way around**

Designing LEVELS + MECHANICS to reduce possibility space and speed up the simulation.

-   Mechanics that: block many spaces at once, but can also open up many other spaces. This way, the playing board becomes more unpredictable (less easy/obvious to see the solution), but the possibility space stays small.

**The fail-safe**

If we've tried loads of moves, but there are just TOO many -- stop.

Add some obstacles to the level, reduce possibility space, then try again.

**The heuristic**

Currently, the algorithm is "perfect": if there IS a solution, it will find it. It will never skip a state (branch of the tree) that COULD result in a solution.

If we change that, however, things could speed up a LOT. There are certain states which are simply "hopeless".

For example: say you've already done 5 moves, and you still haven't collected a single collectible. Are you going to find the solution? Probably not.

Another example:
