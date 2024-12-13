-- General hooks 'n stuff
local case_weapon_validation = CaseInventory:GetCVAR("case_weapon_validation")

hook.Add("Tick", "CASE_ServerTick", function ()
    for k, v in ipairs(player.GetAll()) do
        if v.CasePickupDelay > 0 then
            v.CasePickupDelay = v.CasePickupDelay - 1
        end
    end

    local i = 1

    while i ~= #CaseInventory.PickupQueue+1 do
        local v = CaseInventory.PickupQueue[i]
        local remove = false

        if IsValid(v.Player) and IsValid(v.ENT) then
            if v.Timer > 0 then
                v.Timer = v.Timer - 1
            else
                if CaseInventory:PickupItem(v.Player, v.ItemID, 1) then
                    v.Player:DropObject()
                    v.ENT:Remove()
                end
                remove = true
            end
        else
            remove = true
        end
        
        if not remove then
            i = i + 1
        else
            table.remove(CaseInventory.PickupQueue, i)
        end
    end

    -- If a weaopon was just vaporized from the player's loadout bypassing PlayerDroppedWeapon
    if case_weapon_validation:GetBool() then
        for pi, p in ipairs(player.GetAll()) do
            local change = false
            local inv = CaseInv(p)
            for n, i in pairs(inv.Items) do
                -- Make sure the player actually has the item in their inventory
                -- If not remove it
                if CaseInventory:IsWeapon(i.ItemID) and not p:HasWeapon(i.Name) then
                    inv.Items[n] = nil
                    change = true
                end
            end

            if change then
                CaseInventory:Sync(p)
            end
        end
    end

end)