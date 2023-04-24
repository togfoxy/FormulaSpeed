podium = {}

local podiumloaded = false
local shopitem = {}
local car = {}
local career = {}

local function drawShopItems()

    local drawx = 1050
    local drawy = 250

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Gear #", drawx, drawy)
    drawx = drawx + 57
    love.graphics.print("Low", drawx, drawy)
    drawx = drawx + 50
    love.graphics.print("High", drawx, drawy)
    drawx = drawx + 50

    drawx = 1000
    drawy = 275

    for shopindex, gearitem in pairs(shopitem) do
       love.graphics.setColor(1,1,1,1)

       love.graphics.print("For sale: ", drawx, drawy)
       drawx = drawx + 65
       love.graphics.print(gearitem.gear, drawx, drawy)
       drawx = drawx + 50
       love.graphics.print(gearitem.lowestspeed, drawx, drawy)
       drawx = drawx + 50
       love.graphics.print(gearitem.highestspeed, drawx, drawy)
       drawx = drawx + 50

       drawx = 1000
       drawy = drawy + 50

    end
end

local function drawCareer()
    local drawx = 600
    local drawy = 300

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Career stats", drawx, drawy)
    drawy = drawy + 50
    for i = 1, #career do
        if career[i] ~= nil then
            love.graphics.print(i .. ": " .. career[i], drawx, drawy)
            drawy = drawy + 50
        end
    end

end

local function drawCarComponents()

    -- print(inspect(car.gearboxsettings))

    local drawx = 400
    local drawy = 250

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Gearbox configuration:", drawx, drawy)
    drawy = drawy + 30
    for i = 1, 6 do         -- six gears
        love.graphics.print("Gear " .. i .. " : " .. car.gearboxsettings[i][1] .. " - " .. car.gearboxsettings[i][2], drawx, drawy )
        drawy = drawy + 30
    end
end

function podium.keyreleased(key, scancode)
    if key == "ESCAPE" then
        cf.removeScreen(SCREEN_STACK)       -- should return to main menu
    end
end

function podium.mousereleased(rx, ry, x, y, button)
    -- call from love.mousereleased()

    local clickedButtonID = buttons.getButtonID(rx, ry)

    if clickedButtonID == enum.buttonPodiumExit then
        love.event.quit()
    elseif clickedButtonID == enum.buttonPodiumRestart then
        print("Saving player car to file")
        fun.saveTableToFile("playercar.dat", PLAYERCAR)
        cf.swapScreen(enum.sceneRace, SCREEN_STACK)
    end
end

function podium.draw()

    -- draw trophy
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(IMAGE[enum.imageGoldTrophy], 200, 200)
    love.graphics.draw(IMAGE[enum.imageSilverTrophy], 100, 250)
    love.graphics.draw(IMAGE[enum.imageBronzeTrophy], 300, 275)

    -- draw podium
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(FONT[enum.fontalienEncounters48])
    love.graphics.print("Podium", 175, 100, 0 , 1, 1)
    love.graphics.setFont(FONT[enum.fontDefault])

    for i = 1, #PODIUM do
        if i == 1 and PODIUM[i].turns < 999 then
            drawx = 225
            drawy = 325
        end
        if i == 2 and PODIUM[i].turns < 999 then
            drawx = 125
            drawy = 375
        end
        if i == 3 and PODIUM[i].turns < 999 then
            drawx = 325
            drawy = 400
        end
        if i == 4 and PODIUM[i].turns < 999 then
            drawx = 225
            drawy = 500
        end
        if i == 5 and PODIUM[i].turns < 999 then
            drawx = 225
            drawy = 550
        end
        if i == 6 and PODIUM[i].turns < 999 then
            drawx = 225
            drawy = 600
        end

        --! don't fort DNF

        -- love.graphics.print(txt, drawx + 5, drawy)
        love.graphics.draw(CARIMAGE[PODIUM[i].car], drawx, drawy)
        drawy = drawy + 35
    end

    -- drawShopItems()
    -- drawCarComponents()
    drawCareer()

    buttons.drawButtons()
end

function podium.update()

    if not podiumloaded then
        podiumloaded = true

        -- debug. load fake podium
        PODIUM = {}
        for i = 1, 6 do
            local thiswin = {}
            thiswin.car = i
            thiswin.turns = love.math.random(15, 24)
            table.insert(PODIUM, thiswin)
        end
        print(inspect((PODIUM)))

        table.sort(PODIUM, function(k1, k2)
            return k1.turns < k2.turns
        end)

        -- load car configuration
        -- car = fun.loadTableFromFile("playercar.dat")
        -- if car == nil then
        --     print("No car found")
        -- else
        --     print("Car loaded")
        -- end
        -- assert(car ~= nil)

        -- load career
        career = fun.loadTableFromFile("career.dat")
        if career == nil then career = {} end

        -- adjust career
        for i = 1, #PODIUM do
            if PODIUM[i].car == 1 then
                if career[i] == nil then career[i] = 0 end
                career[i] = career[i] + 1       -- i.e career[1] = 8 means player came first 8 times
            end
        end
        -- write career to file
        fun.saveTableToFile("career.dat", career)

        print("Career table:")
        print(inspect(career))

        -- determine which gears are on sale
        shopitem[1] = {}
        shopitem[1].gear = love.math.random(1,6)
        shopitem[2] = {}
        shopitem[2].gear = love.math.random(1,6)
        table.sort(shopitem, function(k1, k2)
            if k1.gear < k2.gear then
                return true
            else
                return false
            end
        end)

        -- random gear configuration
        for shopindex, gearitem in pairs(shopitem) do
            if gearitem.gear == 1 then
                gearitem.lowestspeed = 1
                gearitem.highestspeed = love.math.random(1, 3)
            elseif gearitem.gear == 2 then
                gearitem.lowestspeed = love.math.random(1, 3)
                gearitem.highestspeed = love.math.random(gearitem.lowestspeed, 5)       -- noting we don't want high to be lower than low
            elseif gearitem.gear == 3 then
                gearitem.lowestspeed = love.math.random(3, 5)
                gearitem.highestspeed = love.math.random(7, 9)
            elseif gearitem.gear == 4 then
                gearitem.lowestspeed = love.math.random(6, 8)
                gearitem.highestspeed = love.math.random(11, 13)
            elseif gearitem.gear == 5 then
                gearitem.lowestspeed = love.math.random(10, 12)
                gearitem.highestspeed = love.math.random(19, 21)
            elseif gearitem.gear == 6 then
                gearitem.lowestspeed = love.math.random(20, 22)
                gearitem.highestspeed = love.math.random(29, 31)
            end
        end



    end

    if TRAINER_MODE then
        cf.swapScreen(enum.sceneRace, SCREEN_STACK)
    end
end

function podium.loadButtons()
    -- call this from love.load()
    -- ensure buttons.drawButtons() is added to the scene.draw() function
    -- ensure scene.mousereleased() function is added

    local numofbuttons = 2      -- how many buttons on this form, assuming a single column
    local numofsectors = numofbuttons + 1

    -- button for restart
    local mybutton = {}
    local buttonsequence = 1            -- sequence on the screen
    mybutton.x = (SCREEN_WIDTH / 2) - 75
    mybutton.y = SCREEN_HEIGHT - 300
    mybutton.width = 125
    mybutton.height = 25
    mybutton.bgcolour = {169/255,169/255,169/255,1}
    mybutton.drawOutline = false
    mybutton.outlineColour = {1,1,1,1}
    mybutton.label = "Restart race"
    mybutton.image = nil
    mybutton.imageoffsetx = 20
    mybutton.imageoffsety = 0
    mybutton.imagescalex = 0.9
    mybutton.imagescaley = 0.3
    mybutton.labelcolour = {1,1,1,1}
    mybutton.labeloffcolour = {1,1,1,1}
    mybutton.labeloncolour = {1,1,1,1}
    mybutton.labelcolour = {0,0,0,1}
    mybutton.labelxoffset = 15

    mybutton.state = "on"
    mybutton.visible = true
    mybutton.scene = enum.scenePodium               -- change and add to enum
    mybutton.identifier = enum.buttonPodiumRestart     -- change and add to enum
    table.insert(GUI_BUTTONS, mybutton) -- this adds the button to the global table

    -- button for exit
    local mybutton = {}
    local buttonsequence = 2            -- sequence on the screen
    mybutton.x = (SCREEN_WIDTH / 2) - 75
    mybutton.y = SCREEN_HEIGHT - 200
    mybutton.width = 125
    mybutton.height = 25
    mybutton.bgcolour = {169/255,169/255,169/255,1}
    mybutton.drawOutline = false
    mybutton.outlineColour = {1,1,1,1}
    mybutton.label = "Exit"
    mybutton.image = nil
    mybutton.imageoffsetx = 20
    mybutton.imageoffsety = 0
    mybutton.imagescalex = 0.9
    mybutton.imagescaley = 0.3
    mybutton.labelcolour = {1,1,1,1}
    mybutton.labeloffcolour = {1,1,1,1}
    mybutton.labeloncolour = {1,1,1,1}
    mybutton.labelcolour = {0,0,0,1}
    mybutton.labelxoffset = 15

    mybutton.state = "on"
    mybutton.visible = true
    mybutton.scene = enum.scenePodium               -- change and add to enum
    mybutton.identifier = enum.buttonPodiumExit     -- change and add to enum
    table.insert(GUI_BUTTONS, mybutton) -- this adds the button to the global table


end

return podium
