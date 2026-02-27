local component = require("component")
local sides = require("sides")
local nav = component.navigation

local Navlib = {}
Navlib.__index = Navlib

-- Ottiene la posizione corrente
function Navlib.getPosition()
    local x, y, z = nav.getPosition()
    local facing = nav.getFacing()
    return {x = x, y = y, z = z, facing = facing}
end

-- Ottiene la posizione corrente, return json
function Navlib.getPositionJson()
    local pos = Navlib.getPosition()
    local json = "{"
    json = json .. '"x":' .. tostring(pos.x) .. ','
    json = json .. '"y":' .. tostring(pos.y) .. ','
    json = json .. '"z":' .. tostring(pos.z) .. ','
    json = json .. '"facing":' .. tostring(pos.facing)
    json = json .. "}"
    return json
end

-- Ottiene il range operativo del navigation upgrade
function Navlib.getRange()
    return nav.getRange()
end

-- Trova waypoint in un range specificato
function Navlib.findWaypoints(range)
    return nav.findWaypoints(range)
end

return Navlib
