---Converts a source/lua weapon into a usable item in the inventory
---@param ply table
---@param wpn table
---@return boolean added Was the weapon added to the inventory of the player?
function CaseInventory:PickupWeapon(ply, wpn)
    if not wpn:IsWeapon() and not wpn:IsScripted() then
        return false
    end

    local wpnId = CaseInventory:GetItemID(wpn:GetClass())
    local info = CaseInventory.ItemRegister[wpnId]
    local count = CaseInventory:ItemCount(ply, wpnId)

    -- Do a count check here just for grenades :)
    if count == 0 or info.ItemType == CASE_ITEM_GRENADE then
        if not CaseInventory:AddItemToInventory(ply, wpnId, 1) then
            return false
        end
    end


    local excessAmmo1 = math.max(0, wpn:Clip1() - wpn:GetMaxClip1())
    local excessAmmo2 = math.max(0, wpn:Clip2() - wpn:GetMaxClip2())

    wpn:SetClip1(math.min(wpn:Clip1(), wpn:GetMaxClip1()))
    wpn:SetClip2(math.min(wpn:Clip2(), wpn:GetMaxClip2()))
    ply:PickupWeapon(wpn, count > 0)
    


    self:PickupAmmo(ply, wpn:GetPrimaryAmmoType(), excessAmmo1)
    self:PickupAmmo(ply, wpn:GetSecondaryAmmoType(), excessAmmo2)


    return true
end

---TODO
---@param ply table
---@param itmId integer
---@param count integer
function CaseInventory:PickupItem(ply, itmId, count)
    CaseInventory:AddItemToInventory(ply, itmId, count)
    return true
end

---Converts source ammo into a usable item in the inventory
---@param ply table
---@param ammoID integer
---@param count integer
---@return boolean
function CaseInventory:PickupAmmo(ply, ammoID, count)
    if ammoID == -1 then
        return false
    end

    local rem = count
    local res = true 
    local id = self:GetItemFromAmmo(ammoID)

    if id == -1 then
        return false
    end

    while res and rem > 0 do
        res, rem = self:AddItemToInventory(ply, id, rem, false) -- Hold off on syncing for now
    end

    -- TODO: Drop any unused ammo on the ground
    if rem > 0 then
        
    end

    CaseInventory:SyncAmmo(ply)
end


---Don't use this one directly :)<br>
---Tries to find a suitable spot to place an item in the inventory
---@param ply table
---@param itemId integer
---@param count integer
---@param sync boolean?
---@return boolean itemAdded, integer remainingItems Any items added?, Items remaining
function CaseInventory:AddItemToInventory(ply, itemId, count, sync)
    if CLIENT then
        return false, 0
    end
    local valid = false
    local rem = count
    local max = 0
    if sync == nil then
        sync = true
    end

    for k, v in pairs(self.ItemRegister) do
        if k == itemId then
            valid = true
        end
    end
    
    if not valid then
        return false, 0
    end

    max = self.ItemRegister[itemId].MaxCount

    
    -- Check to see if we already have an instance of this item
    for k, v in pairs(ply.CaseInv.Items) do
        if v.ItemID == itemId then
            -- TODO: Replace for a check to get the max stack size of an item
            -- Default will be 32 for non-weapons
            if v.Count < max then
                local toAdd = math.min(max - v.Count, rem)
                v.Count = v.Count + toAdd
                rem = rem - toAdd

                if rem == 0 then
                    break
                end
            end
        end
    end

    if rem ~= 0 then
        local newItem = {
            ItemID=itemId,
            Count=math.min(max, rem),
            Rotation=1,
            X=1,
            Y=1
        }
        local newItemId = -1

        if CASE_INVENTORY_DEBUG then
            newItem.Name = self.ItemRegister[itemId].Name
        end

        local foundSpace = false
        local placedItem = false
        local itemSize = CaseInventory:ItemSize(ply)
        local k = 1

        -- Check to see if there are any empty ids
        for k = 1, itemSize do
            local v = ply.CaseInv.Items[k]
            if v == nil then
                newItemId = k
                foundSpace = true 
                break
            end
        end

        -- None found, place at the end of the item list
        if not foundSpace then
            newItemId = itemSize + 1
        end

        -- Find a spot to place the new item in the loadout
        for r=1,2 do -- Even attempt both rotations
            newItem.Rotation = r
            for y=1,ply.CaseInv.Size[2] do
                for x=1,ply.CaseInv.Size[1] do
                    newItem.X = x
                    newItem.Y = y
                    if CaseInventory:PlaceItem(ply.CaseInv.Loadout, newItemId, newItem, self:GetPlayerCaseRect(ply, false)) then
                        placedItem = true
                        break
                    end
                end
                    if placedItem then -- for y
                        break
                    end
                end
            if placedItem then -- for r
                break
            end
        end

       

        if not placedItem then
            return false, rem
        end

        ply.CaseInv.Items[newItemId] = newItem

        --PrintTable(ply.CaseInv.Items)
        rem = rem - newItem.Count
    end

    if sync then
        CaseInventory:Sync(ply)
    end
    return true, rem
end


---Returns the total count of all items of a certain type
---@param ply table
---@param id integer
---@return integer
function CaseInventory:ItemCount(ply, id)
    local count = 0
    for k, v in pairs(ply.CaseInv.Items) do
        if v.ItemID == id then
            count = count + v.Count
        end
    end
    return count
end


---Returns what would kinda just be #ply.CaseInv.Items, but that doesn't work properly :(
---@param ply table
---@return integer
function CaseInventory:ItemSize(ply)
    local count = 0
    for _, _ in pairs(ply.CaseInv.Items) do
        count = count + 1
    end
    return count
end


---Removes X amount of items of a certain itemId
---@param ply table
---@param id integer
---@param count integer
---@return boolean allRemoved, integer remaining Were all items removed and if not the remaining count
function CaseInventory:RemoveItem(ply, id, count)
    local rem = count
    if rem == nil then
        rem = 1
    end

    for k, v in pairs(ply.CaseInv.Items) do
        if v.ItemID == id then
            local toTake = math.min(v.Count, rem)
            v.Count = v.Count - toTake
            rem = rem - toTake

            if v.Count == 0 then
                ply.CaseInv.Items[k] = nil
            end

            if rem == 0 then
                break
            end
        end
    end

    if SERVER then
        CaseInventory:Sync(ply)
    end
    return rem ~= count, rem
end

---Returns the itemID based off name
---@param name string
---@return integer -1 On not found
function CaseInventory:GetItemID(name)
    for k, v in pairs(self.ItemRegister) do
        if v.Name == name then
            return k
        end
    end
    return -1
end

---Returns true/false if an item is registered
---@param name string
---@return boolean
function CaseInventory:IsValid(name)
    return self:GetItemID(name) ~= -1
end

---Fetches and itemID based off source ammoID
---@param ammoID integer
---@return integer -1 On not found
function CaseInventory:GetItemFromAmmo(ammoID)
    for k, v in pairs(self.ItemRegister) do
        if v.AmmoID == ammoID then
            return k
        end
    end
    return -1
end

-- See sh_items.lua on how to make the info table
---@param info table
---@return boolean 
function CaseInventory:RegisterItem(info)
    local exists = false
    for k, v in pairs(self.ItemRegister) do
        if v.Name == info.Name then
            self.ItemRegister[k] = info
            exists = true 
            break
        end
    end

    if exists then
        print("Overwrote item", info.Name)
        return true
    end

    table.insert(self.ItemRegister, info)

    return true
end

---Used to make sure the ammo in the player's inventory is the same in the case
---@param ply table
function CaseInventory:SyncAmmo(ply)
    local ammoCount = {}
    --ply:RemoveAllAmmo() -- no excess ammo :)

    for k, v in pairs(ply.CaseInv.Items) do
        local info = self.ItemRegister[v.ItemID]

        if info.AmmoID ~= -1 then
            if ammoCount[info.AmmoID] == nil then
                ammoCount[info.AmmoID] = 0
            end
            ammoCount[info.AmmoID] = ammoCount[info.AmmoID] + v.Count
        end
    end

    for k, v in pairs(ammoCount) do
        ply:SetAmmo(v, k)
    end

    CaseInventory:Sync(ply)

end

---Place items in the loadout array (or attempt to at least)
---Seperate to the player for reasons:tm:
---@param loadoutTable table
---@param invId integer
---@param info table
---@param caseRect table
---@return boolean itemPlaced Could the item be placed in the inventory?
function CaseInventory:PlaceItem(loadoutTable, invId, info, caseRect)
    local itemInfo = CaseInventory.ItemRegister[info.ItemID]
    

    if itemInfo == nil then
        return false
    end
    local w = itemInfo.Size.W
    local h = itemInfo.Size.H

    if info.Rotation % 2 == 0 then
        local _w, _h = w, h
        w = _h
        h = _w
    end

    -- If the item doesn't even fit in the bounds why even bother checking
    if info.X + (w-1) > caseRect[3] or info.Y + (h-1) > caseRect[4]
        or info.X < caseRect[1] or info.Y < caseRect[2] then
        return false 
    end

    if not self:CheckLocation(loadoutTable, info.X, info.Y, w, h) then
        return false
    end
    
    for x = info.X, info.X + w-1 do
        for y = info.Y, info.Y + h-1 do
            loadoutTable[x][y] = invId
        end
    end

    return true
end

-- Move an item and swap it with something else if possible
function CaseInventory:MoveItem(ply, id, x, y, rotation)
    local item = ply.CaseInv.Items[id]
    local info = CaseInventory.ItemRegister[item.ItemID]
    local w = info.Size.W
    local h = info.Size.H

    if rotation % 2 == 0 then
        local _w, _h = w, h
        w = _h
        h = _w
    end

    -- See if we encounter any items on our trip
    local foundItem = 0
    for _x = x, x + w-1 do
        for _y = y, y + h-1 do
            if ply.CaseInv.Loadout[_x][_y] ~= 0 then
                if foundItem ~= 0 then
                    return false -- We can only swap one item :( (i'm lazy)
                end

                foundItem = ply.CaseInv.Loadout[_x][_y]
            end
        end
    end
    item.X = x
    item.Y = y
    if self:CheckLocation(ply.CaseInv.Loadout, x, y, w, h, {0, foundItem}) then
        self:PlaceItem(ply.CaseInv.Loadout, id, info, {1,1, 255, 255})
    end
end

function CaseInventory:MergeItem(arguments)

end

function CaseInventory:CheckLocation(loadoutTable, x, y, w, h, ignore)
    ignore = ignore or {0} -- Items to ignore, useful for moving stuff
    
    -- *salutes* rip performance
    for _x = x, x + w-1 do
        for _y = y, y + h-1 do
            local found = false
            for k, v in pairs(ignore) do
                if loadoutTable[_x][_y] == v then
                    found = true 
                    break
                end
            end
            if not found then
                return false
            end
        end
    end

    return true
end

function CaseInventory:GetPlayerCaseRect(ply, alt)
    if SERVER then -- This only really matters on the client
        return {
            1, 1,
            ply.CaseInv.Size[1],
            ply.CaseInv.Size[2]
        }
    end

    if not alt then
        return {
            1, 1,
            ply.CaseInv.Size[3],
            ply.CaseInv.Size[4]
        }
    end
end

---Resets the loadout table for a player
---@param ply table
function CaseInventory:ClearLoadout(ply)
    ply.CaseInv.Loadout = {}
    for x=1,ply.CaseInv.Size[1] do
        ply.CaseInv.Loadout[x] = {}
        for y=1,ply.CaseInv.Size[2] do
            ply.CaseInv.Loadout[x][y] = 0
        end
    end
end

function CaseInventory:GenerateInventory()
    
end


-- Packet structure :)
--[[
    uint8 SizeX
    uint8 SizeY
    uint16 ItemCount
    for ItemCount
        uint16   index
        uint16   itemID
        uint32   count
        uint2    rotation
        uint8    X
        uint8    Y
]]--

---Sync the player inventory over the network
---@param ply table
function CaseInventory:Sync(ply)
    -- If any items were removed we have to place them back :)
    self:ClearLoadout(ply)

    for k, v in pairs(ply.CaseInv.Items) do
        if not CaseInventory:PlaceItem(ply.CaseInv.Loadout, k, v, {
            1, 1, ply.CaseInv.Size[1], ply.CaseInv.Size[2],
        }) then -- This probably means the case shrunk
            
        end
    end

    

    net.Start("CaseSync")
        net.WriteUInt(ply.CaseInv.Size[1], 8)   -- SizeX
        net.WriteUInt(ply.CaseInv.Size[2], 8)   -- SizeY

        net.WriteUInt(CaseInventory:ItemSize(ply), 16) -- ItemCount
        for k, v in pairs(ply.CaseInv.Items) do
            net.WriteUInt(k, 16)            -- Index
            net.WriteUInt(v.ItemID, 16)     -- ItemID
            net.WriteUInt(v.Count, 32)      -- Count
            net.WriteUInt(v.Rotation, 2)    -- Rotation
            net.WriteUInt(v.X, 8)   -- X
            net.WriteUInt(v.Y, 8)   -- Y
        end
        
    net.Send(ply)
    
    PrintTable(ply.CaseInv.Items)
    print("sent ", CaseInventory:ItemSize(ply), "items")
    --CaseInventory:DebugPrintLoadout(ply.CaseInv.Items)
end

function CaseInventory:DebugPrintLoadout(ply)
    local s = ""
    for y=1,ply.CaseInv.Size[2] do
        for x=1,ply.CaseInv.Size[1] do
            s = s .. string.format("[%i]", ply.CaseInv.Loadout[x][y])
        end
        s = s .. "\n"
    end
    print(s)
    return s
end