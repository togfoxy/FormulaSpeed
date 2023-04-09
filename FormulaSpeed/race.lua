race = {}

local racetrack = {}          -- the network of cells
local cars = {}               -- a table of cars
local numofcells = 999        -- arbitrary number
local numofcars = 6

local celllength = 128
local cellwidth = 64

local sidebarwidth = 250

local gearstick = {}            -- made this a table so I can do graphics stuff

local GAME_MODE

local EDIT_MODE = false                -- true/false

local function loadRaceTrack()
    -- loads the hardcoded track into the racetrack variable

    -- initialise table
    for i = 1, numofcells do
        racetrack[i] = {}
        racetrack[i].link = {}
    end

    racetrack[1].x = 100
    racetrack[1].y = 100
    racetrack[1].rotation = 0       -- radians
    -- racetrack[1].link[1] = 2
    -- racetrack[1].link[2] = 4
end

local function loadCars()

    for i = 1, numofcars do
        cars[i] = {}
    end

    cars[1].cell = 1
    cars[1].gear = 0
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

local function getSelectedCell()
    for k, v in pairs(racetrack) do
        if v.isSelected then
            return k
        end
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

    -- print(TRANSLATEX, TRANSLATEY)
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
    end

end

function race.mousereleased(rx, ry, x, y, button)

    local camx, camy = cam:toWorld(x, y)	-- converts screen x/y to world x/y

    -- determine which cell is closest to the mouse click
    local smallestdist = 999999
    local smallestkey = nil
    for k, v in pairs(racetrack) do
        local dist = cf.getDistance(camx, camy, v.x, v.y)
        if dist > 0 and dist < smallestdist then
            smallestdist = dist
            smallestkey = k
        end
    end
    if smallestdist <= 15 then
        if racetrack[smallestkey].isSelected then
            racetrack[smallestkey].isSelected = false
        else
            -- unselect every cell
            for i = 1, numofcells do
                racetrack[i].isSelected = false
            end
            racetrack[smallestkey].isSelected = true
        end
    end

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
        -- try to move the car to the selected cell

        if cars[1].movesleft > 0 then
            local currentcell = cars[1].cell
            local desiredcell = getSelectedCell()

            for k, v in pairs(racetrack[currentcell].link) do
                if v == desiredcell then
                    -- link established. Move car
                    cars[1].cell = desiredcell
                    cars[1].movesleft = cars[1].movesleft - 1

                    -- if leaving corner, see if correct number of stops made
                    if racetrack[cars[1].cell].brakecheck == nil then
                        -- do nothing
                    else
                        if racetrack[cars[1].cell].brakecheck > 0 then
                            if cars[1].brakestaken >= racetrack[cars[1].cell].brakecheck then
                                -- all good. Do nothing
                                cars[1].brakestaken = 0         -- reset for next corner
                            else
                                print("Crash!")
                            end
                        end
                    end
                end
            end
        end
        if cars[1].movesleft == 0 then
            if racetrack[cars[1].cell].isBrakeZone then
                cars[1].brakestaken = cars[1].brakestaken + 1
            end
        end

    end
end

function race.wheelmoved(x, y)

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
end

function race.draw()

    cam:attach()

    -- draw the track background first
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(IMAGE[enum.imageTrack], 0, 0, 0, 1, 1)

    -- draw the track
    for k, v in pairs(racetrack) do
        if v.x ~= nil then
            -- dray the dots
            love.graphics.setColor(1, 0, 1, 1)
            love.graphics.circle("fill", v.x, v.y, 5)

            -- draw the cell number
            love.graphics.print(k, v.x + 6, v.y - 6)


            -- draw the cell images
            if v.isBrakeZone then
                love.graphics.setColor(1, 1, 0, 1)
            else

                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.draw(IMAGE[enum.imageCell], v.x, v.y, v.rotation, celllength / 64, cellwidth / 32, 16, 8)

            -- draw the selected cell
            if v.isSelected then
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("fill", v.x - celllength / 4, v.y - cellwidth / 4, celllength / 2, cellwidth / 2)
            end
        end

        -- draw the links
        for q, w in pairs(v.link) do
            if racetrack[w] ~= nil then
                if racetrack[w].x ~= nil then
                    love.graphics.setColor(1, 0, 1, 0.5)
                    love.graphics.line(v.x, v.y, racetrack[w].x, racetrack[w].y)
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
    cam:detach()

    -- draw the sidebar

    local drawx = SCREEN_WIDTH - sidebarwidth
    love.graphics.setColor(1, 1, 1, 0.25)
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

    -- edit mode?
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

-- local function loadRaceTrack()
--     -- loads the hardcoded track into the racetrack variable
--
--     -- initialise table
--     for i = 1, numofcells do
--         racetrack[i] = {}
--         racetrack[i].link = {}
--     end
--
--     racetrack[1].x = 100
--     racetrack[1].y = 100
--     racetrack[1].rotation = 0       -- radians
--     racetrack[1].link[1] = 2
--     racetrack[1].link[2] = 4
--
--     racetrack[2].x = racetrack[1].x + celllength / 4
--     racetrack[2].y = racetrack[1].y + cellwidth / 2
--     racetrack[2].rotation = 0       -- radians
--     racetrack[2].link[1] = 4
--     racetrack[2].link[2] = 5
--     racetrack[2].link[3] = 6
--
--     racetrack[3].x = racetrack[1].x
--     racetrack[3].y = racetrack[1].y + cellwidth
--     racetrack[3].rotation = 0       -- radians
--     racetrack[3].link[1] = 2
--     racetrack[3].link[2] = 6
--
--     racetrack[4].x = racetrack[1].x + celllength / 2
--     racetrack[4].y = racetrack[1].y
--     racetrack[4].rotation = 0       -- radians
--     racetrack[4].link[1] = 5
--     racetrack[4].link[2] = 7
--
--     racetrack[5].x = racetrack[2].x + celllength / 2
--     racetrack[5].y = racetrack[2].y
--     racetrack[5].rotation = 0       -- radians
--     racetrack[5].link[1] = 7
--     racetrack[5].link[2] = 8
--     racetrack[5].link[3] = 9
--
--     racetrack[6].x = racetrack[3].x + celllength / 2
--     racetrack[6].y = racetrack[3].y
--     racetrack[6].rotation = 0       -- radians
--     racetrack[6].link[1] = 5
--     racetrack[6].link[2] = 9
--
--     racetrack[7].x = racetrack[4].x + celllength / 2
--     racetrack[7].y = racetrack[4].y
--     racetrack[7].rotation = 0       -- radians
--     racetrack[7].link[1] = 8
--     racetrack[7].link[2] = 10
--
--     racetrack[8].x = racetrack[5].x + celllength / 2
--     racetrack[8].y = racetrack[5].y
--     racetrack[8].rotation = 0       -- radians
--     racetrack[8].link[1] = 11
--
--     racetrack[9].x = racetrack[6].x + celllength / 2
--     racetrack[9].y = racetrack[6].y
--     racetrack[9].rotation = 0       -- radians
--     racetrack[9].link[1] = 8
--     racetrack[9].link[2] = 12
--
--     racetrack[10].x = racetrack[7].x + celllength / 2
--     racetrack[10].y = racetrack[7].y
--     racetrack[10].rotation = 0       -- radians
--     racetrack[10].link[1] = 13
--     -- racetrack[11].link[1] = 17
--
--     racetrack[11].x = racetrack[8].x + celllength / 2
--     racetrack[11].y = racetrack[8].y + cellwidth / 2
--     racetrack[11].rotation = 0.7853       -- radians
--     racetrack[11].isBrakeZone = true
--     racetrack[11].link[1] = 15
--     racetrack[11].link[2] = 14
--
--     racetrack[12].x = racetrack[9].x + celllength / 2
--     racetrack[12].y = racetrack[9].y + cellwidth / 2 - 5
--     racetrack[12].rotation = 0.7853       -- radians
--     racetrack[12].isBrakeZone = true
--     racetrack[12].link[1] = 14
--
--     racetrack[13].x = racetrack[10].x + celllength / 2
--     racetrack[13].y = racetrack[10].y + cellwidth / 2 - 5
--     racetrack[13].rotation = 0.7853       -- radians
--     racetrack[13].isBrakeZone = true
--     racetrack[13].link[1] = 17
--
--     racetrack[14].x = racetrack[12].x + 25
--     racetrack[14].y = racetrack[12].y + cellwidth
--     racetrack[14].rotation = 1.5706       -- radians
--     racetrack[14].brakecheck = 1
--     racetrack[14].link[1] = 16
--     racetrack[14].link[2] = 20
--
--     racetrack[15].x = racetrack[11].x + 30
--     racetrack[15].y = racetrack[11].y + cellwidth
--     racetrack[15].rotation = 1.1       -- radians
--     racetrack[15].isBrakeZone = true
--     racetrack[15].link[1] = 16
--
--     racetrack[16].x = racetrack[15].x - 5
--     racetrack[16].y = racetrack[14].y + celllength / 4
--     racetrack[16].rotation = 1.5706       -- radians
--     racetrack[16].brakecheck = 1
--     racetrack[16].link[1] = 19
--     racetrack[16].link[2] = 20
--
--     racetrack[17].x = racetrack[13].x + 37
--     racetrack[17].y = racetrack[13].y + 58
--     racetrack[17].rotation = 1.2        -- radians
--     racetrack[17].isBrakeZone = true
--     racetrack[17].link[1] = 15
--     racetrack[17].link[2] = 18
--
--     racetrack[18].x = racetrack[17].x + 10
--     racetrack[18].y = racetrack[14].y
--     racetrack[18].rotation = 1.5706        -- radians
--     racetrack[18].isBrakeZone = true
--     racetrack[18].link[1] = 19
--     racetrack[18].link[2] = 16
--
--     racetrack[19].x = racetrack[18].x - 10
--     racetrack[19].y = racetrack[18].y + celllength / 2
--     racetrack[19].rotation = 1.5706        -- radians
--     racetrack[19].brakecheck = 1
--
--     racetrack[20].x = racetrack[14].x
--     racetrack[20].y = racetrack[14].y + celllength / 2
--     racetrack[20].rotation = 1.5706        -- radians
--
-- end
