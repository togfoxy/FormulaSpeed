podium = {}

function podium.mousereleased(rx, ry, x, y, button)
    -- call from love.mousereleased()

    local clickedButtonID = buttons.getButtonID(rx, ry)
    
    if clickedButtonID == enum.buttonPodiumExit then
        love.event.quit()
    elseif clickedButtonID == enum.buttonPodiumExit then

    end
end

function podium.draw()

    table.sort(PODIUM, function(k1, k2)
        return k1.turns < k2.turns
    end)

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

    buttons.drawButtons()
end

function podium.loadButtons()
    -- call this from love.load()
    -- ensure buttons.drawButtons() is added to the scene.draw() function
    -- ensure scene.mousereleased() function is added

    local numofbuttons = 1      -- how many buttons on this form, assuming a single column
    local numofsectors = numofbuttons + 1

    -- button for exit
    local mybutton = {}
    local buttonsequence = 2            -- sequence on the screen
    mybutton.x = (SCREEN_WIDTH / 2) - 75
    mybutton.y = SCREEN_HEIGHT - 75
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
    mybutton.visible = false
    mybutton.scene = enum.scenePodium               -- change and add to enum
    mybutton.identifier = enum.buttonPodiumExit     -- change and add to enum
    table.insert(GUI_BUTTONS, mybutton) -- this adds the button to the global table


end

return podium
