constants = {}

function constants.load()

    GAME_VERSION = "0.01"

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
    TRAINER_MODE = true

    IMAGE = {}
    CARIMAGE = {}
    FONT = {}
    PODIUM = {}               -- where/if the car finished including number of turns


    cam = nil       -- camera

    enums.load()


end


return constants
