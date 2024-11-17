local cvar_drop_on_death = CreateConVar("case_drop_on_death", "1", {FCVAR_ARCHIVE}, "", 0, 1)
local cvar_drop_excess_ammo = CreateConVar("case_drop_excess_ammo", "1", {FCVAR_ARCHIVE},"", 0, 1)
local cvar_pickup_mode = CreateConVar("case_pickup_mode", "1", {FCVAR_ARCHIVE}, [[0 -> Items can be walked over to be picked up
1 -> Items must be +used to pickup]], 0, 1)

hook.Add( "PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function( ply, ent )
    local lookTarget = ply:GetEyeTrace().Entity

    if ply.UseCommand == nil then
        ply.UseCommand = 0
    end

    if ply.UseCommand == 1 and lookTarget == ent then
        ply.UseCommand = 2

        local id = CaseInventory:GetItemID(ent:GetClass())
        local info = id ~= -1 and CaseInventory.ItemRegister[id] or {}

        if id == -1 or info.ItemType == CASE_ITEM_GLOW_ONLY or info.ItemType == CASE_ITEM_WEAPON or info.ItemType == CASE_ITEM_GRENADE then
            return true
        end
        -- Do funny check to see if holding alt here
        if true then
            return true
        end
        if CaseInventory:PickupItem(ply, id, 1) then
            ent:Remove()
        end
    end

    return false
end )

hook.Add("PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon", function( ply, ent)
    local lookTarget = ply:GetEyeTrace().Entity

    if ply.UseCommand == nil then
        ply.UseCommand = 0
    end

    if ply.UseCommand == 1 and lookTarget == ent then
        ply.UseCommand = 2
        CaseInventory:PickupWeapon(ply, ent)
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
    if not trans or plr.CaseInv == nil then
        plr.CaseInv = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], plr)
    end
    CaseInventory:Sync(plr)
end)



hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    -- TODO Drop all items if a cvar is set
    if victim:IsPlayer() and cvar_drop_on_death:GetBool() then
        for k, v in pairs(CaseInventory:Inv(victim).Items) do
            CaseInventory:DropItem(CaseInventory:Inv(victim), k, victim, false)
        end
        CaseInventory:Sync(victim)
    end

end)

hook.Add("PlayerDroppedWeapon", "CASE_PlayerDroppedWeapon", function (owner, wpn)
    if owner:IsPlayer() then
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
