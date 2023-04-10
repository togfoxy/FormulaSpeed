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

function fileops.loadGhost()
    local thistable = {}
    local savefile = savedir .. "ghost.dat"
	if nativefs.getInfo(savefile) then
		contents, size = nativefs.read(savefile)
	    thistable = bitser.loads(contents)
        return thistable
    else
        return nil
    end
end

function fileops.saveRaceTrack(racetrack)
    local savefile = savedir .. "racetrack.dat"
    local serialisedString = bitser.dumps(racetrack)
    local success, message = nativefs.write(savefile, serialisedString)
    return success
end

function fileops.saveGhost(history)
    local savefile = savedir .. "ghost.dat"
    local serialisedString = bitser.dumps(history)
    local success, message = nativefs.write(savefile, serialisedString)
    return success
end

return fileops
