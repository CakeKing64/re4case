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

function CaseInventory:PickupItem(ply, itmName, count)
    CaseInventory:AddItemToInventory(ply, itmName, count)
    return true
end

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


-- Don't use this one directly :)
-- Returns true/false and the remaining amount of items from count not added to the inventory
function CaseInventory:AddItemToInventory(ply, itemId, count, sync)
    if CLIENT then
        return false, 0
    end
    local found = false
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
                    if CaseInventory:PlaceItem(ply.CaseInv.Loadout, newItemId, newItem, {
                        1, 1, ply.CaseInv.Size[1], ply.CaseInv.Size[2],
                    }) then
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


-- Returns the amount of an item in inventory
function CaseInventory:ItemCount(ply, id)
    local count = 0
    for k, v in pairs(ply.CaseInv.Items) do
        if v.ItemID == id then
            count = count + v.Count
        end
    end
    return count
end


-- Returns what would kinda just be #ply.CaseInv.Items, but that doesn't work properly :(
function CaseInventory:ItemSize(ply)
    local count = 0
    for _, _ in pairs(ply.CaseInv.Items) do
        count = count + 1
    end
    return count
end

-- Returns true/false if any items were removed and the remaining count
function CaseInventory:RemoveItem(ply, id, count)
    local rem = count
    local toRemove = {}
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
    return rem != count, rem
end

function CaseInventory:GetItemID(name)
    for k, v in pairs(self.ItemRegister) do
        if v.Name == name then
            return k
        end
    end
    return -1
end

function CaseInventory:IsValid(name)
    return self:GetItemID(name) != -1
end

function CaseInventory:GetItemFromAmmo(ammoID)
    for k, v in pairs(self.ItemRegister) do
        if v.AmmoID == ammoID then
            return k
        end
    end
    return -1
end

-- See sh_items.lua on how to make the info table
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


function CaseInventory:SyncAmmo(ply)
    local ammoCount = {}
    --ply:RemoveAllAmmo() -- no excess ammo :)

    for k, v in pairs(ply.CaseInv.Items) do
        local info = self.ItemRegister[v.ItemID]

        if info.AmmoID != -1 then
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


-- Place items in the loadout array (or attempt to at least)
function CaseInventory:PlaceItem(loadoutTable, invId, info, caseRect)
    local itemInfo = CaseInventory.ItemRegister[info.ItemID]
    

    if itemInfo == nil then
        print(info.ItemID)
    end
    local w = itemInfo.Size.W
    local h = itemInfo.Size.H

    if info.Rotation % 2 == 0 then
        local _w, _h = w, h
        w = _h
        h = _w
    end

    -- If the item doesn't even fit in the bounds why even bother checking
    if info.X + (w-1) > caseRect[3] or info.Y + (h-1) > caseRect[4] then
        return false 
    end

    for x = info.X, info.X + w-1 do
        for y = info.Y, info.Y + h-1 do
            if loadoutTable[x][y] != 0 then
                return false
            end
        end
    end
    
    for x = info.X, info.X + w-1 do
        for y = info.Y, info.Y + h-1 do
            loadoutTable[x][y] = invId
        end
    end

    return true
end

function CaseInventory:MoveItem(ply, id, x, y, rotation)
    if CLIENT then -- Request to move the item to this location
        
    end
end

function CaseInventory:SwapItem(arguments)
    
end

function CaseInventory:MergeItem(arguments)
    
end

function CaseInventory:ClearLoadout(ply)
    ply.CaseInv.Loadout = {}
    for x=1,ply.CaseInv.Size[1] do
        ply.CaseInv.Loadout[x] = {}
        for y=1,ply.CaseInv.Size[2] do
            ply.CaseInv.Loadout[x][y] = 0
        end
    end
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

-- Sync the player inventory over the network
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
    print("sent ", CaseInventory:ItemSize(ply), items)
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