race = {}

local racetrack = {}          -- the network of cells
local cars = {}               -- a table of cars
local numofcars = 6

local celllength = 128
local cellwidth = 64

local sidebarwidth = 250

local gearstick = {}            -- made this a table so I can do graphics stuff

local GAME_MODE

local EDIT_MODE = false                -- true/false

local previouscell = nil                -- previous cell placed during link command

local function unselectAllCells()
    for k, v in pairs(racetrack) do
        v.isSelected = false
    end
end

local function addNewCell(x, y, previouscell)
    -- adds a new cell at the provided x/y
    -- makes the new cell the selected cell
    -- includes a link from previouscell to this cell if not nil

    local thisCell = {}
    thisCell.x = x
    thisCell.y = y
    thisCell.rotation = 0
    thisCell.isSelected = true
    thisCell.isCorner = false
    thisCell.speedCheck = nil               -- Number. Used at the exit of corners to check for overshoot
    thisCell.link = {}
    table.insert(racetrack, thisCell)

    if previouscell ~= nil then
        -- link from previous cell to this cell
        racetrack[previouscell].link[#racetrack] = true
    end

    unselectAllCells()
    previouscell = #racetrack
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
            addNewCell(camx, camy)
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

        if key == "s" then          -- lower case s for 'speed'
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
                    if math.abs(smallestkey - cars[1].gear) <= 1 then
                        cars[1].gear = smallestkey
                        cars[1].movesleft = cars[1].gear
                        GAME_MODE = enum.gamemodeMoveCar
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
                                else
                                    cars[1].wptyres = cars[1].wptyres - 1
                                    print("Overshoot!")
                                end
                            end
                            cars[1].brakestaken = 0     -- reset for next corner
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
                racetrack[cell1].link[cell2] = true
            end
        end
    end
end

function race.wheelmoved(x, y)

    if not EDIT_MODE or (EDIT_MODE and selectedcell == nil) then
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
        if y < 0 then -- mouse wheel down
            racetrack[selectedcell].rotation = racetrack[selectedcell].rotation + 0.1
        else
            racetrack[selectedcell].rotation = racetrack[selectedcell].rotation - 0.1
        end
        if racetrack[selectedcell].rotation < 0 then racetrack[selectedcell].rotation = (2 * math.pi) end
        if racetrack[selectedcell].rotation > (2 * math.pi) then racetrack[selectedcell].rotation = 0 end
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
            love.graphics.print(k, v.x + 6, v.y - 6)

            -- draw the cell images
            if v.isCorner then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.draw(IMAGE[enum.imageCell], v.x, v.y, v.rotation, celllength / 64, cellwidth / 32, 16, 8)

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
        love.graphics.setColor(1,1,1,1)
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
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", drawx, 0, sidebarwidth, SCREEN_HEIGHT)

    drawx = drawx + 10
    drawy = 75
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Cell #" .. cars[1].cell, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Gear: " .. cars[1].gear, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Moves left: " .. cars[1].movesleft, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Stops in corner: " .. cars[1].brakestaken, drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Tyre wear points: " .. cars[1].wptyres, drawx, drawy)
    drawy = drawy + 35

    -- draw the gear stick on top of the sidebarwidth
    -- draw the lines on the gear stick first
    love.graphics.line(gearstick[1].x, gearstick[1].y, gearstick[2].x, gearstick[2].y)
    love.graphics.line(gearstick[3].x, gearstick[3].y, gearstick[4].x, gearstick[4].y)
    love.graphics.line(gearstick[5].x, gearstick[5].y, gearstick[6].x, gearstick[6].y)
    local drawy = gearstick[1].y - (gearstick[1].y - gearstick[2].y) / 2
    love.graphics.line(gearstick[1].x, drawy, gearstick[6].x, drawy)
    for k, v in pairs(gearstick) do
        if cars[1].gear == k then           -- set the colour green if this gear is selected
            love.graphics.setColor(0,1,0,1)
        else
            love.graphics.setColor(1,1,1,1)
        end
        love.graphics.circle("fill", v.x, v.y, 10)
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
        GAME_MODE = enum.gamemodeGearSelect
    end

    cam:setZoom(ZOOMFACTOR)
    cam:setPos(TRANSLATEX, TRANSLATEY)
end

return race
