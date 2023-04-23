podium = {}

local podiumloaded = false
local shopitem = {}

function podium.mousereleased(rx, ry, x, y, button)
    -- call from love.mousereleased()

    local clickedButtonID = buttons.getButtonID(rx, ry)

    if clickedButtonID == enum.buttonPodiumExit then
        love.event.quit()
    elseif clickedButtonID == enum.buttonPodiumExit then

    end
end

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

function podium.draw()

    local drawx = 100
    local drawy = 100
    local txt

    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Podium:", drawx, drawy)
    drawy = drawy + 35
    love.graphics.print("Car #          Time", drawx, drawy)
    drawy = drawy + 35

    for i = 1, #PODIUM do
        if PODIUM[i].turns < 999 then
            txt = PODIUM[i].car .. "                " .. PODIUM[i].turns
        else
            txt = PODIUM[i].car .. "                DNF"
        end
        love.graphics.print(txt, drawx + 5, drawy)
        drawy = drawy + 35
    end

    drawShopItems()

    buttons.drawButtons()
end

function podium.update()

    if not podiumloaded then
        podiumloaded = true
        table.sort(PODIUM, function(k1, k2)
            return k1.turns < k2.turns
        end)

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

    local numofbuttons = 1      -- how many buttons on this form, assuming a single column
    local numofsectors = numofbuttons + 1

    -- button for exit
    local mybutton = {}
    local buttonsequence = 1            -- sequence on the screen
    mybutton.x = (SCREEN_WIDTH / 2) - 75
    mybutton.y = SCREEN_HEIGHT / 2
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
