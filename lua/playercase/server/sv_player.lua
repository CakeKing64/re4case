local cvar_drop_excess_ammo = CaseInventory:GetCVAR("case_drop_excess_ammo")
local cvar_drop_on_death = CaseInventory:GetCVAR("case_drop_on_death")
local cvar_inventory_mode = CaseInventory:GetCVAR("case_inventory_mode")
local cvar_frame0 = CaseInventory:GetCVAR("case_frame0_pickup")

local cvar_pick_on_hold = CaseInventory:GetCVAR("case_pickup_on_hold")
local cvar_pickup_mode = CaseInventory:GetCVAR("case_pickup_mode")

local function _canPickup(ply, ent)
    local lookTarget = ply:GetEyeTrace().Entity
    local use = (lookTarget == ent and ply.UseCommand == 1)
    local pickup_mode = cvar_pickup_mode:GetInt() == -1 and math.Clamp(ply:GetInfoNum("case_cl_pickup_mode", 1), 0, 2) or cvar_pickup_mode:GetInt()
    -- In order of most likely to be set :)
    -- if optimization or something [[likely]]


    -- Either use or be in a vehicle
    if pickup_mode == 1 and 
        (use or ply:InVehicle())
    then
        return true
    end

    -- Pickup when walked over
    if pickup_mode == 0 and ply.CasePickupDelay <= 0 then
        return true
    end

    -- Must interact with the item, being in a vehicle doesn't count
    if pickup_mode == 2 and use then
        return true
    end

    -- An item was :Give()'d to a player :)
    -- Pos check to skip some shenanigoons
    if cvar_frame0:GetBool() and CurTime() - ent:GetCreationTime() == 0 and ent:GetPos() == ply:GetPos()then
        return true
    end

    return false
end

hook.Add( "PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function( ply, ent )

    

    if ply.CasePickup == ent then
        ply.CasePickup = nil
        return true
    end

    if ply.UseCommand == nil then
        ply.UseCommand = 0
    end

    if _canPickup(ply, ent) then
        ply.UseCommand = 2

        local id = CaseInventory:GetItemID(ent:GetClass())
        local info = id ~= -1 and CaseInventory.ItemRegister[id] or {}

        if id == -1 or info.ItemType == CASE_ITEM_GLOW_ONLY or info.ItemType == CASE_ITEM_WEAPON or info.ItemType == CASE_ITEM_GRENADE then
            return true
        end

        -- If the player is not holding walk and the item can be used
        -- Use it in the overworld then :)
        -- If not pick it up
        local canUse = CaseInventory.ItemRegister[id].CanUse
        
        if not ply:IsWalking() and (canUse ~= nil and canUse(ply, CaseInventory.ItemRegister[id], -1)) then
            return true
        end

        -- See if the item is already in the pickup queue
        -- If so, remove it
        for k, v in pairs(CaseInventory.PickupQueue) do
            if v.ENT == ent then
                table.remove(CaseInventory.PickupQueue, k)
                break
            end    
        end

        if CaseInventory:PickupItem(ply, id, 1) then
            ply:DropObject()
            ent:Remove()
        end
    end

    return false
end )

hook.Add("PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon", function( ply, ent)
    if ply.UseCommand == nil then
        ply.UseCommand = 0
    end


    if _canPickup(ply, ent) then
        ply.UseCommand = 2
        ply.CasePickup = nil
        

        local itemId = CaseInventory:GetItemID(ent:GetClass())
        if itemId == -1 then
            return false
        end

        -- Weapons will (should) give ammo when picked up so if we already have a copy let it be obtained anyway
        if CaseInventory:HasItem(CaseInventory:Inv(ply), itemId) or CaseInventory:FindValidSpot(CaseInventory:Inv(ply), itemId) then
            return
        end
    end

    return false
end)

hook.Add( "StartCommand", "CASE_StartCommand", function( ply, cmd)
    if cmd:KeyDown(IN_USE) then
        if ply.UseCommand < 2 then
            ply.UseCommand = ply.UseCommand + 1
        end
    else
        ply.UseCommand = 0
    end
end)

hook.Add("PlayerAmmoChanged", "CASE_PlayerAmmoChanged", function (ply, ammoID, oldCount, newCount)
    -- Check to see if the newCount is equal to the total ammo in the inventory for that ammo type
    -- If so don't do anything
    local count = 0

    for k, v in pairs(CaseInventory:Inv(ply).Items) do
        local info = CaseInventory.ItemRegister[v.ItemID]

        if info.AmmoID == ammoID then
            count = count + v.Count
        end
    end

    if newCount == count then
        return
    end

    if newCount > oldCount then
        if not CaseInventory:PickupAmmo(ply, ammoID, newCount - oldCount, cvar_drop_excess_ammo:GetBool()) then
            
        end
    end

    if newCount < oldCount then
        local itemId = CaseInventory:GetItemFromAmmo(ammoID)

        CaseInventory:RemoveItem(CaseInventory:Inv(ply), itemId, oldCount - newCount)
    end
end)




hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, trans)
    if not trans then
        CaseInventory:Inv(plr, CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], plr))
    end
    CaseInventory:Sync(plr)
end)



hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    -- Drop all items if cvar is set
    if victim:IsPlayer() and cvar_drop_on_death:GetBool() then
        for k, v in pairs(CaseInventory:Inv(victim).Items) do
            CaseInventory:DropItem(CaseInventory:Inv(victim), k, -1, victim, false)
        end
        CaseInventory:Sync(victim)
    end

end)

hook.Add("PlayerDroppedWeapon", "CASE_PlayerDroppedWeapon", function (owner, wpn)
    -- This check is here just so we don't cause any unnecessary syncs
    if owner:IsPlayer() and CaseInventory:HasItem(CaseInventory:Inv(owner), CaseInventory:GetItemID(wpn:GetClass())) then
        CaseInventory:RemoveItem(CaseInventory:Inv(owner), CaseInventory:GetItemID(wpn:GetClass()), 1)
    end
end)

hook.Add( "WeaponEquip", "CASE_WeaponEquip", function( weapon, ply )

    if CASE_INVENTORY_DEBUG then
        print(weapon.WorldModel)
    end
    -- Check to see if the player has picked up an item but doesn't have it in their inventory
    local itemId = CaseInventory:GetItemID(weapon:GetClass())
    if itemId == -1 then
        return
    end

	if not CaseInventory:HasItem(CaseInventory:Inv(ply), itemId) then
        if not CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), itemId, 1, true) then
            ply:DropWeapon(weapon, ply:GetPos(), Vector(0,0,0))
        end
    end
end )

-- For if you just slightly miss picking up an item
hook.Add("OnPlayerPhysicsPickup", "CASE_OnPlayerPhysicsPickup", function( ply, ent )
    if not IsValid(ent) then
        return
    end

    -- Allow the client to pick this value if the serverside version is -1
    local pickup_setting = cvar_pick_on_hold:GetInt() == -1 and math.Clamp(ply:GetInfoNum("case_cl_pickup_on_hold", 0), 0, 2) or cvar_pick_on_hold:GetInt()
    local itemID = CaseInventory:GetItemID(ent:GetClass())

    if itemID ~= -1 and pickup_setting > 0 then
        -- If the cvar is 1 then don't pickup if we're walking
        -- If it's 2 then pick it up always
        local pickup =
            (pickup_setting == 1 and not ply:IsWalking() or pickup_setting == 2)
            
        if pickup then
            if CaseInventory:IsWeapon(itemID) then
                CaseInventory:PickupWeapon(ply, ent)
                return
            end



            local info = CaseInventory.ItemRegister[itemID]
            -- Anti infinite loop:tm:
            -- Don't try to pickup if already in the queue
            for k, v in ipairs(CaseInventory.PickupQueue) do
                if v.ENT == ent then
                    return
                end
            end

            if info.CanUse ~= nil and info.CanUse(ply, itemID, -1) then
                ply.CasePickup = ent
                return
            end

            if info.CanUse == nil then
                ply.CasePickup = ent
                return
            end

            -- Add to a queue to be added to the inventory next tick
            -- If the item is invalid by then it will be assumed to have been used
            if CaseInventory:FindValidSpot(CaseInventory:Inv(ply), itemID) then
                ply:DropObject()
                table.insert(CaseInventory.PickupQueue, {Player=ply, ENT=ent, Timer=0, ItemID=itemID})
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "CASE_PlayerDisconnected", function (ply)
    if cvar_inventory_mode:GetInt() == 1 then
        CaseInventory.Inventories[ply:SteamID64()] = nil
    end
end)