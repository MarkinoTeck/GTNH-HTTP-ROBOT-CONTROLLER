-- src/setup.lua
local robot_api  = require("robot")

local HttpClient = require("lib/httpclient")
local JsonEncode = require("lib/jsonEncode")
local Sender     = require("lib/sender")
local RobotUtils = require("lib/robot_utils")
local computer   = require("computer")

local Setup      = {}

function Setup.run(conf)
    if conf:get("configured") then
        Sender.position()
        Sender.batteryLevel()
        Sender.touchingBlocks()
        Sender.inventoryData()
        return true
    end

    -- First boot: request a new device ID
    print("Now trying to get ID as new device..")

    local response, _ = HttpClient.post(
        conf:get("ip") .. "/getNewDeviceId",
        JsonEncode.encode({
            inventorySize = robot_api.inventorySize(),
            name          = robot_api.name(),
            upgrades      = RobotUtils.getUpgrades(),
        })
    )

    local new_id = tostring(response)
    if type(new_id) == "string" then
        conf:set("id", new_id)
        conf:set("configured", true)
        conf:save()
        print("Got new ID: " .. new_id .. " — restarting.")
        os.sleep(2)
        computer.shutdown(true)
    else
        print('Error getting ID (invalid response: "' .. tostring(response) .. '")')
        os.exit()
    end
end

return Setup
