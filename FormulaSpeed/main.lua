-- rules: https://www.ultraboardgames.com/formula-d/game-rules.php

inspect = require 'lib.inspect'
-- https://github.com/kikito/inspect.lua

res = require 'lib.resolution_solution'
-- https://github.com/Vovkiv/resolution_solution

cf = require 'lib.commonfunctions'

Camera = require 'lib.cam11.cam11'
-- https://notabug.org/pgimeno/cam11

bitser = require 'lib.bitser'
-- https://github.com/gvx/bitser

nativefs = require 'lib.nativefs'
-- https://github.com/EngineerSmith/nativefs

lovelyToasts = require 'lib.lovelyToasts'
-- https://github.com/Loucee/Lovely-Toasts

-- these are core modules
require 'lib.buttons'
require 'enums'
require 'constants'
fun = require 'functions'
require 'fileops'

-- these are project specific
require 'mainmenu'
require 'race'
require 'podium'

function love.resize(w, h)
	res.resize(w, h)
end

function love.keypressed(key, scancode, isrepeat)

	if key == "escape" then
		love.event.quit()
	end

	local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.keypressed(key, scancode)
	elseif currentscene == enum.sceneMainMenu then
		mainmenu.keypressed(key, scancode)
    end
end

function love.keyreleased(key, scancode)
	local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.keyreleased(key, scancode)
    end
end

function love.mousereleased(x, y, button, isTouch)
	local rx, ry = res.toGame(x,y)
	local currentscene = cf.currentScreenName(SCREEN_STACK)

	if currentscene == enum.sceneRace then
		race.mousereleased(rx, ry, x, y, button)		-- need to send through the res adjusted x/y and the 'real' x/y
	elseif currentscene == enum.scenePodium then
		podium.mousereleased(rx, ry, x, y, button)
	elseif currentscene == enum.sceneMainMenu then
		mainmenu.mousereleased(rx, ry, x, y, button)
	end
end

function love.wheelmoved(x, y)
	local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.wheelmoved(x, y)
	end
end

function love.mousepressed(x, y, button, istouch)
	local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.mousepressed(x, y, button, istouch)
	end
end

function love.mousemoved(x, y, dx, dy, istouch )
	local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.mousemoved(x, y, dx, dy)
	end
end

function love.load()
    res.init({width = 1920, height = 1080, mode = 2})
	res.setMode(1920, 1080, {resizable = true})

	enums.load()
	constants.load()

	fun.loadFonts()
    -- fun.loadAudio()
	fun.loadImages()

	mainmenu.loadButtons()
	-- credits.loadButtons()
	race.loadButtons()
	podium.loadButtons()


	cam = Camera.new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 1)
	cam:setZoom(ZOOMFACTOR)
	cam:setPos(TRANSLATEX,	TRANSLATEY)

	love.window.setTitle("Speed " .. GAME_VERSION)

	cf.addScreen(enum.sceneMainMenu, SCREEN_STACK)
    -- cf.addScreen(enum.sceneRace, SCREEN_STACK)
	-- cf.addScreen(enum.scenePodium, SCREEN_STACK)

	love.keyboard.setKeyRepeat(true)

	lovelyToasts.options.tapToDismiss = true
	lovelyToasts.options.queueEnabled = true

	-- use this to debug the podium
	-- local thiswin = {}
	-- thiswin.car = 2
	-- thiswin.turns = 999
	-- table.insert(PODIUM, thiswin)
	-- local thiswin = {}
	-- thiswin.car = 1
	-- thiswin.turns = 15
	-- table.insert(PODIUM, thiswin)
	-- cf.addScreen(enum.scenePodium, SCREEN_STACK)

end

function love.draw()

    local currentscene = cf.currentScreenName(SCREEN_STACK)

    res.start()

    if currentscene == enum.sceneMainMenu then
        mainmenu.draw()
    elseif currentscene == enum.sceneCredits then
        -- credits.draw()
    elseif currentscene == enum.sceneRace then
        race.draw()
	elseif currentscene == enum.scenePodium then
		podium.draw()
    else
        error()
    end

    res.stop()

end

function love.update(dt)
    local currentscene = cf.currentScreenName(SCREEN_STACK)
	if currentscene == enum.sceneRace then
		race.update(dt)
	elseif currentscene == enum.scenePodium then
		podium.update(dt)
	end
end
