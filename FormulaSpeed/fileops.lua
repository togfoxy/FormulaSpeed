fileops = {}

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
        print("Failed to load ghost.")
        return nil
    end
end

function fileops.loadTrackKnowledge()
    local thistable = {}
    local savefile = savedir .. "knowledge.dat"
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

function fileops.saveTrackKnowledge(knowledge)
    local savefile = savedir .. "knowledge.dat"
    local serialisedString = bitser.dumps(knowledge)
    local success, message = nativefs.write(savefile, serialisedString)
    return success
end

return fileops
