podium = {}



function podium.draw()

    print("This is the podium:")
    print(inspect(PODIUM))

    table.sort(PODIUM, function(k1, k2)
        return k1..turns < k2.turns
    end)

    local drawx = 100
    local drawy = 100
    local txt

    love.graphics.print("Podium:", drawx, 65)
    for i = 1, #PODIUM do
        if PODIUM[i].turns < 999 then
            txt = PODIUM[i].car, PODIUM.turns
        else
            txt = PODIUM[i].car, "DNF"
        end
        love.graphics.print(txt, drawx, drawy)
        drawy = drawy + 35
    end
end

return podium
