local cvar_drop_on_death = CreateConVar("case_drop_on_death", "1", {FCVAR_ARCHIVE}, "", 0, 1)
local cvar_drop_excess_ammo = CreateConVar("case_drop_excess_ammo", "1", {FCVAR_ARCHIVE},"", 0, 1)

hook.Add( "PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function( ply, ent )
    local lookTarget = ply:GetEyeTrace().Entity


    if ply.CaseInv.UseCommand == 1 and lookTarget == ent then
        ply.CaseInv.UseCommand = 2

        local id = CaseInventory:GetItemID(ent:GetClass())
        local info = id ~= -1 and CaseInventory.ItemRegister[id] or {}

        if id == -1 or info.ItemType == CASE_ITEM_GLOW_ONLY then
            return true
        end

        if CaseInventory:PickupItem(ply, ent:GetClass(), 1) then
            return true
        end
    end

    return false
end )

hook.Add("PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon", function( ply, ent)
    local lookTarget = ply:GetEyeTrace().Entity


    if ply.CaseInv.UseCommand == 1 and lookTarget == ent then
        ply.CaseInv.UseCommand = 2
        CaseInventory:PickupWeapon(ply, ent)
    end

    return false
end)

hook.Add( "StartCommand", "CASE_StartCommand", function( ply, cmd)
    if cmd:KeyDown(IN_USE) then
        if ply.CaseInv.UseCommand < 2 then
            ply.CaseInv.UseCommand = ply.CaseInv.UseCommand + 1
        end
    else
        ply.CaseInv.UseCommand = 0
    end
end)

hook.Add("PlayerAmmoChanged", "CASE_PlayerAmmoChanged", function (ply, ammoID, oldCount, newCount)
    -- Check to see if the newCount is equal to the total ammo in the inventory for that ammo type
    -- If so don't do anything
    local count = 0

    for k, v in pairs(ply.CaseInv.Items) do
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

        CaseInventory:RemoveItem(ply.CaseInv, itemId, oldCount - newCount)
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
        for k, v in pairs(victim.CaseInv.Items) do
            CaseInventory:DropItem(victim.CaseInv, k, victim, false)
        end
        CaseInventory:Sync(victim)
    end

end)

hook.Add("PlayerDroppedWeapon", "CASE_PlayerDroppedWeapon", function (owner, wpn)
    if owner:IsPlayer() then
        CaseInventory:RemoveItem(owner.CaseInv, CaseInventory:GetItemID(wpn:GetClass()), 1)
    end
end)

hook.Add( "WeaponEquip", "CASE_WeaponEquip", function( weapon, ply )
    -- Check to see if the player has picked up an item but doesn't have it in their inventory
    local itemId = CaseInventory:GetItemID(weapon:GetClass())
    if itemId == -1 then
        return
    end

	if not CaseInventory:HasItem(ply.CaseInv, itemId) then
        if not CaseInventory:AddItemToInventory(ply.CaseInv, itemId, 1, true) then
            ply:DropWeapon(weapon, ply:GetPos(), Vector(0,0,0))
        end
    end
end )