-- main.lua
local autoUpdate = require("lib/autoupdate")
local version    = require("version")

autoUpdate(
  version,
  "MarkinoTeck/GTNH-HTTP-ROBOT-CONTROLLER",
  "RobotCode"
)

local ok, robot_api = pcall(require, "robot")
---@diagnostic disable-next-line: cast-local-type
if not ok then robot_api = nil end

local Config = require("lib/config")
local Sender = require("lib/sender")
local Setup  = require("src/setup")

local DEFAULTS = {
  id         = false,
  ip         = "http://test.lookitsmark.com",
  configured = false,
  owner      = false,
}

local conf = Config.new("/etc/robot_config.cfg", DEFAULTS)

Sender.init(conf, robot_api)
Setup.run(conf, robot_api)

if robot_api then
  local Commands = require("src/commands")
  local Loop     = require("src/loop")

  Commands.init(conf)
  Loop.init(conf)

  while true do
    Loop.tick()
  end
end