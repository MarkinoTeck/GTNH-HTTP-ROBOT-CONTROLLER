-- src/setup.lua
local HttpClient = require("lib/httpclient")
local JsonEncode = require("lib/jsonEncode")
local Sender     = require("lib/sender")
local RobotUtils = require("lib/robot_utils")
local computer   = require("computer")
local io         = require("io")

local Setup      = {}

local function promptOwner()
    while true do
        io.write("Enter owner id (min. 8 characters): ")
        local input = io.read("*l")
        if input and #input >= 8 then
            return input
        end
        print("Error: id must be valid. Try again.")
    end
end

function Setup.run(conf, robot_api_avible, robot_api)
    local owner = conf:get("owner")
    if not owner or type(owner) ~= "string" or #owner < 8 then
        print("=== OWNER SETUP ===")
        owner = promptOwner()
        conf:set("owner", owner)
        conf:save()
        print("Owner saved: " .. owner)
        print("===================")
    end

    -- On a computer: just save owner locally, never talk to the server
    if not robot_api_avible then
        if conf:get("configured") then
            print("Configuration already present.")
            print("Owner: " .. tostring(conf:get("owner")))
            print("ID:    " .. tostring(conf:get("id")))
            print("IP:    " .. tostring(conf:get("ip")))
        else
            print("Owner saved. Configuration will complete on first robot boot.")
        end
        print("")
        print("You can now transfer the disk drive and the EEPROM to the robot.")
        return true
    end

    -- On a robot: (already configured)
    if conf:get("configured") then
        robot_api.setLightColor(0x0000FF) -- blue
        Sender.position()
        Sender.batteryLevel()
        Sender.touchingBlocks()
        Sender.inventoryData()
        robot_api.setLightColor(0x00FF00) -- green
        return true
    end

    -- First boot on the robot: request a new device ID
    print("Requesting new device ID...")
    robot_api.setLightColor(0xFFFFFF) -- white

    local payload = {
        name          = robot_api.name(),
        owner         = owner,
        upgrades      = RobotUtils.getUpgrades(),
        inventorySize = robot_api.inventorySize(),
    }

    local response, _ = HttpClient.post(
        conf:get("ip") .. "/getNewDeviceId",
        JsonEncode.encode(payload)
    )

    local new_id = tostring(response)
    if type(new_id) == "string" then
        conf:set("id", new_id)
        conf:set("configured", true)
        conf:save()
        print("Got new ID: " .. new_id)
        print("Rebooting...")
        os.sleep(2)
        computer.shutdown(true)
    else
        print('Error getting ID (invalid response: "' .. tostring(response) .. '")')
        os.exit()
    end
end

return Setup
