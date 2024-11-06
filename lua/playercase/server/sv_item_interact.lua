hook.Add("PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon", function(plr, wep)
	if wep:IsWeapon() or wep:IsScripted() then
		return false
	end
end)

hook.Add("PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function(plr, item) 

end)

hook.Add("AllowPlayerPickup", "CASE_AllowPlayerPickup", function(plr, ent)
	if ent:IsWeapon() then
		return false
	end
end)

hook.Add("PlayerUse", "CASE_PlayerUse", function(plr, ent)
    if CaseInventory:PickupEnt(plr, ent) then
    end
end)

hook.Add("StartCommand", "CASE_StartCommand", function(plr, cmd)
end)

hook.Add("StartCommand", "CASE_KeyRelease", function(plr, key)

end)