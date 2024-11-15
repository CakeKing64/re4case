if SERVER then
    local case_sync_mode = CreateConVar("case_sync_mode", "0", {FCVAR_ARCHIVE}, 
    [[Determines if weapons/ammo should be given or taken if they are not in the inventory on sync
    0 -> Weapons/ammo should be given if they are in the inventory but not held
    1 -> Weapons/ammo should be removed from the inventory if they aren't also held
    ]], 0, 1)
end



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
    local count = CaseInventory:ItemCount(CaseInventory:Inv(ply), wpnId)

    -- Do a count check here just for grenades :)
    if count == 0 or info.ItemType == CASE_ITEM_GRENADE then
        if not CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), wpnId, 1) then
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
    CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), itmId, count)
    return true
end

---Converts source ammo into a usable item in the inventory
---@param ply table
---@param ammoID integer
---@param count integer
---@return boolean, integer
function CaseInventory:PickupAmmo(ply, ammoID, count, dropIfCantPickup)
    dropIfCantPickup = dropIfCantPickup or true
    if ammoID == -1 then
        return false, count
    end

    local rem = count
    local res = true 
    local id = self:GetItemFromAmmo(ammoID)
    local info = CaseInventory.ItemRegister[id]
    
    if id == -1 then
        return false, 0
    end

    while res and rem > 0 do
        res, rem = self:AddItemToInventory(CaseInventory:Inv(ply), id, rem, false) -- Hold off on syncing for now
    end


    -- Give an instance of the weapon if grenade :)
    -- (And we didn't have one before)
    if rem ~= count and info.ItemType == CASE_ITEM_GRENADE then
        local hasGrenade = false
        for k, v in pairs(ply:GetWeapons()) do
            if v:GetName() == info.Name then
                hasGrenade = true
                break
            end
        end
            if not hasGrenade then
            local wpn = ents.Create(info.Name)
            wpn:Spawn()
            wpn:SetClip1(0)
            wpn:SetClip2(0)
            
            if not ply:PickupWeapon(wpn) then
                wpn:Remove()
            end
        end
    end

    if rem > 0 and dropIfCantPickup then

        local ent = ents.Create("ent_caseammo")
        ent:SetInfo(
            info.RenderInfo.Model, -- Use the model provided in the inventory
            info.AmmoID, -- AmmoID
            rem -- Count
        )
        ent:SetPos(ply:GetPos())
        ent:Spawn()
    end

    CaseInventory:SyncAmmo(ply)
    return true, rem
end


---Don't use this one directly :)<br>
---Tries to find a suitable spot to place an item in the inventory
---@param inv table
---@param itemId integer
---@param count integer
---@param sync boolean?
---@return boolean itemAdded, integer remainingItems Any items added?, Items remaining
function CaseInventory:AddItemToInventory(inv, itemId, count, sync)
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
    for k, v in pairs(inv.Items) do
        if v.ItemID == itemId then
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
        local newItem = CaseInventory:CreateItemInfo(
            itemId, math.min(max, rem), false, 1, 1
        )
        local newItemId = self:FindFreeId(inv)

        if CASE_INVENTORY_DEBUG then
            newItem.Name = self.ItemRegister[itemId].Name
        end

        local foundSpace = false
        local placedItem = false


        -- Find a spot to place the new item in the loadout
        for r=1,2 do -- Even attempt both rotations
            newItem.Rotated = r == 2
            for y=1, inv.Size[2] do
                for x=1, inv.Size[1] do
                    newItem.X = x
                    newItem.Y = y
                    if CaseInventory:PlaceItem(inv, newItemId, newItem) then
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

        inv.Items[newItemId] = newItem

        --PrintTable(ply.CaseInv.Items)
        rem = rem - newItem.Count
    end

    if sync and inv.Player ~= nil then
        CaseInventory:Sync(inv.Player)
    end
    return true, rem
end


---Returns the total count of all items of a certain type
---@param inv table
---@param id integer
---@return integer
function CaseInventory:ItemCount(inv, id)
    local count = 0
    for k, v in pairs(inv.Items) do
        if v.ItemID == id then
            count = count + v.Count
        end
    end
    return count
end

---Checks to see if the player has an item
---@param inv table
---@param id integer
---@return boolean
function CaseInventory:HasItem(inv, id)
    for k, v in ipairs(inv.Items) do
        if v.ItemID == id then
            return true
        end
    end
    return false
end


---Returns what would kinda just be #ply.CaseInv.Items, but that doesn't work properly :(
---@param inv table
---@return integer
function CaseInventory:ItemSize(inv)
    local count = 0
    for _, _ in pairs(inv.Items) do
        count = count + 1
    end
    return count
end


---Removes X amount of items of a certain itemId
---@param inv table
---@param id integer
---@param count integer
---@return boolean allRemoved, integer remaining Were all items removed and if not the remaining count
function CaseInventory:RemoveItem(inv, id, count)
    local rem = count
    if rem == nil then
        rem = 1
    end

    for k, v in pairs(inv.Items) do
        if v.ItemID == id then
            local toTake = math.min(v.Count, rem)
            v.Count = v.Count - toTake
            rem = rem - toTake

            if v.Count == 0 then
                inv.Items[k] = nil
            end

            if rem == 0 then
                break
            end
        end
    end

    if SERVER and inv.Player ~= nil then
        CaseInventory:Sync(inv.Player)
    end
    return rem ~= count, rem
end

---Drops a player's item on the ground
---@param inv table
---@param invId integer
---@param player table
---@param sync boolean
---@return boolean
function CaseInventory:DropItem(inv, invId, player, sync)
    if invId < 1 then
        return false
    end

    if player == nil then
        return false
    end

    if inv.Items[invId] == nil then
        return false
    end

    local itemInfo = CaseInventory.ItemRegister[inv.Items[invId].ItemID]
    local invInfo = inv.Items[invId]
    inv.Items[invId] = nil -- Remove it here just so no future errors make it materialize back into the inventory
    
    if sync then
        CaseInventory:Sync(player)
    end

    -- Drop different stuff based on item type

    -- For generic items just spawn the entity on the floor and that should be it
    if itemInfo.ItemType == CASE_ITEM_GENERIC then
        for i=1, invInfo.Count do 
            local ent = ents.Spawn(itemInfo.Name)
            ent:SetPos(player:GetPos())
            ent:Spawn()
        end
    end

    -- For weapons call player:DropWeapon
    -- If the player is dead spawn one in with the old clips
    if itemInfo.ItemType == CASE_ITEM_WEAPON  then
        local found = false
        local clip1 = 0
        local clip2 = 0
        for _, wep in ipairs( player:GetWeapons() ) do
            if wep:GetClass() == itemInfo.Name then
                if player:Alive() then
                    player:DropWeapon( wep , player:GetPos(), Vector(0, 0, 0))
                    found = true
                    break
                else
                    clip1 = wep:Clip1()
                    clip2 = wep:Clip2()
                end
            end
        end


        if not found then
            local wpn = ents.Create(itemInfo.Name) 
            wpn:SetPos(player:GetPos())
            wpn:Spawn()

            wpn:SetClip1(clip1)
            wpn:SetClip2(clip2)
        end

    end

    -- For ammo we create a caseammo
    if itemInfo.ItemType == CASE_ITEM_AMMO or itemInfo.ItemType == CASE_ITEM_GRENADE then
        local ent = ents.Create("ent_caseammo")
        ent:SetInfo(
            itemInfo.RenderInfo.Model, -- Use the model provided in the inventory
            itemInfo.AmmoID, -- AmmoID
            invInfo.Count -- Count
        )
        ent:SetPos(player:GetPos())
        ent:Spawn()

        self:SyncAmmo(player)
    end

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

---Creates an item info table :)
---@param itemId integer
---@param count integer
---@param rotated boolean
---@param x integer
---@param y integer
---@return table
function CaseInventory:CreateItemInfo(itemId, count, rotated, x, y)
    return {
        ItemID=itemId,
        Count=count,
        Rotated=rotated,
        X=x,
        Y=y
    }
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
    local plyCurAmmo = ply:GetAmmo()

    for k, v in pairs(CaseInventory:Inv(ply).Items) do
        local info = self.ItemRegister[v.ItemID]

        if info.AmmoID ~= -1 then
            plyCurAmmo[info.AmmoID] = nil
            if ammoCount[info.AmmoID] == nil then
                ammoCount[info.AmmoID] = 0
            end
            ammoCount[info.AmmoID] = ammoCount[info.AmmoID] + v.Count
        end
    end

    for k, v in pairs(ammoCount) do
        ply:SetAmmo(v, k)
    end

    for k, v in pairs(plyCurAmmo) do -- Strip any ammo not in the inventory
        ply:SetAmmo(0, k)
    end

    CaseInventory:Sync(ply)

end

---Place items in the loadout array (or attempt to at least)
---Seperate to the player for reasons:tm:
---@param inv table
---@param invId integer
---@param info table
---@return boolean itemPlaced Could the item be placed in the inventory?
function CaseInventory:PlaceItem(inv, invId, info)
    local itemInfo = CaseInventory.ItemRegister[info.ItemID]
    

    if itemInfo == nil then
        return false
    end
    local w = itemInfo.Size.W
    local h = itemInfo.Size.H

    if info.Rotated then
        local _w, _h = w, h
        w = _h
        h = _w
    end

    -- If the item doesn't even fit in the bounds why even bother checking
    if info.X + (w-1) > inv.Size[1] or info.Y + (h-1) > inv.Size[2]
        or info.X < 1 or info.Y < 1 then
        return false 
    end

    if not self:CheckLocation(inv, info.X, info.Y, w, h) then
        return false
    end
    
    for x = info.X, info.X + w-1 do
        for y = info.Y, info.Y + h-1 do
            inv.Loadout[x][y] = invId
        end
    end

    return true
end

-- Move an item and swap it with something else if possible
---comment
---@param src table Source inventory
---@param srcId integer Source invId
---@param tgt table Target inventory
---@param tgtX integer Target X Cell
---@param tgtY integer Target Y Cell
---@param tgtRot boolean Target rotation
---@return boolean success Was the item moved?
function CaseInventory:MoveItem(src, srcId, tgt, tgtX, tgtY, tgtRot)
    local item = src.Items[srcId]
    local info = CaseInventory.ItemRegister[item.ItemID]
    local w = info.Size.W
    local h = info.Size.H

    if tgtRot then
        local _w, _h = w, h
        w = _h
        h = _w
    end


    local foundItem = 0 -- See if we encounter any items on our trip
    for _x = tgtX, tgtX + w-1 do
        for _y = tgtY, tgtY + h-1 do
            if tgt.Loadout[_x][_y] ~= 0 and tgt.Loadout[_x][_y] ~= foundItem then
                if foundItem ~= 0 then
                    return false -- We can only swap one item :( (i'm lazy)
                end

                foundItem = tgt.Loadout[_x][_y]
            end
        end
    end

    local filter = {
        0, foundItem
    }

    if src == tgt then -- Make sure to filter out the item itself
        filter[#filter+1] = srcId 
    end
    filter = { 
        0,
        src == tgt and srcId or nil
    }
    --PrintTable(filter)

    if self:CheckLocation(tgt, tgtX, tgtY, w, h, filter) then
        local tgtId = 0
        
        if tgt.Items[srcId] == nil or tgt == src then -- Resuse the old id so it's easier on me :)
            tgtId = srcId
        else
            tgtId = CaseInventory:FindFreeId(tgt)
        end
        local newItem = CaseInventory:CreateItemInfo(
            item.ItemID,
            item.Count,
            tgtRot,
            tgtX,
            tgtY
        )

        src.Items[srcId] = nil
        tgt.Items[tgtId] = newItem

        
        CaseInventory:RefreshLoadout(src)
        CaseInventory:RefreshLoadout(tgt)
        return true
        --self:PlaceItem(ply.CaseInv.Loadout, id, info, {1,1, 255, 255})
    end
end


function CaseInventory:MergeItem(arguments)

end

---Checks a location in a loadout table to see if it's either empty
---or only contains another thing (could be used to check for more but lmao)
---@param inv table
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param ignore table?
---@return boolean
function CaseInventory:CheckLocation(inv, x, y, w, h, ignore)
    ignore = ignore or {0} -- Items to ignore, useful for moving stuff
    
    -- *salutes* rip performance
    for _x = x, x + w-1 do
        for _y = y, y + h-1 do
            local found = false
            for k, v in pairs(ignore) do
                if inv.Loadout[_x][_y] == v then
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

function CaseInventory:FindFreeId(inv)
    local itemSize = CaseInventory:ItemSize(inv)
    local newItemId = 0
    local foundSpace = false
    -- Check to see if there are any empty ids
    for k = 1, itemSize do
        local v = inv.Items[k]
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

    return newItemId
end

---Fetches the inventory of a player from the CaseInventory.Inventories value
---Or returns the .ClientInventory value if called from the client
---Not like the .Inventories could be accessed from the client anyway
---@param ply table?
---@return table
function CaseInventory:Inv(ply)
    if CLIENT then
        return LocalPlayer().CaseInv
    end

    if ply == nil then
        return {}
    end

    if ply.CaseInv == nil then
        ply.CaseInv = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], ply)
    end

    return ply.CaseInv
end

function CaseInv(ply)
    return CaseInventory:Inv(ply)
end

---Resets the loadout table for a player
---@param inv table
function CaseInventory:ClearLoadout(inv)
    inv.Loadout = {}
    for x=1, inv.Size[1] do
        inv.Loadout[x] = {}
        for y=1,inv.Size[2] do
            inv.Loadout[x][y] = 0
        end
    end
end

---Resets the loadout table for a table
---@param load table
---@param w integer
---@param h integer
function CaseInventory:ClearLoadout2(load, w, h)
    load = {}
    for x=1, w do
        load[x] = {}
        for y=1,h do
            load[x][y] = 0
        end
    end
end

---Clear and then place :)
---@param inv table
function CaseInventory:RefreshLoadout(inv)
    CaseInventory:ClearLoadout(inv)

    for k, v in pairs(inv.Items) do 
        CaseInventory:PlaceItem(inv, k, v)
    end
end

---Generates an empty inventory
---@param width? integer
---@param height? integer
---@param player table?
---@return table
function CaseInventory:GenerateInventory(width, height, player)
    local inv = {
        Size={width or 10, height or 6},
        Items={},
        Loadout={},
        UseCommand=0,
        Player=player -- could be any entity... maybe
    }

    CaseInventory:ClearLoadout(inv)
    return inv
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
        uint1    rotated
        uint8    X
        uint8    Y
]]--

---Sync the player inventory over the network
---@param ply table
function CaseInventory:Sync(ply)
    if CLIENT then
        return
    end
    -- If any items were removed we have to place them back :)
    self:ClearLoadout(CaseInventory:Inv(ply))

    for k, v in pairs(CaseInventory:Inv(ply).Items) do
        if not CaseInventory:PlaceItem(CaseInventory:Inv(ply), k, v) then -- This probably means the case shrunk
            CaseInventory:DropItem(CaseInventory:Inv(ply), k, ply, false)
        end
    end

    

    net.Start("CaseSync")
        net.WriteUInt(CaseInventory:Inv(ply).Size[1], 8)   -- SizeX
        net.WriteUInt(CaseInventory:Inv(ply).Size[2], 8)   -- SizeY

        net.WriteUInt(CaseInventory:ItemSize(CaseInventory:Inv(ply)), 16) -- ItemCount
        for k, v in pairs(CaseInventory:Inv(ply).Items) do
            net.WriteUInt(k, 16)            -- Index
            net.WriteUInt(v.ItemID, 16)     -- ItemID
            net.WriteUInt(v.Count, 32)      -- Count
            net.WriteBool(v.Rotated)       -- Rotation
            net.WriteUInt(v.X, 8)   -- X
            net.WriteUInt(v.Y, 8)   -- Y
        end
        
    net.Send(ply)
    
    --PrintTable(ply.CaseInv.Items)
    --print("sent ", CaseInventory:ItemSize(ply.CaseInv), "items")
    --CaseInventory:DebugPrintLoadout(ply.CaseInv.Items)
end

function CaseInventory:DebugPrintLoadout(inv)
    local s = ""
    for y=1,inv.Size[2] do
        for x=1,inv.Size[1] do
            s = s .. string.format("[%i]", inv.Loadout[x][y])
        end
        s = s .. "\n"
    end
    print(s)
    return s
end