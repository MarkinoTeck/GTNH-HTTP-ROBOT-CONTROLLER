-- lib/robot_utils.lua

local component = require("component")

local RobotUtils = {}

function RobotUtils.getUpgrades()
    local upgrades_to_check = {
        "database", "geolyzer", "gpu", "navigation", "oc_pattern_editor",
        "os_keypad", "printer3d", "robot", "screen", "sign", "sound",
        "stargate", "tank_controller", "tps_card", "transposer", "upgrade_me",
        "waypoint", "world_sensor", "angel", "inventory_controller",
    }

    local installed = {}
    for _, name in ipairs(upgrades_to_check) do
        if component.isAvailable(name) then
            table.insert(installed, name)
        end
    end
    return installed
end

function RobotUtils.split(str, sep)
    local parts = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

-- Returns: side number
function RobotUtils.getRelativeSide(robotFacing, desiredFacing)
    if desiredFacing == "up"   then return 1 end
    if desiredFacing == "down" then return 0 end

    local worldDir = ({ north=0, east=1, south=2, west=3 })[desiredFacing]
    if not worldDir then return 0 end

    local facingMap = { [3]=0, [4]=1, [2]=2, [5]=3 }
    local robotDir  = facingMap[robotFacing] or 0
    local relative  = (worldDir - robotDir + 4) % 4

    local sideMap = { [0]=3, [1]=4, [2]=2, [3]=5 }
    return sideMap[relative] or 0
end

return RobotUtils
