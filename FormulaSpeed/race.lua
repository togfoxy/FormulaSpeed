race = {}

local racetrack = {}          -- the network of cells
local cars = {}               -- a table of cars
local numofcars = 6

local celllength = 128
local cellwidth = 64

local sidebarwidth = 250

local gearstick = {}            -- made this a table so I can do graphics stuff

local ghost = {}                -- tracks the ghosts movements
local history = {}              -- eg history[1][12] = cell 29     (car 1, turn 12, cell 29)

local EDIT_MODE = false                -- true/false

local previouscell = nil                -- previous cell placed during link command
local numberofturns = 0
local diceroll = nil                    -- this is the number of moves allocated when choosing a gear.
local currentplayer = 1                 -- value from 1 -> numofcars
local pausetimer = 0 -- track time between bot moves so player can see what is happening

local function getForwardCornerCells(cell)
    -- used during editing. Return a table of all the corner cells in front of this one
    -- including this one
    --! not yet working
    local stack = {}
    table.insert(stack, cell)
    for k, v in pairs(racetrack[cell].link) do
        if v == true then       -- k = cell number. v = true/false
            if racetrack[k].isCorner then
                -- local thiscell = getForwardCornerCells(k)
                -- table.insert(stack, getForwardCornerCells(k))
                local newstack = {}
                newstack = getForwardCornerCells(k)
                for q, w in pairs(newstack) do
                    table.insert(stack, w)
                end
            end
        end
    end
    return stack
end

local function allCarsLeftGrid()
    -- returns true if all cars have crossed the finish line at least once
    for i = 1, numofcars do
        if not cars[i].isOffGrid then
            return false
        end
    end
    return true
end

local function getDistanceToFinish(startcell, ignoreFirstFinish)
	-- count the number of cells between the provided cell and the finish line
	-- does NOT check for a clear path. Just measures raw distance
    -- input: startcell = starting cell
    -- input: ignoreFirstFinish = set to TRUE when the car is still on the grid and the first crossing of the finish
    --          line needs to be ignored
	-- NOTE: this function doesn't try to find the shortest path meaning it is not very efficient (or accurate)
	-- NOTE: gives incorrect results for cars on the grid and not yet crossed the line.        --!

    -- print("Cell #" .. startcell, ignoreFirstFinish)

	local result       -- number
    local nextcell
	currentcell = startcell
    for k, v in pairs(racetrack[currentcell].link) do
        if v == true then       -- only count active links
            nextcell = k
            break       -- just need the first link
        end
    end

    -- check to see if finish line is crossed
    if racetrack[currentcell].isFinish and not racetrack[nextcell].isFinish then
        -- current cell is on the finish and is about to leave/cross the finish
        if not ignoreFirstFinish then
            result = 1
            -- print("Found the finish line on cell #" .. nextcell .. " so returning result:" .. result)
            return result
        elseif ignoreFirstFinish then
            -- print("Found finish on cell #" .. nextcell .. " but ignoring. Moving on to cell #" .. nextcell)
            result = 1 + getDistanceToFinish(nextcell, false)       -- continue recursing with the FALSE flag
            return result
        else
            -- print("Continuing search alpha. Will use default parameters. Moving on to cell #" .. nextcell)
            result = 1 + getDistanceToFinish(nextcell, ignoreFirstFinish)
            return result
        end
    else
        -- not crossing the line. Continue counting
        -- print("Continuing search beta. Will use default parameters. Moving on to cell #" .. nextcell)
        result = 1 + getDistanceToFinish(nextcell, ignoreFirstFinish)
        return result
    end
	error("Not sure this code should ever execute.", 100)
end

local function incCurrentPlayer()
    -- operates on global. Returns nothing.

    -- find the car with the least number of turns
    -- if more than one then find car closest to the finish line

    -- iterate through loop and get the number of turns used + distance to finish at same time and then sort
    local players = {}
    for i = 1, numofcars do
        if cars[i].isEliminated or cars[i].hasFinished then
            -- skip this car so it never becomes the current player
        else
            thisplayer = {}
            thisplayer.turns = cars[i].turns
            -- print("Getting distance for car #" .. i)
            if cars[i].isOffGrid then
                thisplayer.distance = getDistanceToFinish(cars[i].cell, false)      -- car is offgrid. Don't ignore the next finish line
            else
                thisplayer.distance = getDistanceToFinish(cars[i].cell, true)
            end
            thisplayer.carindex = i
            -- print("Distance determined to be " .. thisplayer.distance )
            table.insert(players, thisplayer)
        end
    end

    if #players == 0 then
        error("All cars have crashed so this game also crashed", 130)       --!
    end

    -- print("")
    -- print("About to sort this table:")
    -- print(inspect(players))
    table.sort(players, function(k1, k2)
        if k1.turns < k2.turns then
            return true
        elseif k1.turns == k2.turns and k1.distance < k2.distance then
            return true
        elseif k1.turns > k2.turns then
            return false
        elseif k1.turns == k2.turns and k1.distance > k2.distance then
            return false
        elseif k1.turns == k2.turns and k1.distance == k2.distance then
            return false
        else
            error("bad sort", 80)
        end
    end)

    currentplayer = players[1].carindex     -- this is not cars[1] - it's players[1]

    -- see if every car has had a turn. If so then set number of turns
    local turntable = {}
    for i = 1, numofcars do
        if not cars[i].isEliminated then
            table.insert(turntable, cars[i].turns)
        end
    end
    table.sort(turntable)
    numberofturns = turntable[1]

    if currentplayer == 1 and not cars[1].isEliminated then
        TRANSLATEX = racetrack[cars[1].cell].x
        TRANSLATEY = racetrack[cars[1].cell].y
        cam:setPos(TRANSLATEX, TRANSLATEY)
    end
end

local function unselectAllCells()
    for k, v in pairs(racetrack) do
        v.isSelected = false
    end
end

local function addNewCell(x, y, pcell)
    -- adds a new cell at the provided x/y
    -- makes the new cell the selected cell
    -- includes a link from pcell to this cell if not nil

    local thisCell = {}
    thisCell.x = x
    thisCell.y = y
    thisCell.rotation = 0
    thisCell.isSelected = true
    thisCell.isCorner = false
    thisCell.speedCheck = nil               -- Number. Used at the exit of corners to check for overshoot
    thisCell.isFinish = nil
    thisCell.link = {}
    table.insert(racetrack, thisCell)

    if pcell ~= nil then
        -- link from previous cell to this cell
        racetrack[pcell].link[#racetrack] = true
        racetrack[#racetrack].rotation = racetrack[pcell].rotation
        previouscell = nil
    else
        previouscell = #racetrack       -- global
    end
    unselectAllCells()
end

local function getSelectedCell()
    -- retuns a number or nil
    for k, v in pairs(racetrack) do
        if v.isSelected then
            return k
        end
    end
    return nil
end

local function isCellClear(cellindex)
	-- returns true if no cars are on the provided cell
	for k, v in pairs(cars) do
		if v.cell == cellindex then
			-- cell is not clear
			return false
		end
	end
	return true
end

local function findClearPath(stack, fromcell, movesleft)
	-- starting at fromcell, find a path that uses at least movesleft steps)
    -- eg cell #1 to cell #25
    -- input: a table that will start empty and be filled
    -- input: the cell the path starts at
    -- input: how many cells to look forward (moves left/dice roll)
    --! how does this behave when blocked and no path?

	-- local stack = {}
	local currentcell = fromcell
	local stepsneeded = movesleft
    -- print("Car at cell#" .. currentcell .. " about to look for a valid link")
	for k, v in pairs(racetrack[currentcell].link) do
        if v == true then       -- ensure the link is valid/real
            local nextrandomcell = k		-- k is the cell number of the link
    		if isCellClear(nextrandomcell) then
                table.insert(stack, nextrandomcell)
    			stepsneeded = stepsneeded - 1
                if stepsneeded < 1 then
                    -- job done
                    return stack
                else
                    -- steps not exhausted yet. Keep going
                    stack = findClearPath(stack, nextrandomcell, stepsneeded)
                    return stack
                end
            end
        end
    end
    print("I think car is blocked and all links exhausted. Maybe?")     --!
    stepsneeded = 0
    return {}       -- a signal that a path could not be found
    -- return stack
end

local function removeLinksToCell(cell)
    -- scan racetrack and remove all links to cell making it orphaned and ready for deletion
    -- for i = 1, #racetrack do
    for q, w in pairs(racetrack) do
        for k, v in pairs(w.link) do
            if k == cell and v == true then
                -- kill this link as it's not permitted. Kill it by setting value to false
                print("Killing link to destroyed cell# " .. k)
                w.link[k] = false
                print("Best to save the track in the editor")
            end
        end
    end
end

local function loadRaceTrack()
    -- loads the hardcoded track into the racetrack variable
    racetrack = fileops.loadRaceTrack()
    if racetrack == nil then
        racetrack = {}                  -- the load operation returned nil. Set back to empty table
        addNewCell(100,100, nil)
        print("No track found. Providing starting cell.")
    else
        print("Track loaded.")
    end

    -- do a sanity check on the track and look for simple faults.
    -- ensure there are no links to destroyed cells
    for i = #racetrack, 1, -1 do
        if racetrack[i] == nil then
            removeLinksToCell(i)
        end
    end

    trackknowledge = {}
    trackknowledge = fileops.loadTrackKnowledge()
    if trackknowledge == nil then
        print("No track knowledge found.")
    else
        print("Track knowledge loaded.")
    end
end

local function loadCars()

    for i = 1, numofcars do
        cars[i] = {}
        history[i] = {}         -- tracks the history for this race only

        if i == 1 then
            cars[i].cell = 1
        elseif i == 2 then
            cars[i].cell = 435
        elseif i == 3 then
            cars[i].cell = 162
        elseif i == 4 then
            cars[i].cell = 432
        elseif i == 5 then
            cars[i].cell = 159
        elseif i == 6 then
            cars[i].cell = 429
        else
            error("Too many cars loaded.", 148)
        end

        -- ** debugging: tight grid to test blocking **
        -- if i == 1 then
        --     cars[i].cell = 164
        -- elseif i == 2 then
        --     cars[i].cell = 448
        -- elseif i == 3 then
        --     cars[i].cell = 435
        -- elseif i == 4 then
        --     cars[i].cell = 163
        -- elseif i == 5 then
        --     cars[i].cell = 447
        -- elseif i == 6 then
        --     cars[i].cell = 434
        -- else
        --     error("Too many cars loaded.", 148)
        -- end


        cars[i].gear = 0
        cars[i].wptyres = 6
        cars[i].wpbrakes = 3
        cars[i].wpgearbox = 3
        cars[i].wpbody = 3
        cars[i].wpengine = 3
        cars[i].wphandling = 2
        cars[i].movesleft = 0
        cars[i].brakestaken = 0             -- how many times did car stop in current corner
        cars[i].isEliminated = false
        cars[i].isSpun = false
        cars[i].log = {}
        cars[i].turns = 0                       -- how many turns taken
        cars[i].isOffGrid = false               -- set to true on first corner to see if car has moved off grid
        cars[i].hasFinished = false             -- has finished the race

        -- gearbox
        cars[i].gearbox = {}
        cars[i].gearbox[1] = {}
        cars[i].gearbox[1][1] = 1
        cars[i].gearbox[1][2] = love.math.random(1, 3)

        cars[i].gearbox[2] = {}
        cars[i].gearbox[2][1] = love.math.random(1, 3)
        cars[i].gearbox[2][2] = love.math.random(1, 5)
        if cars[i].gearbox[2][2] < cars[i].gearbox[2][1] then cars[i].gearbox[2][2] = cars[i].gearbox[2][1] end

        cars[i].gearbox[3] = {}
        cars[i].gearbox[3][1] = love.math.random(3, 5)
        cars[i].gearbox[3][2] = love.math.random(7, 9)

        cars[i].gearbox[4] = {}
        cars[i].gearbox[4][1] = love.math.random(6, 8)
        cars[i].gearbox[4][2] = love.math.random(11, 13)

        cars[i].gearbox[5] = {}
        cars[i].gearbox[5][1] = love.math.random(10, 12)
        cars[i].gearbox[5][2] = love.math.random(19, 21)

        cars[i].gearbox[6] = {}
        cars[i].gearbox[6][1] = love.math.random(20, 22)
        cars[i].gearbox[6][2] = love.math.random(29, 31)
    end

    -- load the ghost history, if there is one
    ghost = fileops.loadGhost()
end

local function loadGearStick()
    -- the gear stick knobs are a table that needs to be loaded.
    -- making it a table of x/y makes mouse detection easier
    gearstick[1] = {}
    gearstick[1].x = SCREEN_WIDTH - sidebarwidth + 50
    gearstick[1].y = SCREEN_HEIGHT - 100

    gearstick[2] = {}
    gearstick[2].x = gearstick[1].x
    gearstick[2].y = gearstick[1].y - 100

    gearstick[3] = {}
    gearstick[3].x = gearstick[1].x + 75
    gearstick[3].y = gearstick[1].y

    gearstick[4] = {}
    gearstick[4].x = gearstick[3].x
    gearstick[4].y = gearstick[2].y

    gearstick[5] = {}
    gearstick[5].x = gearstick[3].x + 75
    gearstick[5].y = gearstick[3].y

    gearstick[6] = {}
    gearstick[6].x = gearstick[5].x
    gearstick[6].y = gearstick[4].y
end

local function getClosestCell(pointx, pointy)
    -- returns cell number or nil
    -- determine which cell is closest to the mouse click
    local smallestdist = 999999
    local smallestkey = nil
    for k, v in pairs(racetrack) do
        local dist = cf.getDistance(pointx, pointy, v.x, v.y)
        if dist > 0 and dist < smallestdist then
            smallestdist = dist
            smallestkey = k
        end
    end

    if smallestdist <= 30 then
        return smallestkey
    end
    return nil
end

local function addCarMoves(carindex)
    -- need to set the correct gear BEFORE calling this function
    -- assign a random number of moves based on new gear
    local currentgear = cars[carindex].gear     -- done for readability
    local low = cars[carindex].gearbox[currentgear][1]
    local high = cars[carindex].gearbox[currentgear][2]
    diceroll = love.math.random(low, high)      -- capture this here and use it for the AI
    cars[carindex].movesleft = diceroll

    if carindex > 1 then
        print("Dice roll for car #" .. carindex .. " is " .. diceroll)
    end
end

local function executeLegalMove(carindex, desiredcell)
    -- moves to desired cell which is just one cell away
    local originalcell = cars[carindex].cell
    local originalmovesleft = cars[carindex].movesleft
    cars[carindex].cell = desiredcell
    cars[carindex].movesleft = cars[carindex].movesleft - 1
    cars[carindex].isSpun = false       -- the act of moving causes unspin

    if racetrack[originalcell].isFinish and not racetrack[desiredcell].isFinish then
        -- car was on the finish but moved off it. It is now 'off grid'
        cars[carindex].isOffGrid = true
    end

    if cars[carindex].movesleft < 1 then
        -- end of turn
        cars[carindex].movesleft = 0

        -- add to history. This tracks which cell the car landed on for each turn
        if cars[carindex].isOffGrid then
            history[carindex][numberofturns] = cars[carindex].cell
        end

        -- add move to the log file for this car
        -- happens end of every move and is used for the bots AI. Different to history[] which is used for the ghost
        -- example format:  cars[1].log[23].movesleft = 10      -- car 1 log for cell 23 = 10 moves left
        if cars[carindex].log[desiredcell] == nil then     -- at this point, desiredcell = cars[1].cell
            cars[carindex].log[desiredcell] = {}
        end
        cars[carindex].log[desiredcell].moves = diceroll       -- basically saying "rolled this dice from this cell"

        -- give credit for braking in corner
        -- print("Checking if desired cell# " .. desiredcell .. " is a corner")
        if racetrack[desiredcell].isCorner then     -- desired cell is actually current cell
            cars[carindex].brakestaken = cars[carindex].brakestaken + 1
        end
    end

    -- if leaving corner, see if correct number of stops made
    if racetrack[originalcell].isCorner and not racetrack[desiredcell].isCorner then
        -- have left the corner. Do speed check
        local brakescore = racetrack[originalcell].speedCheck - cars[carindex].brakestaken
        if brakescore <= 0 then     -- brake score relates to the yellow flag.
            -- correct brakes taken. No problems
        else        -- overshoot
            -- overshoot
            if brakescore >= 2 then
                -- elimination
                cars[carindex].isEliminated = true
                local txt = "Car #" .. carindex .. " ignored yellow flag and is eliminated"
                lovelyToasts.show(txt, 10, "middle")
                cars[carindex].movesleft = 0
            else        -- brakescore == 1
                -- see how many cells was overshot
                -- some complex rules about spinning etc
                if cars[carindex].wptyres > 0 then
                    -- different set of rules
                    if cars[carindex].wptyres > originalmovesleft then
                        -- normal overshoot
                        local txt = "Car #" .. carindex .. " used " .. originalmovesleft .. " tyre points"
                        lovelyToasts.show(txt, 10, "middle")
                        cars[carindex].wptyres = cars[carindex].wptyres - originalmovesleft
                    elseif cars[carindex].wptyres == originalmovesleft then
                        -- spin becaue overshoot amoutn == wptyres
                        cars[carindex].wptyres = 0
                        cars[carindex].isSpun = true
                        cars[carindex].gear = 0
                        local txt = "Car #" .. carindex .. " has no tyre points left. Car has spun"
                        lovelyToasts.show(txt, 10, "middle")
                    elseif originalmovesleft > cars[carindex].wptyres then
                        -- crash out
                        txt = ("Car #" .. carindex .. " has crashed. Overshoot amount is greater than tyre wear points")
                        lovelyToasts.show(txt, 10, "middle")
                        cars[carindex].isEliminated = true
                        cars[carindex].isSpun = true
                    end
                elseif cars[carindex].wptyres == 0 then
                    -- special rules when wptyres == 0
                    if originalmovesleft == 1 then  -- oveshoot on zero tyres has an odd rule
                        casr[carindex].isSpun = true
                        cars[carindex].gear = 0
                        if originalmovesleft > 1 then
                            -- crash out
                            txt = ("Car #" .. carindex .. " has crashed. Overshoot amount is > 1 while out of tyre wear points")
                            lovelyToasts.show(txt, 10, "middle")
                            cars[carindex].isEliminated = true
                            cars[carindex].isSpun = true
                            cars[carindex].movesleft = 0
                        end
                    elseif originalmovesleft > 1 then
                        -- crash
                        txt = ("Car #" .. carindex .. " has crashed. Overshoot amount > 1 while out of tyre wear points")
                        lovelyToasts.show(txt, 10, "middle")
                        cars[carindex].isEliminated = true
                        cars[carindex].isSpun = true
                        cars[carindex].movesleft = 0
                    else
                        error("Oops. Unexpected code executed", 394)
                    end
                else
                    error("Oops. Unexpected code executed", 399)
                end
            end
        end
        cars[carindex].brakestaken = 0     -- reset for next corner
    end

    -- check for a finish
    if racetrack[cars[carindex].cell].isFinish and cars[carindex].isOffGrid == true then
        -- WIN!
        cars[carindex].hasFinished = true
        print("Lap time = " .. numberofturns)
        lovelyToasts.show("Lap time = " .. numberofturns, 15, "middle")

        -- see if this lap performance should replace the ghost
        if carindex == 1 then   -- ghost is only for player 1
            if ghost == nil or numberofturns < #ghost then
                local success = fileops.saveGhost(history[carindex])
                print("Ghost save success: " .. tostring(success))
            end
        end

        -- update the bot AI
        -- use the cars log to update the bots knowledge of the race track
        -- example: trackknowledge[23].besttime	= the best recorded time for any car using cell 23
        --          trackknowledge[23].moves = the speed of the car that achieved the best time (see above)
        -- these two things gives the bot AI something to strive for when selecting gears
        for k, v in pairs(cars[carindex].log) do
            if trackknowledge == nil then trackknowledge = {} end
            if trackknowledge[k] == nil then trackknowledge[k] = {} end
            if trackknowledge[k].besttime == nil or trackknowledge[k].besttime > numberofturns then
                if v.moves > 0 then -- 0 is a legit value but offers no value to an AI
                    -- this log has a faster time than previously recorded
                    -- update track knowledge with this new information
                    trackknowledge[k].besttime = numberofturns
                    trackknowledge[k].moves = v.moves
                end
            end
        end
        local success = fileops.saveTrackKnowledge(trackknowledge)
        print("Knowledge save success: " .. tostring(success))
        -- print(inspect(trackknowledge))

    end

    if currentplayer ~= 1 then
        pausetimer = 1.25			-- seconds
    end
end

local function botSelectGear(botnumber)
    local rnd = love.math.random(-1, 1)
    local result = cars[botnumber].gear + rnd
    if result < 1 then result = 1 end
    if result > 6 then result = 6 end
    return result
end

local function applyMoves(carindex)

    local path = {}
    path = findClearPath(path, cars[carindex].cell, cars[carindex].movesleft)
    -- print("Found a path:")
    -- print(inspect(path))

    -- path can be nil if the car gets blocked
    if #path == 0 then
        -- path is blocked. Abort turn and move to next player
        cars[carindex].turns = cars[carindex].turns + 1     -- need to inc this count so that this car is not simply selected again
        incCurrentPlayer()
    else
        -- path not blocked. execute move and move to next player
        while path ~= nil and #path > 0 do
            local desiredcell = path[1]
            executeLegalMove(carindex, desiredcell)
            if cars[carindex].movesleft < 1 then
                cars[carindex].turns = cars[carindex].turns + 1
                incCurrentPlayer()
            end
            table.remove(path, 1)
        end
    end
end

local function moveBots()
    cars[currentplayer].gear = botSelectGear(currentplayer)
    addCarMoves(currentplayer)       -- assumes the gear has been set
    applyMoves(currentplayer)
end

local function drawGearStick(currentgear)
    -- draw gear stick in bottom right corner
    -- draw the lines on the gear stick first
    love.graphics.line(gearstick[1].x, gearstick[1].y, gearstick[2].x, gearstick[2].y)
    love.graphics.line(gearstick[3].x, gearstick[3].y, gearstick[4].x, gearstick[4].y)
    love.graphics.line(gearstick[5].x, gearstick[5].y, gearstick[6].x, gearstick[6].y)
    local drawy = gearstick[1].y - (gearstick[1].y - gearstick[2].y) / 2
    love.graphics.line(gearstick[1].x, drawy, gearstick[6].x, drawy)
    -- draw the knobs
    for k, v in pairs(gearstick) do
        if currentgear == k then           -- set the colour green if this gear is selected
            love.graphics.setColor(0,1,0,1)
        else
            love.graphics.setColor(1,1,1,1)
        end
        love.graphics.circle("fill", v.x, v.y, 10)
        -- draw the numbers on the knobs
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(k, v.x - 4, v.y - 6)
    end
end

local function drawGearboxMatrix()
    -- draw the matrix along the top bar
    -- !! uses global cars[1] for now

    local topbarheight = 225
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH - sidebarwidth, topbarheight)

    -- draw the gearbox matrix
    -- draw the speed along the top
    local drawx = 100
    local drawy = 25
    love.graphics.setColor(1,1,1,1)
    for i = 1, 40 do            -- 40 is the max dice roll
        love.graphics.print(i, drawx + 10, drawy)       -- the +10 centres the text
        drawx = drawx + 30
    end

    -- draw the gears down the side of the matrix
    drawx = 50
    drawy = 50
    for i = 1, 6 do
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Gear " .. i, drawx, drawy + 4)         -- the +4 centres the text
        drawy = drawy + 25
    end

    -- now fill in the matrix
    -- add white boxes everywhere
    for i = 1, 6 do     -- this is not cars - its gears
        for j = 1, 40 do
            local drawx1 = 70 + (30 * j)
            local drawy1 = 25 + (25 * i)
            love.graphics.setColor(1,1,1,0.5)
            love.graphics.rectangle("line", drawx1, drawy1, 30, 25)

            -- now fill the cell if a gear can access this speed
            if j >= cars[1].gearbox[i][1] and j <= cars[1].gearbox[i][2] then
                love.graphics.setColor(0,1,0,0.75)
                love.graphics.rectangle("fill", drawx1, drawy1, 30, 25)
            end
        end
    end
end

function race.keypressed( key, scancode, isrepeat )
	-- this is in keypressed because the keyrepeat needs to be detected.

	local translatefactor = 10 * ZOOMFACTOR		-- screen moves faster when zoomed in

	local leftpressed = love.keyboard.isDown("left")
	local rightpressed = love.keyboard.isDown("right")
	local uppressed = love.keyboard.isDown("up")
	local downpressed = love.keyboard.isDown("down")
	local shiftpressed = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")	-- either shift key will work

	-- adjust translatex/y based on keypress combinations
	if shiftpressed then translatefactor = translatefactor * 2 end	-- ensure this line is above the lines below
	if leftpressed then TRANSLATEX = TRANSLATEX - translatefactor end
	if rightpressed then TRANSLATEX = TRANSLATEX + translatefactor end
	if uppressed then TRANSLATEY = TRANSLATEY - translatefactor end
	if downpressed then TRANSLATEY = TRANSLATEY + translatefactor end
end

function race.keyreleased(key, scancode)
	-- this is keyreleased because we detect just a single stroke
	if scancode == "kp5" then
		ZOOMFACTOR = 0.7
		TRANSLATEX = SCREEN_WIDTH / 2
		TRANSLATEY = SCREEN_HEIGHT / 2
	end

	if scancode == "-" then
		ZOOMFACTOR = ZOOMFACTOR - 0.05
	end
	if scancode == "=" then
		ZOOMFACTOR = ZOOMFACTOR + 0.05
	end

    if key == "e" then
        EDIT_MODE = not EDIT_MODE
        unselectAllCells()
    end

    if EDIT_MODE then
        local x, y = love.mouse.getPosition()
        local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y

        if key == "n" then  -- add new cell
            addNewCell(camx, camy, nil)
        end

        if key == "l" then  -- add new cell and link it to the previous cell
            addNewCell(camx, camy, previouscell)
            previouscell = #racetrack
        end

        if key == "delete" then
            local cell = getSelectedCell()
            if cell ~= nil then
                -- delete cell
                racetrack[cell] = nil
                unselectAllCells()
                previouscell = nil
            end
        end

        if key == "c" then
            -- toggle corner
            local cell = getSelectedCell()
            if cell ~= nil then
                racetrack[cell].isCorner = not racetrack[cell].isCorner
            end
        end

        if key == "s" then          -- lower case s for 'speed' or uppercase S for SAVE
            -- save the track
            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                local success = fileops.saveRaceTrack(racetrack)
                if success then
                    lovelyToasts.show("Track saved", 10, "middle")
                else
                    lovelyToasts.show("Error during save", 10, "middle")
                end
            else
                local cell = getSelectedCell()
                if cell ~= nil then     -- increment the speed check
                    if racetrack[cell].speedCheck == nil then
                        racetrack[cell].speedCheck = 1
                    else
                        racetrack[cell].speedCheck = racetrack[cell].speedCheck + 1
                    end
                    if racetrack[cell].speedCheck > 3 then
                        racetrack[cell].speedCheck = nil
                    end

                    -- -- map all corner cells in front of this cell as a speedcheck
                    --! not yet working. Stack overflow
                    -- if racetrack[cell].isCorner then
                    --     local cornercells = {}
                    --     local newvalue = racetrack[cell].speedCheck
                    --     cornercells = getForwardCornerCells(cell)
                    --     for k, v in pairs(cornercells) do
                    --     	racetrack[v].speedCheck = newvalue
                    --     end
                    -- end
                end
            end
        end

        if key == "f" then          -- finish line
            local cell = getSelectedCell()
            if cell ~= nil then
                racetrack[cell].isFinish = not racetrack[cell].isFinish
            end
        end
    end
end

function race.mousereleased(rx, ry, x, y, button)

    lovelyToasts.mousereleased(x, y, button)

    local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y

    if EDIT_MODE == false then
        if currentplayer == 1 then
            if button == 1 then
                -- see if a gear is selected
                if cars[1].movesleft == 0 then
                    local smallestdist = 999999
                    local smallestkey = nil
                    for k, v in pairs(gearstick) do
                        local dist = cf.getDistance(rx, ry, v.x, v.y)
                        if dist > 0 and dist < smallestdist then
                            smallestdist = dist
                            smallestkey = k
                        end
                    end
                    if smallestdist <= 40 then
                        -- smallestkey is the gear selected
                        local desiredgear = smallestkey
                        local currentgear = cars[1].gear
                        local gearchange = desiredgear - currentgear

                        if gearchange >= -1 and gearchange <= 1 then
                            -- a shift up/down or same gear is legit
                            cars[1].gear = desiredgear
                            addCarMoves(1)      -- car index
                        else
                            if cars[1].wpgearbox == 0 then
                                -- gearbox damaged. Can only shift one gear. Ignore this click
                                lovelyToasts.show("Gearbox damaged. Can only shift one gear", 10, "middle")
                            else
                                if gearchange == -2 then -- a rapid shift down. Damage gearbox
                                    cars[1].wpgearbox = cars[1].wpgearbox - 1
                                    cars[1].gear = desiredgear
                                    addCarMoves(1)      -- car index
                                    lovelyToasts.show("Gearbox point used", 15, "middle")
                                elseif gearchange == -3 then -- a rapid shift down. Damage gearbox
                                    cars[1].wpgearbox = cars[1].wpgearbox - 1
                                    cars[1].wpbrakes = cars[1].wpbrakes - 1
                                    cars[1].gear = desiredgear
                                    addCarMoves(1)      -- car index
                                    lovelyToasts.show("Gearbox and brake point used", 15, "middle")
                                elseif gearchange == -4 then -- a rapid shift down. Damage gearbox
                                    cars[1].wpgearbox = cars[1].wpgearbox - 1
                                    cars[1].wpbrakes = cars[1].wpbrakes - 1
                                    cars[1].wpengine = cars[1].wpengine - 1
                                    cars[1].gear = desiredgear
                                    addCarMoves(1)      -- car index
                                    lovelyToasts.show("Gearbox, brake and engine point used", 15, "middle")
                                else
                                    -- illegal shift. Do nothing
                                end
                            end
                        end
                    end
                end
            end
            if button == 2 then
                -- try to move the car to the selected cell if linked
                if not cars[1].isEliminated then
                    if cars[1].movesleft > 0 then
                        local currentcell = cars[1].cell
                        local desiredcell = getSelectedCell()

                        if desiredcell ~= nil then
                            if racetrack[currentcell].link[desiredcell] == true then
                                -- move is legal
                                executeLegalMove(1, desiredcell)
                                if cars[1].movesleft < 1 then
                                    cars[1].movesleft = 0
                                    cars[1].turns = cars[1].turns + 1
                                    incCurrentPlayer()
                                end
                            end
                        else
                            -- no desired cell. Do nothing. Move not legal
                        end
                    end
                else
                    cars[1].movesleft = 0
                    incCurrentPlayer()
                end
            end
        end
    else        -- edit mode = true
        -- edit mode = true
        if button == 2 then
            local cell1 = getSelectedCell()
            local cell2 = getClosestCell(camx, camy)

            if cell1 ~= nil and cell2 ~= nil then
                -- link cell1 to cell2
                racetrack[cell1].link[cell2] = not racetrack[cell1].link[cell2]
            end
        end
    end
end

function race.wheelmoved(x, y)

    if not EDIT_MODE then
    	if y > 0 then
    		-- wheel moved up. Zoom in
    		ZOOMFACTOR = ZOOMFACTOR + 0.05
    	end
    	if y < 0 then
    		ZOOMFACTOR = ZOOMFACTOR - 0.05
    	end
    	if ZOOMFACTOR > 3 then ZOOMFACTOR = 3 end
    	print("Zoom factor = " .. ZOOMFACTOR)
    else
        -- in edit mode with a selected cell. Rotate it
        local cell = getSelectedCell()
        if cell == nil then -- no cell selected. Zoom
            -- zoom
            if y > 0 then
        		-- wheel moved up. Zoom in
        		ZOOMFACTOR = ZOOMFACTOR + 0.05
        	end
        	if y < 0 then
        		ZOOMFACTOR = ZOOMFACTOR - 0.05
        	end
        	-- if ZOOMFACTOR < 0.8 then ZOOMFACTOR = 0.8 end
        	if ZOOMFACTOR > 3 then ZOOMFACTOR = 3 end
        	print("Zoom factor = " .. ZOOMFACTOR)
        else
            if y < 0 then -- mouse wheel down
                if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                    -- rotate a little bit
                    racetrack[cell].rotation = racetrack[cell].rotation + 0.05
                else
                    -- rotate normal
                    racetrack[cell].rotation = racetrack[cell].rotation + 0.1
                end
            else
                if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                    racetrack[cell].rotation = racetrack[cell].rotation - 0.05
                else
                    racetrack[cell].rotation = racetrack[cell].rotation - 0.1
                end
            end
            if racetrack[cell].rotation < 0 then racetrack[cell].rotation = (2 * math.pi) end
            if racetrack[cell].rotation > (2 * math.pi) then racetrack[cell].rotation = 0 end
        end
    end
end

function race.mousepressed(x, y, button, istouch)
    local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y
    local cell = getClosestCell(camx, camy)
    unselectAllCells()
    if cell ~= nil then
        racetrack[cell].isSelected = true
    end
end

function race.mousemoved(x, y, dx, dy, istouch)
    local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y

    if love.mouse.isDown(3) then
        TRANSLATEX = TRANSLATEX - dx
        TRANSLATEY = TRANSLATEY - dy
    end

    if EDIT_MODE then
        if love.mouse.isDown(1) then
            local cell = getSelectedCell()
            if cell ~= nil then
                racetrack[cell].x = camx
                racetrack[cell].y = camy
            end
        end
    end
end

function race.draw()

    cam:attach()

    -- draw the track background first
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(IMAGE[enum.imageTrack], 0, 0, 0, 0.75, 0.75)

    -- draw the cars
    for i = 1, numofcars do
        local drawx = racetrack[cars[i].cell].x
        local drawy = racetrack[cars[i].cell].y

        if cars[i].isEliminated then
            love.graphics.setColor(1,0,0,1)     -- red for crash
        else
            love.graphics.setColor(1,1,1,1)     -- white
        end
        local rotation = racetrack[cars[i].cell].rotation
        if cars[i].isSpun then      -- draw car backwards
            rotation = rotation + math.pi   -- pi = half a circle (in radians)
            if rotation > 2 * math.pi then
                rotation = rotation - (2 * math.pi)
            end
        end
        love.graphics.draw(CARIMAGE[i], drawx, drawy, rotation , 1, 1, 32, 15)
    end

    -- draw number of moves left beside the mouse
    if currentplayer == 1 then
        if cars[1].movesleft > 0 then
            drawx, drawy = love.mouse.getPosition()
            drawx, drawy = cam:toWorld(drawx, drawy)

            love.graphics.setColor(1,1,1,1)     -- white
            if racetrack[cars[1].cell].isCorner then
                --! make the move left counter change colours here
                if cars[1].brakestaken >= racetrack[cars[1].cell].speedCheck then
                    love.graphics.setColor(0,1,0,1)
                else
                    love.graphics.setColor(1,1,0,1)
                end
            else
                love.graphics.setColor(1,1,1,1)     -- white
            end

            love.graphics.setFont(FONT[enum.fontCorporate])
            love.graphics.print(cars[1].movesleft, drawx + 20, drawy - 5)
            love.graphics.setFont(FONT[enum.fontDefault])
        end
    end

    -- draw the ghost, if there is one
    if currentplayer == 1 then
        if ghost ~= nil then        -- will be nil if no ghost.dat file exists
            if ghost[numberofturns] ~= nil then
                local ghostcell = ghost[numberofturns]

                local drawx = racetrack[ghostcell].x
                local drawy = racetrack[ghostcell].y
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.draw(IMAGE[enum.imageCar], drawx, drawy, racetrack[ghostcell].rotation , 1, 1, 32, 15)
            end
        end
    end

    -- draw any mouse line things
    if EDIT_MODE then       -- note there is another EDIT_MODE after camera detach

        -- draw the track cells and links
        for k, v in pairs(racetrack) do
            if v.x ~= nil then
                -- draw the dots
                love.graphics.setColor(1, 0, 1, 1)
                love.graphics.circle("fill", v.x, v.y, 5)
                -- draw the heading of the dot
                local x2, y2 = cf.addVectorToPoint(v.x, v.y, math.deg(v.rotation) + 90, 15)
                love.graphics.line(v.x, v.y, x2, y2)

                -- draw the cell number
                love.graphics.print(k, v.x + 6, v.y - 6)

                -- draw the cell images
                if v.isCorner then
                    love.graphics.setColor(1, 1, 0, 1)
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end

                if v.isFinish then
                    love.graphics.draw(IMAGE[enum.imageCellFinish], v.x, v.y, v.rotation, celllength / 64, cellwidth / 32, 16, 8)
                else
                    love.graphics.draw(IMAGE[enum.imageCell], v.x, v.y, v.rotation, celllength / 64, cellwidth / 32, 16, 8)
                end

                -- draw the speed limit
                if v.speedCheck ~= nil then
                    love.graphics.setColor(1,0,0,1)
                    love.graphics.print(v.speedCheck, v.x - 3, v.y + 3)
                    love.graphics.circle("line", v.x, v.y + 10, 12)
                end

                -- draw the selected cell over the normal cell
                if v.isSelected then
                    love.graphics.setColor(0, 1, 0, 1)
                    love.graphics.draw(IMAGE[enum.imageCellShaded], v.x, v.y, v.rotation, celllength / 64, cellwidth / 32, 16, 8)
                end
            end

            -- draw the links
            for q, w in pairs(v.link) do
                if w == true then
                    if racetrack[q] == nil then
                        -- this cell use to exist but now it's deleted
                        w = false
                    else
                        local x2 = racetrack[q].x
                        local y2 = racetrack[q].y
                        love.graphics.setColor(1, 0, 1, 0.5)
                        love.graphics.line(v.x, v.y, x2, y2)
                    end
                end
            end
        end


        if love.mouse.isDown(2) then
            local cell = getSelectedCell()
            if cell ~= nil then
                -- button 2 is being dragged from the selected cell
                local drawx1 = racetrack[cell].x
                local drawy1 = racetrack[cell].y

                local drawx2, drawy2 = love.mouse.getPosition()
                drawx2, drawy2 = cam:toWorld(drawx2, drawy2)

                love.graphics.setColor(1,1,1,1)
                love.graphics.line(drawx1, drawy1, drawx2, drawy2)
            end
        end
    end

    cam:detach()

    lovelyToasts.draw()     -- should this be before detach?

    -- draw the sidebar
    local drawx = SCREEN_WIDTH - sidebarwidth
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", drawx, 0, sidebarwidth, SCREEN_HEIGHT)

    drawx = drawx + 10
    drawy = 75

    love.graphics.setColor(1,1,1,1)

    love.graphics.print("Turns: " .. numberofturns, drawx, drawy)
    drawy = drawy + 35

    love.graphics.print("Player #" .. currentplayer, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Gear: " .. cars[currentplayer].gear, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Moves left: " .. cars[currentplayer].movesleft, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Stops in corner: " .. cars[currentplayer].brakestaken, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Tyre wear points: " .. cars[currentplayer].wptyres, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Brake wear points: " .. cars[currentplayer].wpbrakes, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Gearbox wear points: " .. cars[currentplayer].wpgearbox, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Engine wear points: " .. cars[currentplayer].wpengine, drawx, drawy)
    drawy = drawy + 35

    -- draw the gear stick on top of the sidebarwidth
    if currentplayer == 1 then
        drawGearStick(cars[1].gear)
    end

    if not EDIT_MODE then
        -- draw the topbar (gearbox matrix)
        drawGearboxMatrix()
    end

    -- edit mode
    if EDIT_MODE then
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("EDIT MODE", 50, 50)

        local drawx = SCREEN_WIDTH - sidebarwidth + 10
        local drawy = 450

        -- print the number of the selected cell
        local getcellnumber = getSelectedCell()
        if getcellnumber ~= nil then
            love.graphics.print("Cell #" .. getSelectedCell(), drawx, drawy)
            drawy = drawy + 35

            -- draw the links for the selected cell
            for k, v in pairs(racetrack[getcellnumber].link) do
                if v == true then
                    love.graphics.print("Links to " .. k, drawx, drawy)
                    drawy = drawy + 35
                end
            end
        end
    end
end

function race.update(dt)

    if #racetrack == 0 then
        loadRaceTrack()
        loadCars()
        loadGearStick()

        -- a one time reposition of camera
        TRANSLATEX = racetrack[cars[1].cell].x
        TRANSLATEY = racetrack[cars[1].cell].y
        cam:setPos(TRANSLATEX, TRANSLATEY)
    end

    pausetimer = pausetimer - dt
    if pausetimer < 0 then pausertimer = 0 end

    if currentplayer > 1 then
        if pausetimer <= 0 then
            moveBots()
        end
    else

    end

    lovelyToasts.update(dt)

    cam:setZoom(ZOOMFACTOR)
    cam:setPos(TRANSLATEX,	TRANSLATEY)
end

return race


-- table.sort(players, function(k1, k2)
--     if k1.turns > k2.turns then
--         return false
--     elseif k1.turns <= k2.turns and k1.distance <= k2.distance then
--         return true
--     elseif k1.turns <= k2.turns and k1.distance > k2.distance then
--         return false
--     else
--         return false
--     end
-- end)
