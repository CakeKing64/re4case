function CaseInventory:PickupWeapon(ply, wpn)
    if not wpn:IsWeapon() or wpn:IsScripted() then
        return false
    end

    -- TODO: Add exceptions for grenades here & stripping ammo
    if CaseInventory:ItemCount(ply, wpn:GetClass()) > 0 then
        return false
    end

    if not CaseInventory:AddItemToInventory(ply, wpn:GetClass(), 1) then
        return false
    end

    --PrintTable(ply.CaseInv)
    --print(wpn:Clip1())
    --print(wpn:Clip2())

    local excessAmmo1 = math.max(0, wpn:Clip1() - wpn:GetMaxClip1())
    local excessAmmo2 = math.max(0, wpn:Clip2() - wpn:GetMaxClip2())

    wpn:SetClip1(math.min(wpn:Clip1(), wpn:GetMaxClip1()))
    wpn:SetClip2(math.min(wpn:Clip2(), wpn:GetMaxClip2()))
    ply:PickupWeapon(wpn)

    print(excessAmmo1)
    print(excessAmmo2)
    return true
end

function CaseInventory:PickupItem(ply, itmName)
    CaseInventory:AddItemToInventory(ply, itmName, 1)
    PrintTable(ply.CaseInv)
    return true
end

function CaseInventory:PickupAmmo(ply, ammoID, count)
    
end



-- Don't use this one directly :)
function CaseInventory:AddItemToInventory(ply, item, count, ammoID)
    if CLIENT then
        return false
    end
    local found = false
    local rem = count
    if ammoID == nil then
        ammoID = -1
    end
    
    -- Check to see if we already have an instance of this item
    for k, v in pairs(ply.CaseInv.Items) do
        if v.Name == item then
            -- TODO: Replace for a check to get the max stack size of an item
            -- Default will be 32 for non-weapons
            if v.Count < 32 then
                local toAdd = math.min(32, rem)
                v.Count = v.Count + toAdd
                rem = rem - toAdd

                if rem == 0 then
                    break
                end
            end
        end
    end

    if rem ~= 0 then
        -- TODO: Check to see if the item will actually fit in the inventory
        table.insert(ply.CaseInv.Items, {
            Name=item,
            Count=rem,
            AmmoID=ammoID,
            Rotation=0
        })
    end

    return true
end


-- Returns the count of an item in inventory
function CaseInventory:ItemCount(ply, name)
    local count = 0
    for k, v in pairs(ply.CaseInv.Items) do
        if v.Name == name then
            count = count + v.Count
        end
    end
    return count
end

function CaseInventory:IsValid(name)
    for k, v in pairs(self.ItemRegister) do
        if v.Name == name then
            return true
        end
    end
    return false
end

function CaseInventory:GetItemFromAmmo(ammoID)
    for k, v in pairs(self.ItemRegister) do
        if v.AmmoID == ammoID then
            return k
        end
    end
end


function CaseInventory:RegisterItem(name, info)
    local exists = false
    for k, v in pairs(self.ItemRegister) do
        if v.Name == name then
            exists = true 
            break
        end
    end

    if exists then
        print("Tried to re-register item", name)
        return false
    end
    info.Name = name
    self.ItemRegister[#self.ItemRegister] = info

    PrintTable(self.ItemRegister)

    return true
end