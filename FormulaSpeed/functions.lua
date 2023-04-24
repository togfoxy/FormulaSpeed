functions = {}

function functions.loadImages()
    IMAGE[enum.imageCell] = love.graphics.newImage("assets/images/cell_32x16.png")
    IMAGE[enum.imageCellShaded] = love.graphics.newImage("assets/images/cellshaded_32x16.png")
    IMAGE[enum.imageCellFinish] = love.graphics.newImage("assets/images/cellfinish_32x16.png")
    IMAGE[enum.imageCar] = love.graphics.newImage("assets/images/car_64x29.png")
    IMAGE[enum.imageTrack] = love.graphics.newImage("assets/images/track.jpg")
    IMAGE[enum.imageOil] = love.graphics.newImage("assets/images/oil_64x28.png")
    IMAGE[enum.imageBrakeButton] = love.graphics.newImage("assets/images/brakebutton.png")
    IMAGE[enum.imageMainMenu] = love.graphics.newImage("assets/images/mainmenu.jpg")
    IMAGE[enum.imageGoldTrophy] = love.graphics.newImage("assets/images/trophy-gold.png")
    IMAGE[enum.imageSilverTrophy] = love.graphics.newImage("assets/images/trophy-silver.png")
    IMAGE[enum.imageBronzeTrophy] = love.graphics.newImage("assets/images/trophy-bronze.png")
    IMAGE[enum.imageFinish] = love.graphics.newImage("assets/images/finish.jpg")

    CARIMAGE[1] = love.graphics.newImage("assets/images/car1_64x29.png")
	CARIMAGE[2] = love.graphics.newImage("assets/images/car2_64x29.png")
	CARIMAGE[3] = love.graphics.newImage("assets/images/car3_64x29.png")
	CARIMAGE[4] = love.graphics.newImage("assets/images/car4_64x29.png")
	CARIMAGE[5] = love.graphics.newImage("assets/images/car5_64x29.png")
	CARIMAGE[6] = love.graphics.newImage("assets/images/car6_64x29.png")

end

function functions.loadFonts()
    FONT[enum.fontDefault] = love.graphics.newFont("assets/fonts/Vera.ttf", 12)
    FONT[enum.fontMedium] = love.graphics.newFont("assets/fonts/Vera.ttf", 14)
    FONT[enum.fontLarge] = love.graphics.newFont("assets/fonts/Vera.ttf", 18)
    FONT[enum.fontCorporate] = love.graphics.newFont("assets/fonts/CorporateGothicNbpRegular-YJJ2.ttf", 36)
    FONT[enum.fontalienEncounters48] = love.graphics.newFont("assets/fonts/aliee13.ttf", 48)

    love.graphics.setFont(FONT[enum.fontDefault])
end

function functions.loadTableFromFile(datfilename)
    -- inputs: datfilename eg racetrack.dat
    -- output: table or nil
    local thistable = {}
    local savefile = savedir .. datfilename
	if nativefs.getInfo(savefile) then
		contents, size = nativefs.read(savefile)
	    thistable = bitser.loads(contents)
        return thistable
    else
        return nil
    end
end

function functions.saveTableToFile(datfilename, table)
    -- inputs: datfilename eg racetrack.dat
    -- inputs: table = the table that needs to be serialised and save
    local savefile = savedir .. datfilename
    local serialisedString = bitser.dumps(table)
    local success, message = nativefs.write(savefile, serialisedString)
    return success
end

function functions.deleteFile(datfilename)
    local savefile = savedir .. datfilename
    return nativefs.remove(savefile)
end


return functions
