local component = require("component")
local geolyzer = component.geolyzer

local MAX_VOLUME = 64
local geolyze = {}

-- Scan a volume relative to the geolyzer and return a table with position + hardness
-- offsetX, offsetZ, offsetY = start position relative to geolyzer
-- sizeX, sizeZ, sizeY = dimensions of the area to scan
function geolyze.scanVolume(offsetX, offsetZ, offsetY, sizeX, sizeZ, sizeY)
    sizeX = sizeX or 1
    sizeZ = sizeZ or 1
    sizeY = sizeY or 1
    local raw = geolyzer.scan(offsetX, offsetZ, offsetY, sizeX, sizeZ, sizeY)
    local map = {}
    local i = 1
    for y = 0, sizeY - 1 do
        for z = 0, sizeZ - 1 do
            for x = 0, sizeX - 1 do
                if raw[i] then
                    table.insert(map, {
                        posx = offsetX + x,
                        posy = offsetY + y,
                        posz = offsetZ + z,
                        hardness = raw[i]
                    })
                end
                i = i + 1
            end
        end
    end
    return map
end

local function clamp(a, b, max)
    if a * b <= max then
        return a, b
    end
    local s = math.floor(math.sqrt(max))
    return math.min(a, s), math.min(b, math.floor(max / s))
end

function geolyze.scanVolumeMulti(offsetX, offsetZ, offsetY, sizeX, sizeZ, sizeY)
    sizeX = sizeX or 1
    sizeZ = sizeZ or 1
    sizeY = sizeY or 1

    local result = {}

    local sx, sz = clamp(sizeX, sizeZ, MAX_VOLUME)
    local sy = math.floor(MAX_VOLUME / (sx * sz))

    sy = math.max(sy, 1)

    for y = 0, sizeY - 1, sy do
        for z = 0, sizeZ - 1, sz do
            for x = 0, sizeX - 1, sx do
                local cx = math.min(sx, sizeX - x)
                local cz = math.min(sz, sizeZ - z)
                local cy = math.min(sy, sizeY - y)

                local chunk = geolyze.scanVolume(
                    offsetX + x,
                    offsetZ + z,
                    offsetY + y,
                    cx,
                    cz,
                    cy
                )

                for _, b in ipairs(chunk) do
                    table.insert(result, b)
                end
            end
        end
    end

    return result
end

function geolyze.scanVolumeMultiStream(
    offsetX, offsetZ, offsetY,
    sizeX, sizeZ, sizeY,
    onBlock
)
    local MAX_VOLUME = 64

    local function clamp(a, b, max)
        local s = math.floor(math.sqrt(max))
        return math.min(a, s), math.min(b, math.floor(max / s))
    end

    local sx, sz = clamp(sizeX, sizeZ, MAX_VOLUME)
    local sy = math.max(1, math.floor(MAX_VOLUME / (sx * sz)))

    for y = 0, sizeY - 1, sy do
        for z = 0, sizeZ - 1, sz do
            for x = 0, sizeX - 1, sx do
                local cx = math.min(sx, sizeX - x)
                local cz = math.min(sz, sizeZ - z)
                local cy = math.min(sy, sizeY - y)

                local chunk = geolyze.scanVolume(
                    offsetX + x,
                    offsetZ + z,
                    offsetY + y,
                    cx,
                    cz,
                    cy
                )

                for i = 1, #chunk do
                    onBlock(chunk[i])
                end
            end
        end
    end
end


-- Analyze a block on a specific side and return relative position + hardness + id
function geolyze.analyzeSide(side)
    local ok, info = pcall(function()
        return geolyzer.analyze(side)
    end)
    if not ok then
        return {posx = 0, posy = 0, posz = 0, hardness = nil, id = nil, error = "unsupported side"}
    end

    local pos = {posx = 0, posy = 0, posz = 0}

    -- Map side numbers to relative positions
    if side == 0 then pos.posy = -1        -- bottom
    elseif side == 1 then pos.posy = 1     -- top
    elseif side == 2 then pos.posz = -1    -- back
    elseif side == 3 then pos.posz = 1     -- front
    elseif side == 4 then pos.posx = 1     -- right
    elseif side == 5 then pos.posx = -1    -- left
    end

    pos.name = info.name
    pos.hardness = info.hardness
    pos.metadata = info.metadata
    pos.harvestLevel = info.harvestLevel
    pos.harvestTool = info.harvestTool
    pos.color = info.color
    pos.id = info.id
    pos.growth = pos.growth

    -- if gregtech tile entity
    pos.facing = info.facing
    pos.sensorInformation = info.sensorInformation

    -- EventHandlerAgriCraft
    pos.gain = info.gain
    pos.maxGain = info.maxGain
    pos.growth = info.growth
    pos.maxGrowth = info.maxGrowth
    pos.strength = info.strength
    pos.maxStrength = info.maxStrength

    -- ICropTile
    pos.crop_name = info.crop_name
    pos.crop_tier = info.crop_tier
    pos.crop_size = info.crop_size
    pos.crop_maxSize = info.crop_maxSize
    pos.crop_growth = info.crop_growth
    pos.crop_gain = info.crop_gain
    pos.crop_resistance = info.crop_resistance
    pos.crop_fertilizer = info.crop_fertilizer
    pos.crop_hydration = info.crop_hydration
    pos.crop_weedex = info.crop_weedex
    pos.crop_humidity = info.crop_humidity
    pos.crop_nutrients = info.crop_nutrients
    pos.crop_air = info.crop_air
    pos.crop_roots = info.crop_roots

    return pos
end


return geolyze
