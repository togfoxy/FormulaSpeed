functions = {}

function functions.loadImages()
    IMAGE[enum.imageCell] = love.graphics.newImage("assets/images/cell_32x16.png")
    IMAGE[enum.imageCar] = love.graphics.newImage("assets/images/car_64x29.png")
    IMAGE[enum.imageTrack] = love.graphics.newImage("assets/images/track.jpg")

    -- IMAGE[enum.imageStadium] = love.graphics.newImage("assets/images/stadium.jpg")

end


return functions
