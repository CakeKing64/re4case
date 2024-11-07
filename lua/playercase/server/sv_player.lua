hook.Add( "PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function( ply, ent )
    local lookTarget = ply:GetEyeTrace().Entity

    if ply.CaseInv.UseCommand == 1 and lookTarget == ent then
        ply.CaseInv.UseCommand = 2
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
    if newCount > oldCount then
        PrintTable(CaseInventory.ItemRegister[CaseInventory:GetItemFromAmmo(ammoID)])
    end

    if newCount < oldCount then
        print("reloaded")
    end
end)