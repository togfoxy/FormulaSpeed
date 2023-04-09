fileops = {}

-- set the folders based on fused or not fused
local savedir = love.filesystem.getSourceBaseDirectory()
if love.filesystem.isFused() then
    savedir = savedir .. "\\savedata\\"
else
    savedir = savedir .. "/FormulaSpeed/savedata/"
end

function fileops.loadRaceTrack()

    local thistable = {}
    local savefile = savedir .. "racetrack.dat"

	if nativefs.getInfo(savefile) then
		contents, size = nativefs.read(savefile)
	    thistable = bitser.loads(contents)
        return thistable
    else
        return nil
    end
end


return fileops
