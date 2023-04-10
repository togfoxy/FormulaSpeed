race = {}

local racetrack = {}          -- the network of cells
local cars = {}               -- a table of cars
local numofcars = 6

local celllength = 128
local cellwidth = 64

local sidebarwidth = 250

local gearstick = {}            -- made this a table so I can do graphics stuff

local EDIT_MODE = false                -- true/false

local previouscell = nil                -- previous cell placed during link command
local numberofturns = 0

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
        previouscell = nil
    else
        previouscell = #racetrack       -- global
    end
    unselectAllCells()
end

local function getSelectedCell()
    for k, v in pairs(racetrack) do
        if v.isSelected then
            return k
        end
    end
    return nil
end

local function loadRaceTrack()
    -- loads the hardcoded track into the racetrack variable
    racetrack = fileops.loadRaceTrack()
    if racetrack == nil then
        racetrack = {}                  -- the load operation returned nil. Set back to empty table
        addNewCell(100,100, nil)
        print("No track found. Providing starting cell.")
    else
        print("Track loaded")
    end
end

local function loadCars()

    for i = 1, numofcars do
        cars[i] = {}
    end

    cars[1].cell = 1
    cars[1].gear = 0
    cars[1].wptyres = 6
    cars[1].wpbrakes = 3
    cars[1].wpgearbox = 3
    cars[1].wpbody = 3
    cars[1].wpengine = 3
    cars[1].wphandling = 2
    cars[1].movesleft = 0
    cars[1].brakestaken = 0             -- how many times did car stop in current corner
    cars[1].isEliminated = false
    cars[1].isSpun = false
    cars[1].overshootcount = 0              -- used for special rule when wptyres == 0
    cars[1].finishcount = 0                 -- how many times is the finish line crossed. Need 2 to win a 1 lap race

    -- gearbox
    cars[1].gearbox = {}
    cars[1].gearbox[1] = {1,1}
    cars[1].gearbox[2] = {2,2}
    cars[1].gearbox[3] = {3,3}
    cars[1].gearbox[4] = {4,4}
    cars[1].gearbox[5] = {5,5}
    cars[1].gearbox[6] = {6,6}

    -- randomise the gearbox. Example:
    -- gearbox[3][1] = the lowest value for gearbox 3
    -- gearbox[3][2] = the highest value for gearbox 3
    cars[1].gearbox[1][1] = 1
    cars[1].gearbox[1][2] = love.math.random(1, 3)

    cars[1].gearbox[2][1] = 2
    cars[1].gearbox[2][2] = love.math.random(1, 5)

    cars[1].gearbox[3][1] = love.math.random(3, 5)
    cars[1].gearbox[3][2] = love.math.random(7, 9)

    cars[1].gearbox[4][1] = love.math.random(6, 8)
    cars[1].gearbox[4][2] = love.math.random(11, 13)

    cars[1].gearbox[5][1] = love.math.random(10, 12)
    cars[1].gearbox[5][2] = love.math.random(19, 21)

    cars[1].gearbox[6][1] = love.math.random(20, 22)
    cars[1].gearbox[6][2] = love.math.random(29, 31)

end

local function loadGearStick()
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

    if smallestdist <= 15 then
        return smallestkey
    end
    return nil
end

local function addCarMoves(carindex)
    -- need to set the correct gear BEFORE calling this function
    -- assign a random number of moves based on new gear
    local low = cars[carindex].gearbox[cars[carindex].gear][carindex]
    local high = cars[carindex].gearbox[cars[carindex].gear][2]
    cars[carindex].movesleft = love.math.random(low, high)
end

local function checkForElimination(carindex)
    -- check all wear points
    if cars[carindex].wptyres < 0 then
        cars[carindex].isEliminated = true
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

        if key == "s" then          -- capital S
            -- save the track
            if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
                local success = fileops.saveRaceTrack(racetrack)
                print(success)
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
                print(success)
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

    local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y

    if EDIT_MODE == false then
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
                if smallestdist <= 30 then
                    -- smallestkey is the gear selected
                    local desiredgear = smallestkey
                    local currentgear = cars[1].gear
                    local gearchange = desiredgear - currentgear

                    if gearchange >= -1 and gearchange <= 1 then
                        -- a shift up/down or same gear is legit
                        cars[1].gear = desiredgear
                        addCarMoves(1)      -- car index
                    elseif gearchange == -2 then -- a rapid shift down. Damage gearbox
                        cars[1].wpgearbox = cars[1].wpgearbox - 1
                        cars[1].gear = desiredgear
                        addCarMoves(1)      -- car index
                    elseif gearchange == -3 then -- a rapid shift down. Damage gearbox
                        cars[1].wpgearbox = cars[1].wpgearbox - 1
                        cars[1].wpbrakes = cars[1].wpbrakes - 1
                        cars[1].gear = desiredgear
                        addCarMoves(1)      -- car index
                    elseif gearchange == -4 then -- a rapid shift down. Damage gearbox
                        cars[1].wpgearbox = cars[1].wpgearbox - 1
                        cars[1].wpbrakes = cars[1].wpbrakes - 1
                        cars[1].wpengine = cars[1].wpengine - 1
                        cars[1].gear = desiredgear
                        addCarMoves(1)      -- car index
                    else
                        -- illegal shift. Do nothing
                    end
                end
            end
        end
        if button == 2 then
            -- try to move the car to the selected cell if linked
            if cars[1].movesleft > 0 then
                local currentcell = cars[1].cell
                local desiredcell = getSelectedCell()

                if desiredcell ~= nil then
                    if racetrack[currentcell].link[desiredcell] == true then
                        -- move is legal
                        cars[1].cell = desiredcell
                        cars[1].movesleft = cars[1].movesleft - 1

                        -- if ending turn in corner then give credit for the braking
                        if cars[1].movesleft < 1 then
                            cars[1].movesleft = 0
                            numberofturns = numberofturns + 1
                            if racetrack[cars[1].cell].isCorner then
                                cars[1].brakestaken = cars[1].brakestaken + 1
                            end
                        end

                        -- if leaving corner, see if correct number of stops made
                        if racetrack[cars[1].cell].speedCheck ~= nil then
                            local brakescore = racetrack[cars[1].cell].speedCheck - cars[1].brakestaken
                            if brakescore <= 0 then
                                -- correct brakes taken. No problems
                            else
                                -- overshoot
                                if brakescore >= 2 then
                                    -- elimination
                                    print("Crashed out")
                                    cars[1].isEliminated = true
                                else
                                    -- see how many cells was overshot
                                    -- some complex rules about spinning etc
                                    if cars[1].wptyres > 0 then
                                        -- different set of rules
                                        if cars[1].wptyres > cars[1].movesleft then
                                            -- normal overshoot
                                            cars[1].wptyres = cars[1].wptyres - cars[1].movesleft
                                        elseif cars[1].wptyres == cars[1].movesleft then
                                            -- spin
                                            cars[1].wptyres = 0
                                            cars[1].isSpun = true
                                            cars[1].gear = 0
                                        elseif cars[1].movesleft > cars[1].wptyres then
                                            -- crash out
                                            cars[1].isEliminated = true
                                            cars[1].isSpun = true
                                        end
                                    elseif cars[1].wptyres == 0 then
                                        -- special rules when wptyres == 0
                                        if cars[1].movesleft == 1 then  -- oveshoot on zero tyres has an odd rule
                                            cars[1].overshootcount = cars[1].overshootcount + 1
                                            casr[1].isSpun = true
                                            cars[1].gear = 0

                                            if cars[1].overshootcount > 2 then
                                                -- crash out
                                                cars[1].isEliminated = true
                                                cars[1].isSpun = true
                                            end
                                        elseif cars[1].movesleft > 1 then
                                            -- crash
                                            cars[1].isEliminated = true
                                            cars[1].isSpun = true
                                        else
                                            error("Oops. Unexpected code executed", 394)
                                        end
                                    else
                                        error("Oops. Unexpected code executed", 399)
                                    end
                                end
                            end
                            cars[1].brakestaken = 0     -- reset for next corner
                        end

                        checkForElimination(1)      -- carindex

                        if racetrack[cars[1].cell].isFinish then
                            cars[1].finishcount = cars[1].finishcount + 1
                            if cars[1].finishcount > 1 then
                                -- WIN!
                                print("Lap time = " .. numberofturns)
                            end
                        end
                    end
                else
                end
            end
        end
    else
        -- edit mode = true
        if button == 2 then
            local cell1 = getSelectedCell()
            local cell2 = getClosestCell(camx, camy)

            print(cell1, cell2)

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
    	-- if ZOOMFACTOR < 0.8 then ZOOMFACTOR = 0.8 end
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

    -- draw the track
    for k, v in pairs(racetrack) do
        if v.x ~= nil then
            -- draw the dots
            love.graphics.setColor(1, 0, 1, 1)
            love.graphics.circle("fill", v.x, v.y, 5)
            -- draw the heading of the dot
            local x2, y2 = cf.addVectorToPoint(v.x, v.y, math.deg(v.rotation) + 90, 15)
            love.graphics.line(v.x, v.y, x2, y2)

            -- draw the cell number
            -- love.graphics.print(k, v.x + 6, v.y - 6)

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

    -- draw the cars
    for i = 1, 1 do
        local drawx = racetrack[cars[i].cell].x
        local drawy = racetrack[cars[i].cell].y

        if cars[i].isEliminated then
            love.graphics.setColor(1,0,0,1)     -- red for crash
        else
            love.graphics.setColor(1,1,1,1)     -- white
        end
        love.graphics.draw(IMAGE[enum.imageCar], drawx, drawy, racetrack[cars[i].cell].rotation , 1, 1, 32, 15)
    end

    -- draw any mouse line things
    if EDIT_MODE then       -- note there is another EDIT_MODE after camera detach
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

    -- draw the sidebar
    local drawx = SCREEN_WIDTH - sidebarwidth
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", drawx, 0, sidebarwidth, SCREEN_HEIGHT)

    drawx = drawx + 10
    drawy = 75

    love.graphics.setColor(1,1,1,1)

    love.graphics.print("Turns: " .. numberofturns, drawx, drawy)
    drawy = drawy + 35

    love.graphics.print("Cell #" .. cars[1].cell, drawx, drawy)
    drawy = drawy + 35
    -- draw the links for the current cell
    for k, v in pairs(racetrack[cars[1].cell].link) do
        if v == true then
            love.graphics.print("Links to " .. k, drawx, drawy)
            drawy = drawy + 35
        end
    end

    love.graphics.print("Gear: " .. cars[1].gear, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Moves left: " .. cars[1].movesleft, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Stops in corner: " .. cars[1].brakestaken, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Tyre wear points: " .. cars[1].wptyres, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Brake wear points: " .. cars[1].wpbrakes, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Gearbox wear points: " .. cars[1].wpgearbox, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Engine wear points: " .. cars[1].wpengine, drawx, drawy)
    drawy = drawy + 35

    -- draw the gear stick on top of the sidebarwidth
    -- draw the lines on the gear stick first
    love.graphics.line(gearstick[1].x, gearstick[1].y, gearstick[2].x, gearstick[2].y)
    love.graphics.line(gearstick[3].x, gearstick[3].y, gearstick[4].x, gearstick[4].y)
    love.graphics.line(gearstick[5].x, gearstick[5].y, gearstick[6].x, gearstick[6].y)
    local drawy = gearstick[1].y - (gearstick[1].y - gearstick[2].y) / 2
    love.graphics.line(gearstick[1].x, drawy, gearstick[6].x, drawy)
    -- draw the knobs
    for k, v in pairs(gearstick) do
        if cars[1].gear == k then           -- set the colour green if this gear is selected
            love.graphics.setColor(0,1,0,1)
        else
            love.graphics.setColor(1,1,1,1)
        end
        love.graphics.circle("fill", v.x, v.y, 10)
        -- draw the number
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(k, v.x - 4, v.y - 6)
    end

    -- draw the topbar (gearbox matrix)
    local topbarheight = 225
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH - sidebarwidth, topbarheight)

    -- draw the gearbox
    -- draw the speed along the top
    local drawx = 100
    local drawy = 25
    love.graphics.setColor(1,1,1,1)
    for i = 1, 40 do
        love.graphics.print(i, drawx + 10, drawy)       -- the +10 centres the text
        drawx = drawx + 30
    end

    -- draw the gears down the side
    drawx = 50
    drawy = 50
    for i = 1, 6 do
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Gear " .. i, drawx, drawy + 4)         -- the +4 centres the text
        drawy = drawy + 25
    end

    -- now fill in the matrix
    -- add white boxes everywhere

    for i = 1, 6 do
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

    -- edit mode
    if EDIT_MODE then
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("EDIT MODE", 50, 50)
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

    cam:setZoom(ZOOMFACTOR)
    cam:setPos(TRANSLATEX,	TRANSLATEY)
end

return race
