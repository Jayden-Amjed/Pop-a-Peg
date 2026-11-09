-- Use the accepted item instruments on this gameplay instance while retaining
-- the existing bounded UI/physics cue pools and leaving the native bank intact.
local Native = require(script.Parent.SoundEffects)
local Engine = require(game:GetService("ReplicatedStorage").CatalogLibrary.GallerySoundEngine)
local GameSoundEffects = {}

function GameSoundEffects.new()
    return Engine.new(Native.new())
end

return GameSoundEffects
