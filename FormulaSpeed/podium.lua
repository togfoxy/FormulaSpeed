podium = {}



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
end

return podium
