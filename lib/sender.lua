-- lib/sender.lua
local component     = require("component")
local computer      = require("computer")
local robot_api     = require("robot")

local HttpClient    = require("lib/httpclient")
local Navlib        = require("lib/navlib")
local gz            = require("lib/geolyzer")
local JsonEncode    = require("lib/jsonEncode")
local inventoryData = require("lib/inventoryData")

local Sender        = {}
local conf

function Sender.init(config)
    conf = config
end

local function baseUrl()
    return conf:get("ip")
end

local function robotId()
    return conf:get("id")
end

local function post(endpoint, body)
    return HttpClient.post(baseUrl() .. endpoint, body)
end

function Sender.error(errorMsg)
    print("Sending error to server...")
    local pos = Navlib.getPositionJson()
    post("/postError", '{"error":"' .. errorMsg .. '","id":' .. robotId() .. ',"pos":' .. pos .. '}')
    print("Done.")
end

function Sender.batteryLevel()
    print("Sending battery level...")
    ---@diagnostic disable-next-line: undefined-field
    post("/battery", '{"battery":' .. computer.energy() .. ',"id":' .. robotId() .. '}')
    print("Done.")
end

function Sender.position()
    print("Sending position...")
    local pos = Navlib.getPositionJson()
    post("/updatePosition", '{"id":' .. robotId() .. ',"pos":' .. pos .. '}')
    print("Done.")
end

function Sender.inventoryData()
    if not component.isAvailable("inventory_controller") then
        print("Skipping inventoryData: inventory_controller upgrade not installed.")
        return
    end
    if not component.isAvailable("robot") then
        print("Skipping inventoryData: robot component not available.")
        return
    end

    print("Sending inventoryData...")
    local inv = JsonEncode.encode(inventoryData.getSlots())
    post("/updateInventory", '{"id":' .. robotId() .. ',"inv":' .. inv .. '}')
    print("Done.")
end

function Sender.message(msgType, msgNumber, msgString)
    print("Sending message...")
    local message = JsonEncode.encode({ type = msgType, number = msgNumber, string = msgString })
    post("/postMessage", '{"id":' .. robotId() .. ',"message":' .. message .. '}')
    print("Done.")
end

function Sender.blocksRadius(radius)
    local BATCH_SIZE = 64

    if radius <= 0 or radius > 32 then
        error("Scan radius error: " .. radius)
    end

    print("Scanning... (radius: " .. radius .. " blocks)")

    local robotPos = Navlib.getPosition()
    local payload  = { blocks = {} }

    gz.scanVolumeMultiStream(
        -radius, -radius, -radius,
        radius * 2 + 1, radius * 2 + 1, radius * 2 + 1,
        function(b)
            table.insert(payload.blocks, {
                x        = robotPos.x + b.posx,
                y        = robotPos.y + b.posy,
                z        = robotPos.z + b.posz,
                hardness = b.hardness,
            })

            if #payload.blocks >= BATCH_SIZE then
                post("/storeBlocks", JsonEncode.encode(payload))
                payload.blocks = {}
            end
        end
    )

    if #payload.blocks > 0 then
        post("/storeBlocks", JsonEncode.encode(payload))
    end

    print("Done.")
end

function Sender.touchingEntities()
    local posData       = Navlib.getPosition()
    local pos           = { x = posData.x, y = posData.y, z = posData.z }
    local facing        = posData.facing

    local facingOffsets = {
        [2] = { [2] = { x = 0, y = 0, z = -1 }, [3] = { x = 0, y = 0, z = 1 }, [4] = { x = 1, y = 0, z = 0 }, [5] = { x = -1, y = 0, z = 0 } },
        [4] = { [2] = { x = 1, y = 0, z = 0 }, [3] = { x = -1, y = 0, z = 0 }, [4] = { x = 0, y = 0, z = -1 }, [5] = { x = 0, y = 0, z = 1 } },
        [3] = { [2] = { x = 0, y = 0, z = -1 }, [3] = { x = 0, y = 0, z = 1 }, [4] = { x = 1, y = 0, z = 0 }, [5] = { x = -1, y = 0, z = 0 } },
        [5] = { [2] = { x = 0, y = 0, z = 1 }, [3] = { x = 0, y = 0, z = -1 }, [4] = { x = -1, y = 0, z = 0 }, [5] = { x = 1, y = 0, z = 0 } },
    }

    local payload       = { origin = pos, blocks = {} }

    for side = 0, 5 do
        local blocked, kind

        if side == 0 then
            blocked, kind = robot_api.detectDown()
        elseif side == 1 then
            blocked, kind = robot_api.detectUp()
        elseif side == facing then
            blocked, kind = robot_api.detect()
        else
            goto continue
        end

        if kind == "entity" then
            local offset
            if side == 0 then
                offset = { x = 0, y = -1, z = 0 }
            elseif side == 1 then
                offset = { x = 0, y = 1, z = 0 }
            else
                offset = facingOffsets[facing][side]
            end

            table.insert(payload.blocks, {
                name     = "entity",
                hardness = 999,
                x        = pos.x + offset.x,
                y        = pos.y + offset.y,
                z        = pos.z + offset.z,
            })
        end

        ::continue::
    end

    if #payload.blocks > 0 then
        post("/storeBlocks", JsonEncode.encode(payload))
    end
end

function Sender.touchingBlocks()
    local posData = Navlib.getPosition()
    local pos     = { x = posData.x, y = posData.y, z = posData.z }
    local facing  = posData.facing

    print("Sending touching blocks...")

    local facingOffsets = {
        [3] = { [2] = { x = 0, y = 0, z = -1 }, [3] = { x = 0, y = 0, z = 1 }, [4] = { x = -1, y = 0, z = 0 }, [5] = { x = 1, y = 0, z = 0 } },
        [4] = { [2] = { x = 1, y = 0, z = 0 }, [3] = { x = -1, y = 0, z = 0 }, [4] = { x = 0, y = 0, z = -1 }, [5] = { x = 0, y = 0, z = 1 } },
        [2] = { [2] = { x = 0, y = 0, z = 1 }, [3] = { x = 0, y = 0, z = -1 }, [4] = { x = 1, y = 0, z = 0 }, [5] = { x = -1, y = 0, z = 0 } },
        [5] = { [2] = { x = -1, y = 0, z = 0 }, [3] = { x = 1, y = 0, z = 0 }, [4] = { x = 0, y = 0, z = 1 }, [5] = { x = 0, y = 0, z = -1 } },
    }

    local payload = { origin = pos, blocks = {} }

    for side = 0, 5 do
        local scan = gz.analyzeSide(side)
        if scan then
            local offset
            if side == 0 then
                offset = { x = 0, y = -1, z = 0 }
            elseif side == 1 then
                offset = { x = 0, y = 1, z = 0 }
            else
                offset = facingOffsets[facing][side]
                print(facing, side, offset)
            end

            table.insert(payload.blocks, {
                hardness = scan.hardness,
                name     = scan.name,
                x        = pos.x + offset.x,
                y        = pos.y + offset.y,
                z        = pos.z + offset.z,
            })
        end
    end

    post("/storeBlocks", JsonEncode.encode(payload))
    print("Done.")
end

return Sender
