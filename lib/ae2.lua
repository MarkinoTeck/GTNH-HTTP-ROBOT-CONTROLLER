local component = require("component")
local robot = require("robot")
local me = component.upgrade_me
local s = require("serialization")
local db = component.database

local ae2_wireless = {}
ae2_wireless.__index = ae2_wireless

function ae2_wireless:takeItem(item_id, item_damage, count)
    local dbSlot = 1
    db.clear(dbSlot)
    db.set(dbSlot, item_id, item_damage)
    print(item_id, item_damage)

    robot.select(1)

    -- Return items already in slot to AE2 before getting new ones
    if robot.count() > 0 then
        local returned = me.sendItems()
        if returned > 0 then
            print("Returned " .. returned .. " items to AE2")
        end
    end

    local dbItem = db.get(dbSlot)
    if (dbItem ~= nil) then
        local filter = {
            name = dbItem.name,
            damage = dbItem.damage,
        }
        local itemsInNetwork = me.getItemsInNetwork(filter)
        local available = 0

        if #itemsInNetwork > 0 then
            print(s.serialize(itemsInNetwork[1]))
            available = itemsInNetwork[1].size
            print("size: "..available)
        end

        local total_items_got = 0
        total_items_got = total_items_got + me.requestItems(db.address, dbSlot, 0) + me.requestItems(db.address, dbSlot, count)

        if total_items_got > 0 then
            return true
        elseif #itemsInNetwork > 0 then
            return false, "missing items"
        else
            return false, "no items in network"
        end
    else
        return false, "ae2 db error n.821327"
    end
end

function ae2_wireless:ceckItem(item_id, item_damage)
    local dbSlot = 1
    db.set(dbSlot, item_id, item_damage)

    robot.select(1)

    if robot.count() > 0 then
        local returned = me.sendItems()
        if returned > 0 then
            print("Returned " .. returned .. " items to AE2")
        end
    end

    local dbItem = db.get(dbSlot)
    if (dbItem ~= nil) then
        local filter = {
            name = dbItem.name,
            damage = dbItem.damage,
        }
        local itemsInNetwork = me.getItemsInNetwork(filter)
        if #itemsInNetwork > 0 then
            return itemsInNetwork[1].size, itemsInNetwork[1].label
        end

        return 0, ""
    else
        return 0, "ae2 db error n.821387"
    end
end

return ae2_wireless
