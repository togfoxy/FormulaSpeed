functions = {}

function functions.loadImages()
    IMAGE[enum.imageCell] = love.graphics.newImage("assets/images/cell_32x16.png")
    IMAGE[enum.imageCellShaded] = love.graphics.newImage("assets/images/cellshaded_32x16.png")
    IMAGE[enum.imageCellFinish] = love.graphics.newImage("assets/images/cellfinish_32x16.png")
    IMAGE[enum.imageCar] = love.graphics.newImage("assets/images/car_64x29.png")
    IMAGE[enum.imageTrack] = love.graphics.newImage("assets/images/track.jpg")






end


return functions
