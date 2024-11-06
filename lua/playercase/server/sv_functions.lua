function CaseInventory:PickupItem(plr, name, isWeapon)
    table.insert(plr.PlayerCase.Items, name)
    CaseInventory:PlayerItemSync(plr)
    return true
end

function CaseInventory:PickupEnt(plr, ent)
    
    if ent:IsWeapon() then
        -- Only allow one instance of a weapon in an inventory
        if not CaseInventory:HasItem(plr, ent:GetClass()) then
            local res = CaseInventory:PickupItem(plr, ent:GetClass(), true)
            if res then
                -- Don't allow any extra ammo from gun pickup
                ent:SetClip1(math.min(ent:Clip1(), ent:GetMaxClip1()))
                ent:SetClip2(0)
                plr:PickupWeapon(ent)
            end
            return res
        else -- Give ammo instead

        end
    end
end

function CaseInventory:HasItem(plr, name)
    for _, v in pairs(plr.PlayerCase.Items) do
        if v == name then
            return true
        end
    end
    return false
end


function CaseInventory:CanStoreItem(plr, name)

end

function CaseInventory:RegisterItem(name, info)

end