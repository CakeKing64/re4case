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
            Rotation=0,
            X=0,
            Y=0
        }

        if CASE_INVENTORY_DEBUG then
            newItem.Name = self.ItemRegister[itemId].Name
        end

        -- TODO: Check to see if the item will actually fit in the inventory
        local foundSpace = false
        local k = 1
        while k != #ply.CaseInv.Items do
            local v = ply.CaseInv.Items[k]
            if v == nil then
                ply.CaseInv.Items[k] = newItem
                foundSpace = true 
                break
            end
            k = k + 1
        end

        if not foundSpace then
            table.insert(ply.CaseInv.Items, newItem)
        end

        rem = rem - newItem.Count
        



    end

    if sync then
        CaseInventory:Sync(ply)
    end

    PrintTable(ply.CaseInv)
    return true, rem
end


-- Returns the count of an item in inventory
function CaseInventory:ItemCount(ply, id)
    local count = 0
    for k, v in pairs(ply.CaseInv.Items) do
        if v.ItemID == id then
            count = count + v.Count
        end
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
            print(toTake)
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

    CaseInventory:Sync(ply)
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

end

-- Sync the player inventory over the network
function CaseInventory:Sync(ply)
    -- Start by trimming the player inventory to save space
    PrintTable(ply.CaseInv)
end


function CaseInventory:GetPlayerInventory(plr)
    return plr:GetTable()["CaseInv"]["Items"]
end