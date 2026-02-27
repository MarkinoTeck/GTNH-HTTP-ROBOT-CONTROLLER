-- src/loop.lua
local HttpClient = require("lib/httpclient")
local RobotUtils = require("lib/robot_utils")
local Sender     = require("lib/sender")
local Commands   = require("src/commands")

local Loop = {}
local conf

function Loop.init(config)
    conf = config
end

local function dispatch(parts)
    local command = parts[1]

    if command == "wait-a-bit"
        then os.sleep(10)

    elseif command == "move" then
        Commands.move(parts[2])
        Sender.position()

    elseif command == "update_inventory" then
        Sender.inventoryData()

    elseif command == "scanandbreak" then
        Commands.scanAndBreak(
            parts[2],
            tonumber(parts[3]),
            tonumber(parts[4]),
            tonumber(parts[5])
        )

    elseif command == "getblocks" then
        Sender.touchingBlocks()
    elseif command == "scan" then
        Sender.blocksRadius(5)

    elseif command == "factoryReset" then
        conf:set("id",         false)
        conf:set("configured", false)
        conf:save()

    elseif command == "getItem" then
        Commands.getItem(parts[2], parts[3], parts[4])
    elseif command == "ceckItem" then
        Commands.checkItem(parts[2], parts[3])

    elseif command == "equip" then
        Commands.equip()
    elseif command == "placedown" then
        Commands.placeDown(parts)
    elseif command == "placeup" then
        Commands.placeUp(parts)
    elseif command == "use" then
        Commands.use(parts)

    else
        print("Unknown command: " .. tostring(command))
    end
end

function Loop.tick()
    Sender.batteryLevel()

    local raw = HttpClient.get(conf:get("ip") .. "/coda/" .. conf:get("id"))

    if raw == nil then
        return
    end

    raw = raw:gsub("%s+", "")

    if raw == "" then
        os.sleep(5)
        return
    end

    print(raw)
    dispatch(RobotUtils.split(raw, ","))
end

return Loop
