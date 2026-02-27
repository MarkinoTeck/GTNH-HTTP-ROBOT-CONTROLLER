-- src/commands.lua
local component     = require("component")
local robot_api     = require("robot")

local HttpClient    = require("lib/httpclient")
local Navlib        = require("lib/navlib")
local JsonEncode    = require("lib/jsonEncode")
local ae2_wireless  = require("lib/ae2")
local Scanlib       = require("lib/scanlib")
local inventoryData = require("lib/inventoryData")
local Logger        = require("lib/logger")
local Sender        = require("lib/sender")
local RobotUtils    = require("lib/robot_utils")

local Commands      = {}
local conf

function Commands.init(config)
    conf = config
end

local MOVE_HANDLERS = {
    forward  = function() return robot_api.forward() end,
    backward = function() return robot_api.back() end,
    up       = function() return robot_api.up() end,
    down     = function() return robot_api.down() end,
    left     = function()
        robot_api.turnLeft()
        return true
    end,
    right    = function()
        robot_api.turnRight()
        return true
    end,
}

function Commands.move(direction)
    local handler = MOVE_HANDLERS[direction]
    if not handler then
        Logger.error("Unknown move direction: " .. tostring(direction))
        return
    end

    local moved, reason = handler()

    if not moved then
        Logger.error("Movement failed: " .. direction .. " | reason: " .. tostring(reason))
        if reason == "entity" then
            Sender.touchingEntities()
        else
            Sender.blocksRadius(5)
            Sender.touchingBlocks()
        end
        Sender.error("obstacleFound")
    end
end

local STATUS_MESSAGES = {
    air         = "Air block",
    broken      = "Block broken",
    wrenched    = "Machine wrenched",
    unbreakable = "UNBREAKABLE BLOCK - Check tool! (continuing anyway)",
}

function Commands.scanAndBreak(scan_id, target_x, target_y, target_z)
    local pos = Navlib.getPosition()

    print("=== SCAN AND BREAK ===")
    print(string.format("Target:  %d,%d,%d", target_x, target_y, target_z))
    print(string.format("Current: %d,%d,%d", pos.x, pos.y, pos.z))

    if pos.x ~= target_x or pos.y ~= (target_y + 1) or pos.z ~= target_z then
        print("ERROR: Wrong position!")
        Sender.error("wrongPosition")
    else
        -- slot 1 = pickaxe/tool, slot 2 = optional wrench, not inplemented yet
        local blockInfo, _, status = Scanlib.scanAndBreakBelow(
            { x = pos.x, y = pos.y, z = pos.z },
            1, 2
        )

        local payload = JsonEncode.encode({
            mc_id   = conf:get("id"),
            scan_id = scan_id,
            block   = blockInfo,
        })
        local _, err = HttpClient.post(conf:get("ip") .. "/scanBlock", payload)
        if err then
            print("Error sending data: " .. err)
        else
            print("Position marked as scanned")
        end

        local msg = STATUS_MESSAGES[status]
        if msg then
            print(msg)
        elseif status == "no_tool" then
            print("✗ ERROR: No tool found!")
            Sender.error("noTool")
        end
    end

    print("======================")
    Sender.inventoryData()
end

function Commands.getItem(itemName, count, slot)
    print(itemName, count)
    local _, err = ae2_wireless:takeItem(itemName, tonumber(count), tonumber(slot))
    if err then print(err) end
    Sender.inventoryData()
end

function Commands.checkItem(itemName, slot)
    local quantity, name = ae2_wireless:ceckItem(itemName, tonumber(slot))
    Sender.message("ae2-quantity", quantity, name)
end

function Commands.equip()
    inventoryData.equip()
    Sender.inventoryData()
end

local function resolveAndLog(label, placeFunc, parts)
    local desiredFacing = parts[2] or (label == "placeup" and "up" or "down")
    local posData       = Navlib.getPosition()
    local robotFacing   = posData.facing
    local side          = RobotUtils.getRelativeSide(robotFacing, desiredFacing)

    Logger.error(string.format("facing: %s side: %s command: %s, %s",
        robotFacing, side, parts[2] or "(nil)", desiredFacing))
    print(string.format("facing: %s side: %s command: %s, %s",
        robotFacing, side, parts[2] or "(nil)", desiredFacing))

    local done, err = placeFunc(side, true)
    if not done and err then print(err) end
    if done then Sender.touchingBlocks() end
    Sender.inventoryData()
end

function Commands.placeDown(parts)
    resolveAndLog("placedown", robot_api.placeDown, parts)
end

function Commands.placeUp(parts)
    resolveAndLog("placeup", robot_api.placeUp, parts)
end

function Commands.use(parts)
    local desiredFacing = parts[2] or "down"
    local posData       = Navlib.getPosition()
    local robotFacing   = posData.facing
    local side          = RobotUtils.getRelativeSide(robotFacing, desiredFacing)

    Logger.error(string.format("facing: %s side: %s command: %s, %s",
        robotFacing, side, parts[2], desiredFacing))
    print(string.format("facing: %s side: %s command: %s, %s",
        robotFacing, side, parts[2], desiredFacing))

    local done, output = robot_api.use(side, parts[3] == "true")
    if not done and output then
        print(output)
    elseif done then
        print("done? " .. tostring(output))
    end
end

return Commands
