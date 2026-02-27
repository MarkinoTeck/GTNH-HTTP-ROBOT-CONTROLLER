local component = require("component")
local robot = require("robot")
local sides = require("sides")

local Scanlib = {}
Scanlib.__index = Scanlib

-- Ottiene geolyzer se disponibile
local function getGeolyzer()
    if component.isAvailable("geolyzer") then
    ---@diagnostic disable-next-line: undefined-field
        return component.geolyzer
    end
    return nil
end

-- Scansiona il blocco sotto
function Scanlib.scanBlockBelow(robotPos)
    local gz = getGeolyzer()
    local block_info = {
        pos = {
            x = robotPos.x,
            y = robotPos.y - 1,
            z = robotPos.z
        },
        block_id = "minecraft:air",
        block_damage = 0,
        facing = nil
    }

    if not gz then
        print("Warning: Geolyzer not available")
        return block_info
    end

    local success, result = pcall(function()
        return gz.analyze(sides.bottom)
    end)

    if success and result then
        print("=== GEOLYZER ANALYZE RESULT ===")

        local function printData(tbl, indent)
            indent = indent or ""
            for k, v in pairs(tbl) do
                if type(v) == "table" then
                    print(indent .. k .. " = {")
                    printData(v, indent .. "  ")
                    print(indent .. "}")
                else
                    print(indent .. k .. " = " .. tostring(v))
                end
            end
        end

        printData(result)

        print("==============================")

        local blockId = result.name or result.id
        if blockId and blockId ~= "minecraft:air" and blockId ~= "air" then
            block_info.block_id = blockId
            block_info.block_damage = result.metadata or 0
            if result.gtMetaId then
                block_info.gtMetaId = result.gtMetaId
            end
            if result.sides then
                block_info.sides = result.sides
                block_info.ae2fcSides = result.ae2fcSides
                block_info.ae2_cable_multipart = true
                block_info.hasCable = result.hasCable
                if result.hasCable then
                    block_info.cableType = block_info.cableType
                end
            end

            print("Block: " .. blockId .. "/" .. (result.metadata or 0) .. " (hardness: " .. (result.hardness or "?") .. ")")

            if result.facing then
                block_info.facing = result.facing
            end

            if result.sensorInformation then
                print("SensorInfo: " .. tostring(result.sensorInformation))
                block_info.sensorInfo = result.sensorInformation
            end
        end
    else
        print("Error analyzing block: " .. tostring(result))
    end

    return block_info
end

-- Scansiona e rompi il blocco sotto
function Scanlib.scanAndBreakBelow(robotPos, toolSlot, wrenchSlot)
    toolSlot = toolSlot or 1
    wrenchSlot = wrenchSlot or 2  -- slot opzionale per wrench

    -- Prima scansiona
    local blockInfo = Scanlib.scanBlockBelow(robotPos)

    -- Se non è aria, prova a romperlo
    if blockInfo.block_id ~= "minecraft:air" and blockInfo.block_id ~= "air" then
        print("Attempting to break: " .. blockInfo.block_id .. "/" .. blockInfo.block_damage)

        local previousSlot = robot.select()

        -- Usa strumento normale (tipo pickaxe)
        robot.select(toolSlot)

        -- Verifica strumento
        local durability = robot.durability()
        if not durability then
            print("ERROR: No tool in slot " .. toolSlot)
            robot.select(previousSlot)
            return blockInfo, false, "no_tool"
        end

        if durability < 5 then
            print("WARNING: Tool almost broken! (" .. durability .. "%)")
        end

        print("Using tool from slot " .. toolSlot .. " (durability: " .. durability .. "%)")

        -- Prova a rompere (max 15 tentativi)
        local maxAttempts = 15
        local broken = false
        local lastReason = nil

        for attempt = 1, maxAttempts do
            local success, reason = robot.swingDown()
            lastReason = reason

            -- Verifica se il blocco è ancora lì
            local stillThere = robot.detectDown()
            if not stillThere then
                broken = true
                print("Block broken after " .. attempt .. " swing(s)")
                break
            end

            -- Se riceve "block" significa che non può rompere questo blocco
            if reason == "block" then
                -- Continua a provare per qualche tentativo (potrebbe essere questione di tempo)
                if attempt > 5 then
                    print("Cannot break this block (wrong tool or too hard)")
                    break
                end
            end

            os.sleep(0.15)
        end

        if not broken then
            print("FAILED to break block after " .. maxAttempts .. " attempts")
            print("Last reason: " .. (lastReason or "unknown"))
            print("Block ID: " .. blockInfo.block_id)
            print("This block may require:")
            print("  - Different tool type (pickaxe/wrench/shovel)")
            print("  - Better tool tier (stone/iron/diamond)")
            print("  - Special permissions/creative mode")

            robot.select(previousSlot)
            return blockInfo, false, "unbreakable"
        end

        -- Aspetta che gli items cadano
        os.sleep(0.3)

        -- Raccogli gli item
        for i = 1, 5 do
            robot.suckDown()
            os.sleep(0.1)
        end

        robot.select(previousSlot)
        print("Successfully broke: " .. blockInfo.block_id)
        return blockInfo, true, "broken"
    end

    print("Air block - skipping")
    return blockInfo, false, "air"
end

return Scanlib
