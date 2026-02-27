local component = require("component")
local serialization = require("serialization")

local inventory = {}

local function hasComponent(name)
	return component.isAvailable(name)
end

function inventory.getSlots()
	local slots = {}

	if not hasComponent("inventory_controller") then
		print("inventory_controller upgrade not present")
		return slots
	end

	if not hasComponent("robot") then
		print("robot not present")
		return slots
	end

	local ic = component.inventory_controller
	local robot = require("robot")

	-- equiped item
	ic.equip()
	local stack = ic.getStackInInternalSlot()
	if stack then
		stack.tag = nil
	end
	slots[1] = stack or false
	ic.equip()

	-- inventory
	for i = 1, robot.inventorySize() do
		local stack = ic.getStackInInternalSlot(i)
		if stack then
			stack.tag = nil
		end
		slots[i+1] = stack or false
	end

	return slots
end

function inventory.equip()
	local slots = {}

	if not hasComponent("inventory_controller") then
		print("inventory_controller upgrade not present")
		return slots
	end

	if not hasComponent("robot") then
		print("robot not present")
		return slots
	end

	local ic = component.inventory_controller
	local result = ic.equip()

	return result
end

function inventory.print()
	local slots = inventory.getSlots()
	print(serialization.serialize(slots))
end

return inventory