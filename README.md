# Formula Speed - a turn-based racing car board game

Releases: https://github.com/togfoxy/FormulaSpeed/releases

![alt text](https://i.postimg.cc/zBHqFnZ3/image.png)

Select your gear, roll the dice, move your car, negotiate the corners - win!

Instructions

1) choose a gear in the bottom-right corner

2) right-click your car forward one square at a time until all your moves are exhausted

3) go to step 1   :)

Rules
=====

Low gears go slow. High gears go fast.

You can move up one gear at a time.

You can move down one gear without penalty. You can move down more than one gear with penalty.

Aim to 'stop' your car on each corner according to the number of times indicated by the yellow flag. Your car is stopped when you exhaust your moves and need to choose a new gear.

Failing to stop the required number of times on each corner will result in tyre damage or crash.

Use the BRAKE button to slow your car. This will cost you BRAKE points. If you get blocked, keep pressing the brake until your turn ends (or you crash).

Use the matrix at the top of the screen to see how many squares each gear may take you. The actual number will be a random number in the given range.

For the moment, every new game gives you a random gearbox with random ability.

The game presents a 'ghost' car if you play more than one game. The ghost reflects your personal best. Beat the ghost - beat your personal best.

Play the track as many times as you like and beat your personal best time.

DEV NOTES: the game supports one lap. Press ESCAPE to close the game when all cars are finished.


Controls
========

Use left mouse button to select a gear.

Use right moust button to select a cell in front of the race car.

Hold milddle-mouse-button to move the camera.

Use arrow keys to move the camera.   ( <- ^ -> v  )

Use shift-arrow keys to move the camera faster.

Use mouse-wheel to zoom in and out.

Use -/= to zoom in and out.

Editor
======

Contains in-game editor that lets you change the track. Click 'e' to enter editor mode:

- click any cell to highlight it
- use mouse wheel to rotate a cell
- right-click-drag between two cells to create a link (pathway). DIRECTION IS IMPORTANT
- repeat the right-click-drag between two cells to remove the link
- 'delete' key will remove a cell
- 'c' key marks a cell as a corner. Do this for every cell in the corner.
- 's' key sets the speed/stops on the corner. Do this for every cell in the corner.
- 'f' key will mark the cell as a finish line
- 'n' will add a new cell at the current mouse position
- 'l' will add a new cell at the current mouse position AND link it to the previous cell

- 'SHIFT-S' will save the track

Artificial intelligence - machine learning
==========================================

The bots are not hand scripted or coded. They are genuine machine-learning bots. They start with limited intelligence and learn over time. The more you play, the more they learn. As the bots learn, their knowledge and understanding of the track increases. 

Hold the 'k' key to see the heatmap for the track as the bots understand it. Red cells show where the bots think they need to slow down. Yellow and blue cells show where the bots think they need to speed up. This heatmap is constantly evolving and improving. With enough time, the bots will form a perfect heatmap to guide their decision making.

Roadmap
=======

Audio.

A campaign.

A shop that lets you upgrade your car.

A shop that lets you buy drivers.

Better user interface/controls.




