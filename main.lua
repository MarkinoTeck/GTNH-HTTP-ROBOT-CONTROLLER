-- main.lua
local autoUpdate = require("lib/autoupdate")
local version    = require("version")

autoUpdate(
  version,
  "MarkinoTeck/GTNH-HTTP-ROBOT-CONTROLLER",
  "RobotCode"
)

local robot_api_avible, robot_api = pcall(require, "robot")
local Config   = require("lib/config")
local Sender   = require("lib/sender")
local Setup    = require("src/setup")

local DEFAULTS = {
  id         = false,
  ip         = "http://test.lookitsmark.com",
  configured = false,
  owner      = false,
}

local conf = Config.new("/etc/robot_config.cfg", DEFAULTS)

Sender.init(conf)
Setup.run(conf, robot_api_avible, robot_api)


if robot_api_avible then
  local Loop =     require("src/loop")
  local Commands = require("src/commands")

  Loop.init(conf)
  Commands.init(conf)

  while true do
    Loop.tick()
  end
end
