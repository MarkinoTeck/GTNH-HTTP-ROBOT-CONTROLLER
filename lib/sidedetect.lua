local robot = require("robot")
local sides = require("sides")

local sidedetect = {}

function sidedetect.detect(side)
    if side == sides.front then
        return robot.detect()
    elseif side == sides.top then
        return robot.detectUp()
    elseif side == sides.bottom then
        return robot.detectDown()
    else
        return false, "unsupported side"
    end
end

local function escape(str)
    return str:gsub('"', '\\"')
end

function sidedetect.detectAll()
    local sideList = {sides.bottom, sides.top, sides.front, sides.back, sides.left, sides.right}
    local json = "{"

    for i, side in ipairs(sideList) do
        local s, info = sidedetect.detect(side)
        json = json .. '"' .. sides[side] .. '":'
        json = json .. '{"success":' .. tostring(s) .. ',"info":"' .. escape(info) .. '"}'
        if i < #sideList then
            json = json .. ","
        end
    end

    json = json .. "}"
    return json
end

return sidedetect
