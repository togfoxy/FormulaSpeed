functions = {}

function functions.loadImages()
    IMAGE[enum.imageCell] = love.graphics.newImage("assets/images/cell_32x16.png")
    IMAGE[enum.imageCellShaded] = love.graphics.newImage("assets/images/cellshaded_32x16.png")
    IMAGE[enum.imageCellFinish] = love.graphics.newImage("assets/images/cellfinish_32x16.png")
    IMAGE[enum.imageCar] = love.graphics.newImage("assets/images/car_64x29.png")
    IMAGE[enum.imageTrack] = love.graphics.newImage("assets/images/track.jpg")

end

function functions.loadFonts()
    FONT[enum.fontDefault] = love.graphics.newFont("assets/fonts/Vera.ttf", 12)
    FONT[enum.fontMedium] = love.graphics.newFont("assets/fonts/Vera.ttf", 14)
    FONT[enum.fontLarge] = love.graphics.newFont("assets/fonts/Vera.ttf", 18)
    FONT[enum.fontCorporate] = love.graphics.newFont("assets/fonts/CorporateGothicNbpRegular-YJJ2.ttf", 36)

    love.graphics.setFont(FONT[enum.fontDefault])
end


return functions
