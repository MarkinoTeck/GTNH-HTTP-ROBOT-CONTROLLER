-- main.lua
local autoUpdate = require("lib/autoupdate")
local version = require("version")

autoUpdate(
  version,
  "MarkinoTeck/GTNH-HTTP-ROBOT-CONTROLLER",
  "RobotCode"
)

local robot_api = require("robot")
local Config    = require("lib/config")

local Sender    = require("lib/sender")
local Commands  = require("src/commands")
local Setup     = require("src/setup")
local Loop      = require("src/loop")

local DEFAULTS  = {
  id            = false,
  ip            = "http://test.url.com",
  configured    = false,
  inventorySize = robot_api.inventorySize(),
}

local conf = Config.new("/etc/robot_config.cfg", DEFAULTS)

Sender.init(conf)
Commands.init(conf)
Loop.init(conf)

robot_api.setLightColor(0x0000FF) -- blue
Setup.run(conf)
robot_api.setLightColor(0x00FF00) -- green

while true do
  Loop.tick()
end
