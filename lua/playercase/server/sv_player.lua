local cvar_pickup_mode = CaseInventory:GetCVAR("case_pickup_mode")
local cvar_drop_excess_ammo = CaseInventory:GetCVAR("case_drop_excess_ammo")
local cvar_drop_on_death = CaseInventory:GetCVAR("case_drop_on_death")

local function _canPickup(ply, ent)
    local lookTarget = ply:GetEyeTrace().Entity
    local use = (lookTarget == ent and ply.UseCommand == 1)

    -- In order of most likely to be set :)
    -- if optimization or something [[likely]]


    -- Either use or be in a vehicle
    if cvar_pickup_mode:GetInt() == 1 and 
        (use or ply:InVehicle())
    then
        return true
    end

    -- Pickup when walked over
    if cvar_pickup_mode:GetInt() == 0 and ply.CasePickupDelay > 0 then
        return true
    end

    -- Must interact with the item, being in a vehicle doesn't count
    if cvar_pickup_mode:GetInt() == 2 and use then
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
            return true
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

hook.Add("Tick", "CASE_ServerTick", function ()
    for k, v in ipairs(player.GetAll()) do
        if v.CasePickupDelay > 0 then
            v.CasePickupDelay = v.CasePickupDelay - 1
            if v.CasePickupDelay == 0 then
            end
        end
    end
end)


hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, trans)
    if not trans then
        CaseInv(plr, CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], plr))
    end
    CaseInventory:Sync(plr)
end)



hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    -- TODO Drop all items if a cvar is set
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
