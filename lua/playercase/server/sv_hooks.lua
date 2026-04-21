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

--[[
	Cool sync packet structure

	uint8 ItemCount
	for ItemCount
		uint32 ItemID
		string Name
]]
gameevent.Listen("player_activate")
hook.Add("player_activate", "CASE_PlayerActivate", function (data)
	local remItemCount = 0
	local curItemId = 1
	local curLimitCheck = 0
	local player = Player(data.userid)

	for k, v in pairs(CaseInventory.ItemRegister) do
		remItemCount = remItemCount + 1
	end

	net.Start("CaseSyncIDs")
	net.WriteUInt(math.min(remItemCount, 64), 8)

	repeat
		net.WriteUInt(curItemId, 32)
		net.WriteString(CaseInventory.ItemRegister[curItemId].Name)

		curItemId = curItemId + 1
		curLimitCheck = curLimitCheck + 1
		remItemCount = remItemCount - 1
		-- Send packet off and start a new one
		if curLimitCheck == 64 or remItemCount == 0 then
			curLimitCheck = 0
			net.Send(player)
			if remItemCount ~= 0 then
				net.Start("CaseSyncIDs")
				net.WriteUInt(math.min(remItemCount, 64), 8)
			else -- All sent
				net.Start("CaseSyncIDs")
				net.WriteUInt(0, 8)
				net.Send(player)
			end
		end
	until (remItemCount == 0)

	for k, v in pairs(CaseInventory.AutoGenerateInfo) do
		net.Start("CaseAutoGenWeapons")
			net.WriteBool(false) -- Not done yet
			net.WriteTable(v)
		net.Send(player)
	end

	net.Start("CaseAutoGenWeapons")
		net.WriteBool(true) -- All done
	net.Send(player)

	for k, v in pairs(CaseInventory.RegisterOverrides) do
		CaseInventory:SendOverride(k, player)
	end

	for k, v in pairs(CaseInventory.CustomItems) do
		CaseInventory:SyncCustomItem(k, player)
	end
	
	CaseInventory:Sync(player)
end)