-- lib/sender.lua
local component  = require("component")
local computer   = require("computer")
local HttpClient = require("lib/httpclient")
local JsonEncode = require("lib/jsonEncode")

local Sender = {}
local conf
local robot_api

function Sender.init(config, r_api)
    conf      = config
    robot_api = r_api
end

local function baseUrl() return conf:get("ip")    end
local function robotId() return conf:get("id")     end

local function post(endpoint, body)
    return HttpClient.post(baseUrl() .. endpoint, body)
end

-- lazy-loaded robot-only libs
local function nav()           return require("lib/navlib")        end
local function gz()            return require("lib/geolyzer")      end
local function inventoryData() return require("lib/inventoryData") end

function Sender.error(errorMsg)
    print("Sending error to server...")
    local pos = nav().getPositionJson()
    post("/postError", '{"error":"' .. errorMsg .. '","id":"' .. robotId() .. '","pos":' .. pos .. '}')
    print("Done.")
end

function Sender.batteryLevel()
    print("Sending battery level...")
    post("/battery", '{"battery":' .. computer.energy() .. ',"id":"' .. robotId() .. '"}')
    print("Done.")
end

function Sender.position()
    print("Sending position...")
    local pos = nav().getPositionJson()
    post("/updatePosition", '{"id":"' .. robotId() .. '","pos":' .. pos .. '}')
    print("Done.")
end

function Sender.inventoryData()
    if not component.isAvailable("inventory_controller") then
        print("Skipping inventoryData: inventory_controller upgrade not installed.")
        return
    end

    print("Sending inventoryData...")
    local inv = JsonEncode.encode(inventoryData().getSlots())
    post("/updateInventory", '{"id":"' .. robotId() .. '","inv":' .. inv .. '}')
    print("Done.")
end

function Sender.message(msgType, msgNumber, msgString)
    print("Sending message...")
    local message = JsonEncode.encode({ type = msgType, number = msgNumber, string = msgString })
    post("/postMessage", '{"id":"' .. robotId() .. '","message":' .. message .. '}')
    print("Done.")
end

function Sender.scanBlocksRadius(scan_id, radius)
    local BATCH_SIZE = 64

    if radius <= 0 or radius > 32 then
        error("Scan radius error: " .. radius)
    end

    print("Scanning area for schematic... (radius: " .. radius .. " blocks)")

    local robotPos = nav().getPosition()
    local payload  = { mc_id = robotId(), scan_id = scan_id, blocks = {} }

    gz().scanVolumeMultiStream(
        -radius, -radius, -radius,
        radius * 2 + 1, radius * 2 + 1, radius * 2 + 1,
        function(b)
            table.insert(payload.blocks, {
                pos = {
                    x = robotPos.x + b.posx,
                    y = robotPos.y + b.posy,
                    z = robotPos.z + b.posz,
                },
                hardness = b.hardness,
            })

            if #payload.blocks >= BATCH_SIZE then
                post("/scanBlocks", JsonEncode.encode(payload))
                payload.blocks = {}
            end
        end
    )

    if #payload.blocks > 0 then
        post("/scanBlocks", JsonEncode.encode(payload))
    end

    print("Done.")
end

function Sender.blocksRadius(radius)
    local BATCH_SIZE = 64

    if radius <= 0 or radius > 32 then
        error("Scan radius error: " .. radius)
    end

    print("Scanning... (radius: " .. radius .. " blocks)")

    local robotPos = nav().getPosition()
    local payload  = { mc_id = robotId(), blocks = {} }

    gz().scanVolumeMultiStream(
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
    local posData = nav().getPosition()
    local pos     = { x = posData.x, y = posData.y, z = posData.z }
    local facing  = posData.facing

    local facingOffsets = {
        [2] = { [2]={x=0,y=0,z=-1}, [3]={x=0,y=0,z=1},  [4]={x=1,y=0,z=0},  [5]={x=-1,y=0,z=0} },
        [3] = { [2]={x=0,y=0,z=-1}, [3]={x=0,y=0,z=1},  [4]={x=1,y=0,z=0},  [5]={x=-1,y=0,z=0} },
        [4] = { [2]={x=1,y=0,z=0},  [3]={x=-1,y=0,z=0}, [4]={x=0,y=0,z=-1}, [5]={x=0,y=0,z=1}  },
        [5] = { [2]={x=0,y=0,z=1},  [3]={x=0,y=0,z=-1}, [4]={x=-1,y=0,z=0}, [5]={x=1,y=0,z=0}  },
    }

    local payload = { origin = pos, blocks = {} }

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
    local posData = nav().getPosition()
    local pos     = { x = posData.x, y = posData.y, z = posData.z }
    local facing  = posData.facing

    print("Sending touching blocks...")

    local facingOffsets = {
        [2] = { [2]={x=0,y=0,z=1},  [3]={x=0,y=0,z=-1}, [4]={x=1,y=0,z=0},  [5]={x=-1,y=0,z=0} },
        [3] = { [2]={x=0,y=0,z=-1}, [3]={x=0,y=0,z=1},  [4]={x=-1,y=0,z=0}, [5]={x=1,y=0,z=0}  },
        [4] = { [2]={x=1,y=0,z=0},  [3]={x=-1,y=0,z=0}, [4]={x=0,y=0,z=-1}, [5]={x=0,y=0,z=1}  },
        [5] = { [2]={x=-1,y=0,z=0}, [3]={x=1,y=0,z=0},  [4]={x=0,y=0,z=1},  [5]={x=0,y=0,z=-1} },
    }

    local payload = { mc_id = robotId(), origin = pos, blocks = {} }

    for side = 0, 5 do
        local scan = gz().analyzeSide(side)
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
