constants = {}

function constants.load()

    GAME_VERSION = "1.1"

    SCREEN_STACK = {}

    -- SCREEN_WIDTH, SCREEN_HEIGHT = love.window.getDesktopDimensions(1)
    SCREEN_WIDTH, SCREEN_HEIGHT = res.getGame()

    -- camera
    ZOOMFACTOR = 0.7
    TRANSLATEX = cf.round(SCREEN_WIDTH / 2)		-- starts the camera in the middle of the ocean
    TRANSLATEY = cf.round(SCREEN_HEIGHT / 2)	-- need to round because this is working with pixels

    AUDIO = {}
    MUSIC_TOGGLE = true     --! will need to build these features later
    SOUND_TOGGLE = true

    TRAINER_MODE = false
    -- TRAINER_MODE = true

    IMAGE = {}
    CARIMAGE = {}
    FONT = {}
    PODIUM = {}               -- where/if the car finished including number of turns

    -- PLAYERCAR = {}              -- used to carry data between race and podium scene

    cam = nil       -- camera

    -- set the folders based on fused or not fused
    savedir = love.filesystem.getSourceBaseDirectory()
    if love.filesystem.isFused() then
        savedir = savedir .. "\\savedata\\"
        DEV_MODE = false
    else
        savedir = savedir .. "/FormulaSpeed/savedata/"
        DEV_MODE = true
    end

    enums.load()


end


return constants
