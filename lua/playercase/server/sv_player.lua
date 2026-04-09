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
		(use or ply:InVehicle()) and ply.CasePickupDelay <= 0
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
	if cvar_frame0:GetBool() and CurTime() - ent:GetCreationTime() == 0 and ent:GetPos() == ply:GetPos() then
		return true
	end

	return false
end

local function HandleItem(ent)
	if not IsValid(ent) then
		return false
	end

	local itemID = CaseInventory:GetItemID(ent:GetClass())
	if itemID == -1 then
		return false
	end

	local itemInfo = CaseInventory:GetItemInfo(itemID)
	if itemInfo == nil or itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE then
		return false
	end
	return true
end

local function AllowPickup(ply, ent)
	-- This will always trigger a pickup
	if ply.CasePickup == ent then
		return true
	end
	local pickup_mode = cvar_pickup_mode:GetInt() == -1 and math.Clamp(ply:GetInfoNum("case_cl_pickup_mode", 1), 0, 2) or cvar_pickup_mode:GetInt()


	-- Either use or be in a vehicle
	if pickup_mode == 1 and 
		(use or ply:InVehicle()) and ply.CasePickupDelay <= 0
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

	-- Entity was created this frame
	if cvar_frame0:GetBool() and CurTime() - ent:GetCreationTime() == 0 and ent:GetPos() == ply:GetPos() then
		return true
	end
end

hook.Add( "PlayerCanPickupItem", "CASE_PlayerCanPickupItem", function( ply, ent )
	if not HandleItem(ent) then
		return
	end

	if AllowPickup(ply, ent) then
		return true
	end

	return false
end )

hook.Add("PlayerCanPickupWeapon", "CASE_PlayerCanPickupWeapon", function( ply, ent)
	if not HandleItem(ent) then
		return
	end

		
	local itemId = CaseInventory:GetItemID(ent:GetClass())
	if itemId == -1 then
		return false
	end

	if not CaseInventory:HasItem(CaseInventory:Inv(ply), itemId) then
		if not CaseInventory:FindValidSpot(CaseInventory:Inv(ply), itemId) then
			return false
		end
	end

	if AllowPickup(ply, ent) then
		return true
	end

	return false
end)


hook.Add("OnPlayerPhysicsPickup", "CASE_OnPlayerPhysicsPickup", function( ply, ent )
	if not HandleItem(ent) then
		return
	end

	if ply.CasePickup == ent then
		return true
	end

	return false
end)


hook.Add( "WeaponEquip", "CASE_WeaponEquip", function( weapon, ply )
	-- Check to see if the player has picked up an item but doesn't have it in their inventory
	local itemId = CaseInventory:GetItemID(weapon:GetClass())
	if itemId == -1 then
		return
	end

	local info = CaseInventory:GetItemInfo(itemId)
	if info.ItemType == CASE_ITEM_DO_NOT_HANDLE then
		return
	end

	if not CaseInventory:HasItem(CaseInventory:Inv(ply), itemId) then
		if not CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), itemId, 1, true) then
			ply:DropWeapon(weapon, ply:GetPos(), Vector(0,0,0))
		end
	end
end )




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
		local info = CaseInventory:GetItemInfo(v.ItemID)
		
		if info.AmmoID == ammoID then

			-- Wait we don't want to actually touch this
			if info.ItemType == CASE_ITEM_DO_NOT_HANDLE then
				return
			end

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
		local defSize = CaseInventory:GetDefaultCaseSize()
		CaseInventory:Inv(plr, CaseInventory:GenerateInventory(defSize[1], defSize[2], plr))
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



hook.Add("PlayerDisconnected", "CASE_PlayerDisconnected", function (ply)
	if cvar_inventory_mode:GetInt() == 1 then
		CaseInventory.Inventories[ply:SteamID64()] = nil
	end
end)

hook.Add("PlayerUse", "CASE_PlayerUse", function(ply, ent)
	
	if not IsValid(ent) then
		return false -- what
	end

	local itemInfo = CaseInventory:GetItemInfo(CaseInventory:GetItemID(ent:GetClass()))
	if itemInfo == nil then
		return -- let something else handle it
	end
	

	if itemInfo.ItemType == CASE_ITEM_DO_NOT_HANDLE then
		return -- same as above
	end
		
	if ply.UseCommand ~= 1 then
		return false
	end


	if CaseInventory:PickupEntity(ply, ent, not ply:IsWalking()) then
		return false
	end

	ply.UseCommand = 2

	return false
end)


concommand.Add( "case_pickup", function(ply, cmd, args, argStr)
	local lookTarget = ply:GetEyeTrace().Entity

	-- Not looking at anything
	if not IsValid(lookTarget) then
		return
	end

	-- Too far away
	if ply:GetPos():Distance(lookTarget:GetPos()) > 75 then
		return
	end

	CaseInventory:PickupEntity(ply, lookTarget, false)
end )