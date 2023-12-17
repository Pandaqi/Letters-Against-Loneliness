**Pixel Art Tutorials (and stuff)**

**Good Youtube Channel:** MortMort (does pixel art, but also 3D modeling)

**3 common beginner mistakes:** <https://www.youtube.com/watch?v=gW1G_FLsuEs>

-   **Doubles**: when you draw a line, pixels aren't only connected diagonally, but also vertically/horizontally.

    -   Fix? Turn on pixel-perfect in Aseprite, or use shift-click lines

-   **Jaggies**: when a pattern is broken (unintentionally) => e.g. one pixel down all the time, then suddenly two pixels down

    -   Fix? Stick to the pattern (if it's an easy pattern)

    -   Fix 2? Realize that curves have a "tipping point". That's where lines are shortest, usually just a single pixel. Around that, elongate stretches of pixels more and more.

    -   (Think of it as a pattern, something like: 4 3 2 1 1 1 2 3 5 => keep a pattern, and keep a pattern to the *changes* to the pattern)

    -   (Also, this looks a lot like the Fibonacci sequence. As this sequence is related to the Golden ratio, it's usually a good idea for making things look good.)

-   **Outlines**:

    -   Know whether you want something to be *pointy*/*hard edge* or *round/soft edge*. Only use a pixel in the corner (a double, essentially) if you want something pointy.

    -   Don't allow (a few) transparent pixels within the sprite if you have an outline. If you notice this, just fill the whole gap with outline.

    -   Don't allow quick pixel switches => it will be distracting. Just fill them towards a completely straight (vertical/horizontal) line.

    -   (However, if you purposely *want* something to look apart/stand out, do the opposite and leave it open.

    -   TIP: For small objects, such as a *nose*, placing an extra pixel on the outline like this can make a huge difference. (Pixel above = more pointy/upward nose. Pixel below = more soft and wide nose.)

**MiniBoss** (the artist behind *Celeste* and *Towerfall*): <https://www.youtube.com/user/studiominiboss/featured>

**10 Most Common Pixel Art Mistakes:** <https://www.youtube.com/watch?v=R44hZgtqMI8>

-   Don't allow the images to be filtered (when upscaled/downscaled)

-   Keep lines smooth (see MortMort video above)

-   Reduce color count AND pixel count. (Otherwise, it's not really pixel art anymore, and more work than necessary.)

-   SHADING: a few good bits on shading (middle areas are usually flat/open, shading and detail only happen at the edges)

-   Also, establish a light source!!

**A general guide to Pixel Art:** <https://www.youtube.com/watch?v=wdz2IIuTBbs>

-   A bit slow, but very good, especially for an introduction.

-   IDEA: Start as small as you can (8x8). When you have something, scale it to 16x16 and make it more detailed. Continue until satisfied/actual size of asset.

**Beginner Pixel Art Questions:** <https://www.youtube.com/watch?v=cWKhytYUGTg>

-   Check out MortMort's playlist anyway.

-   <https://www.spriters-resource.com/> => library of all sprites from existing pixel art games

-   <https://lospec.com/> => really good pixel art tutorials and stuff

-   Alternative pixel editor (better for **tilesets**): **Pyxel Edit**

-   More advanced software, but very steep learning curve: **Pro Motion**

-   Outline or no Outline? Adding an outline makes things a bit more cartoonish/stylish, while no outline is more natural/realistic. Either way, **be consistent**.

**How do I learn pixel art (amazing Reddit thread!):** <https://www.reddit.com/r/gamedev/comments/8vlzqi/how_do_i_learn_pixel_art/>

**Top Down Pixel Character Art (#1):** <https://www.youtube.com/watch?v=ty-RxDy9_SQ>

**Cute Character & Animation (top-down RPG)**: <https://www.youtube.com/watch?v=ty-RxDy9_SQ>

-   Three-step approach:

    -   First map out/sculpt the silhouette. Give each limb a different color

    -   Add outline, refine details, add lines that need to be there (to distinguish body parts and determine what's in front/back)

    -   Finally, remove color, clean up and add blocks of shading (=> grayscale base)

Once you have a solid base, you add clothing and stuff *afterwards*.

First, make the whole rotation ( = all animation frames) with the colored base. Only add details once you're sure the animation frames work.

Don't draw complete frames on at a time. Draw one single thing *on each frame*, while keeping an animating preview open, to check if everything flows and is consistent.

**Pixel Art Tips for (non-artist) beginners:** <https://www.youtube.com/watch?v=p1t0keLufMw>

-   Always keep a **preview** of your pixel art (zoomed-out) => it's meant to be looked at in that size

-   **The 3-color rule:** limit yourself to a *basic color* and two variations (*light* and *dark*).

    -   Lighter color: shift hue towards yellow/orange, slightly increase saturation and brightness

    -   Darker color: shift hue towards dark blue/purple, slightly decrease saturation and brightness.

-   **Symmetry in shape, asymmetry in color**. Make the overall shape/form/outline have symmetry, but break that (for more detail/interestingness) by using asymmetric colors. (Mainly with off-balance, not-perfect texture work.)
