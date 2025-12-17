local cvar_drop_excess_ammo = 0
local cvar_inventory_mode = 0
local cvar_auto_generate = 0
local cvar_enable_swap = 0

if SERVER then
	--[[
	local case_sync_mode = CreateConVar("case_sync_mode", "0", {FCVAR_ARCHIVE}, 
	[[Determines if weapons/ammo should be given or taken if they are not in the inventory on sync
	0 -> Weapons/ammo should be given if they are in the inventory but not held
	1 -> Weapons/ammo should be removed from the inventory if they aren't also held
	, 0, 1)
	]]
	cvar_inventory_mode = CaseInventory:GetCVAR("case_inventory_mode")
	cvar_drop_excess_ammo = CaseInventory:GetCVAR("case_drop_excess_ammo")
	cvar_auto_generate = CaseInventory:GetCVAR("case_auto_generate")
end

if CLIENT then
	cvar_inventory_mode = CreateConVar("case_sh_inventory_mode", "0", {FCVAR_REPLICATED})
	cvar_auto_generate = CreateConVar("case_sh_auto_generate", "0", {FCVAR_REPLICATED})
	cvar_enable_swap = CreateConVar("case_cl_enable_swapping", "1", {FCVAR_ARCHIVE})
end


---Converts a source/lua weapon into a usable item in the inventory
---@param ply table
---@param wpn table
---@return boolean added Was the weapon added to the inventory of the player?
function CaseInventory:PickupWeapon(ply, wpn)
	if not wpn:IsWeapon() and not wpn:IsScripted() then
		return false
	end

	local wpnId = CaseInventory:GetItemID(wpn:GetClass())
	local info = CaseInventory.ItemRegister[wpnId]
	local count = CaseInventory:ItemCount(CaseInventory:Inv(ply), wpnId)

	-- Do a count check here just for grenades :)
	if count == 0 or info.ItemType == CASE_ITEM_GRENADE then
		if not CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), wpnId, 1) then
			return false
		end
	end


	local excessAmmo1 = math.max(0, wpn:Clip1() - wpn:GetMaxClip1())
	local excessAmmo2 = math.max(0, wpn:Clip2() - wpn:GetMaxClip2())

	wpn:SetClip1(math.min(wpn:Clip1(), wpn:GetMaxClip1()))
	wpn:SetClip2(math.min(wpn:Clip2(), wpn:GetMaxClip2()))
	ply:PickupWeapon(wpn, count > 0)
	


	self:PickupAmmo(ply, wpn:GetPrimaryAmmoType(), excessAmmo1, cvar_drop_excess_ammo:GetBool())
	self:PickupAmmo(ply, wpn:GetSecondaryAmmoType(), excessAmmo2, cvar_drop_excess_ammo:GetBool())


	return true
end

---TODO
---@param ply table
---@param itmId integer
---@param count integer
function CaseInventory:PickupItem(ply, itmId, count)
	return CaseInventory:AddItemToInventory(CaseInventory:Inv(ply), itmId, count)
end

---Converts source ammo into a usable item in the inventory
---@param ply table
---@param ammoID integer
---@param count integer
---@return boolean, integer
function CaseInventory:PickupAmmo(ply, ammoID, count, dropIfCantPickup)
	if dropIfCantPickup == nil then
		dropIfCantPickup = true
	end
	if ammoID == -1 then
		return false, count
	end

	local rem = count
	local res = true 
	local id = self:GetItemFromAmmo(ammoID)
	local info = CaseInventory.ItemRegister[id]
	
	if id == -1 then
		return false, 0
	end

	while res and rem > 0 do
		res, rem = self:AddItemToInventory(CaseInventory:Inv(ply), id, rem, false) -- Hold off on syncing for now
	end


	-- Give an instance of the weapon if grenade :)
	-- (And we didn't have one before)
	if rem ~= count and info.ItemType == CASE_ITEM_GRENADE then
		local hasGrenade = false
		for k, v in ipairs(ply:GetWeapons()) do
			if v:GetName() == info.Name then
				hasGrenade = true
				break
			end
		end
			if not hasGrenade then
			local wpn = ents.Create(info.Name)
			wpn:Spawn()
			wpn:SetClip1(0)
			wpn:SetClip2(0)
			
			if not ply:PickupWeapon(wpn) then
				wpn:Remove()
			end
		end
	end

	if rem > 0 and dropIfCantPickup then
		local ent = ents.Create("ent_caseammo")
		ent:SetInfo(
			info.RenderInfo.Model, -- Use the model provided in the inventory
			info.AmmoID, -- AmmoID
			rem -- Count
		)
		ent:SetPos(ply:GetPos())
		ent:Spawn()
	end

	CaseInventory:SyncAmmo(ply)
	return true, rem
end


---Don't use this one directly :)<br>
---Tries to find a suitable spot to place an item in the inventory
---@param inv table
---@param itemId integer
---@param count integer
---@param sync boolean?
---@return boolean itemAdded, integer remainingItems Any items added?, Items remaining
function CaseInventory:AddItemToInventory(inv, itemId, count, sync)
	if CLIENT then
		return false, 0
	end
	local valid = false
	local rem = count
	local max = 0
	if sync == nil then
		sync = true
	end

	for k, v in pairs(self.ItemRegister) do
		if k == itemId then
			valid = true
		end
	end
	
	if not valid then
		return false, 0
	end

	max = self.ItemRegister[itemId].MaxCount

	
	-- Check to see if we already have an instance of this item
	for k, v in pairs(inv.Items) do
		if v.ItemID == itemId then
			if v.Count < max then
				local toAdd = math.min(max - v.Count, rem)
				v.Count = v.Count + toAdd
				rem = rem - toAdd

				if rem == 0 then
					break
				end
			end
		end
	end

	if rem ~= 0 then
		local newItem = CaseInventory:CreateItemInfo(
			itemId, math.min(max, rem), false, 1, 1
		)
		local newItemId = self:FindFreeId(inv)

		if CASE_INVENTORY_DEBUG then
			newItem.Name = self.ItemRegister[itemId].Name
		end

		local placedItem, x, y, rotated = CaseInventory:FindValidSpot(inv, itemId)


		if not placedItem then
			return false, rem
		end

		newItem.X = x
		newItem.Y = y
		newItem.Rotated = rotated

		inv.Items[newItemId] = newItem
		--PrintTable(ply.CaseInv.Items)
		rem = rem - newItem.Count
	end

	if sync and inv.Player ~= nil then
		CaseInventory:Sync(inv.Player)
	else
		CaseInventory:RefreshLoadout(inv) -- Still need to apply the loadout
	end
	return true, rem
end

---Finds a valid spot for an item (if any)
---@param inv table
---@param itemID integer
---@return boolean found, number? x, number? y, boolean? rotated 
function CaseInventory:FindValidSpot(inv, itemID)
	local info = CaseInventory.ItemRegister[itemID]
	for y=1, inv.Size[2] do
		for x=1, inv.Size[1] do
			for r=1,2 do -- Attempt both rotations per slot, first horiz then vert
				local width = 0
				local height = 0
				if r == 1 then
					width = info.Size.W
					height = info.Size.H
				else
					width = info.Size.H
					height = info.Size.W
				end
				if CaseInventory:CheckLocation(inv, x, y, width, height) then
					return true, x, y, r == 2
				end
			end
		end
	end


	return false
end

---Returns the total count of all items of a certain type
---@param inv table
---@param id integer
---@return integer
function CaseInventory:ItemCount(inv, id)
	local count = 0
	for k, v in pairs(inv.Items) do
		if v.ItemID == id then
			count = count + v.Count
		end
	end
	return count
end

---Checks to see if the player has an item
---@param inv table
---@param id integer
---@return boolean
function CaseInventory:HasItem(inv, id)
	for k, v in pairs(inv.Items) do
		if v.ItemID == id then
			return true
		end
	end
	return false
end

---comment
---@param itemId integer
function CaseInventory:ShouldHandle(itemId)

end


---Returns what would kinda just be #ply.CaseInv.Items, but that doesn't work properly :(
---@param inv table
---@return integer
function CaseInventory:ItemSize(inv)
	local count = 0
	for _, _ in pairs(inv.Items) do
		count = count + 1
	end
	return count
end


---Removes X amount of items of a certain itemId
---@param inv table
---@param id integer
---@param count integer
---@return boolean allRemoved, integer remaining Were all items removed and if not the remaining count
function CaseInventory:RemoveItem(inv, id, count)
	local rem = count
	if rem == nil then
		rem = 1
	end

	-- Take from the lowest count rather than first in the inventory
	while rem ~= 0 do
		local lowest = -1
		local curID = -1
		-- Locate the instance of the item with the lowest count
		-- Or just use the first one we get
		for k, v in pairs(inv.Items) do
			if v.ItemID == id and (lowest == -1 and true or v.Count < lowest) then
				curID = k
				lowest = v.Count
			end
		end
		-- No instances found :(
		if curID == -1 then
			break
		end

		local toTake = math.min(inv.Items[curID].Count, rem)
		inv.Items[curID].Count = inv.Items[curID].Count - toTake
		rem = rem - toTake

		if inv.Items[curID].Count == 0 then
			inv.Items[curID] = nil
		end
	end

	if SERVER and inv.Player ~= nil then
		CaseInventory:Sync(inv.Player)
	end
	return rem ~= count, rem
end

---Drops a player's item on the ground
---@param inv table
---@param invId integer
---@param count integer Set to a negative number to indicate all items
---@param player table
---@param sync boolean
---@return boolean
function CaseInventory:DropItem(inv, invId, count, player, sync)
	if invId < 1 then
		return false
	end
	
	if count == 0 then
		return false
	end

	if player == nil then
		return false
	end

	if inv.Items[invId] == nil then
		return false
	end
	
	local dropCount = count ~= -1 and math.min(count, inv.Items[invId].Count) or inv.Items[invId].Count

	local itemInfo = CaseInventory.ItemRegister[inv.Items[invId].ItemID]
	local invInfo = inv.Items[invId]

	-- Player tried to drop a weapon they don't have
	-- I've found that Zhina of all things has some """weapons""" that can cause this
	-- So it can have its own edge-case :)
	if IsValid(player) and CaseInventory:IsWeapon(invInfo.ItemID) and not player:HasWeapon(itemInfo.Name) then
		return false
	end

	if inv.Items[invId].Count - dropCount == 0 or count == -1 then
		inv.Items[invId] = nil
	else
		inv.Items[invId].Count = inv.Items[invId].Count - dropCount
	end

	if sync then
		CaseInventory:Sync(player)
	end

	CaseInventory:RefreshLoadout(CaseInventory:Inv(player))

	-- Hopefully this is about 1 1/2 seconds
	player.CasePickupDelay = ( 1 / FrameTime() ) * 1.5

	-- Drop different stuff based on item type

	-- For generic items just spawn the entity on the floor and that should be it
	if itemInfo.ItemType == CASE_ITEM_GENERIC then
		for i=1, dropCount do 
			local ent = ents.Create(itemInfo.Name)
			ent:SetPos(player:GetPos())
			ent:Spawn()
		end
	end

	-- For weapons call player:DropWeapon
	-- If the player is dead spawn one in with the old clips
	-- We'll also ignore dropCount as you can only have one weapon at a time :)
	if itemInfo.ItemType == CASE_ITEM_WEAPON  then
		local found = false
		local clip1 = 0
		local clip2 = 0
		for _, wep in ipairs( player:GetWeapons() ) do
			if wep:GetClass() == itemInfo.Name then
				if player:Alive() then
					player:DropWeapon( wep , player:GetPos(), Vector(0, 0, 0))
					found = true
					break
				else
					clip1 = wep:Clip1()
					clip2 = wep:Clip2()
				end
			end
		end


		if not found then
			local wpn = ents.Create(itemInfo.Name) 
			wpn:SetPos(player:GetPos())
			wpn:Spawn()

			wpn:SetClip1(clip1)
			wpn:SetClip2(clip2)
		end

	end

	-- For ammo we create a caseammo
	if itemInfo.ItemType == CASE_ITEM_AMMO or itemInfo.ItemType == CASE_ITEM_GRENADE then
		local ent = ents.Create("ent_caseammo")
		ent:SetInfo(
			itemInfo.RenderInfo.Model, -- Use the model provided in the inventory
			itemInfo.AmmoID, -- AmmoID
			dropCount-- Count
		)
		ent:SetOwner(player) -- Probably useful for limiting ammo drops or something
		ent:SetPos(player:GetPos())
		ent:Spawn()
		self:SyncAmmo(player, sync)

		if itemInfo.ItemType == CASE_ITEM_GRENADE and not CaseInventory:HasItem(inv, itemInfo.ItemID) then
		   player:StripWeapon(itemInfo.Name)
		end
	end
	return true
end

---Uses an item from a player's inventory
---@param ply table
---@param invId integer
---@param sync boolean
---@return boolean used, integer amountUsed
function CaseInventory:UseItem(ply, invId, sync)
	if CaseInventory:Inv(ply).Items[invId] == nil then
		return false, 0
	end

	local item = CaseInventory.ItemRegister[CaseInventory:Inv(ply).Items[invId].ItemID]
	if item.OnUse == nil then
		return false, 0
	end

	if item.CanUse ~= nil and not item.CanUse(ply, item, invId) then
		return false, 0
	end

	local used, amount = item.OnUse(ply, invId)

	if not used then
		return false, 0
	end

	if amount == nil then
		amount = 1
	end

	amount = math.max(1, amount)

	CaseInventory:Inv(ply).Items[invId].Count = CaseInventory:Inv(ply).Items[invId].Count - amount
	if CaseInventory:Inv(ply).Items[invId].Count <= 0 then
		CaseInventory:Inv(ply).Items[invId] = nil
	end

	if sync then
		CaseInventory:Sync(ply)
	end
	local caseCount = CaseInventory:Inv(ply).Items[invId] ~= nil and CaseInventory:Inv(ply).Items[invId].Count or 1
	return true, math.min(amount, caseCount)
end

---Quick check to see if an item can be used
---@param player table
---@param itemInfo table
---@param invId? number
function CaseInventory:CanUse(player, itemInfo, invId)
	if itemInfo.OnUse == nil then
		return false
	end

	if itemInfo.CanUse == nil then
		return true
	end

	return itemInfo.CanUse(player, itemInfo, invId) 
end

---Returns the itemID based off name
---@param name string
---@return integer -1 On not found
function CaseInventory:GetItemID(name)
	for k, v in pairs(self.ItemRegister) do
		if v.Name == name then
			return k
		end
	end
	return -1
end

---Creates an item info table :)
---@param itemId integer
---@param count integer
---@param rotated boolean
---@param x integer
---@param y integer
---@return table
function CaseInventory:CreateItemInfo(itemId, count, rotated, x, y)
	return {
		ItemID=itemId,
		Count=count,
		Rotated=rotated,
		X=x,
		Y=y
	}
end
---Returns true/false if an item is registered
---@param name string
---@return boolean
function CaseInventory:IsValid(name)
	return self:GetItemID(name) ~= -1
end

---Fetches and itemID based off source ammoID
---@param ammoID integer
---@return integer -1 On not found
function CaseInventory:GetItemFromAmmo(ammoID)
	for k, v in pairs(self.ItemRegister) do
		if v.AmmoID == ammoID then
			return k
		end
	end
	return -1
end

-- See sh_items.lua on how to make the info table
---@param info table
---@return boolean 
function CaseInventory:RegisterItem(info)
	if info == nil then
		return false
	end
	local exists = false
	for k, v in pairs(self.ItemRegister) do
		if v.Name == info.Name then
			self.ItemRegister[k] = info
			info.ItemID = k
			exists = true 
			break
		end
	end

	if exists then
		print("Overwrote item", info.Name)
		return true
	end
	
	table.insert(self.ItemRegister, info)

	return true
end

---Used to make sure the ammo in the player's inventory is the same in the case
---@param ply table
---@param sync boolean?
function CaseInventory:SyncAmmo(ply, sync)
	local ammoCount = {}
	local plyCurAmmo = ply:GetAmmo()
	if sync == nil then
		sync = true
	end
	for k, v in pairs(CaseInventory:Inv(ply).Items) do
		local info = self.ItemRegister[v.ItemID]

		if info.AmmoID ~= -1 then
			plyCurAmmo[info.AmmoID] = nil
			if ammoCount[info.AmmoID] == nil then
				ammoCount[info.AmmoID] = 0
			end
			ammoCount[info.AmmoID] = ammoCount[info.AmmoID] + v.Count
		end
	end

	for k, v in pairs(ammoCount) do
		ply:SetAmmo(v, k)
	end

	for k, v in pairs(plyCurAmmo) do -- Strip any ammo not in the inventory
		ply:SetAmmo(0, k)
	end

	if SERVER and sync then
		CaseInventory:Sync(ply)
	end
end

---Place items in the loadout array (or attempt to at least)
---Seperate to the player for reasons:tm:
---@param inv table
---@param invId integer
---@param info table
---@return boolean itemPlaced Could the item be placed in the inventory?
function CaseInventory:PlaceItem(inv, invId, info)
	local itemInfo = CaseInventory.ItemRegister[info.ItemID]
	

	if itemInfo == nil then
		return false
	end
	local w = itemInfo.Size.W
	local h = itemInfo.Size.H

	if info.Rotated then
		local _w, _h = w, h
		w = _h
		h = _w
	end


	if not self:CheckLocation(inv, info.X, info.Y, w, h) then
		return false
	end
	
	for x = info.X, info.X + w-1 do
		for y = info.Y, info.Y + h-1 do
			inv.Loadout[x][y] = invId
		end
	end

	return true
end

---Helper function for checking overlaps
---@param x1 integer
---@param y1 integer
---@param w1 integer
---@param h1 integer
---@param x2 integer
---@param y2 integer
---@param w2 integer
---@param h2 integer
---@return boolean
function CaseInventory:Overlap(x1, y1, w1, h1, x2, y2, w2, h2)
	return 	x1 < x2 + w2 and
			x1 + w1 > x2 and
			y1 < y2 + h2 and
			y1 + h1 > y2
end

---Checks to see if any rotations are valid for moving into a spot
---@param inv table
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param reqRotation boolean
---@param filter table
---@return integer -1 -> Invalid, 0 -> Valid, No rotation, 1 -> Valid, Rotated
function CaseInventory:RotationCheck(inv, x, y, w, h, reqRotation, filter)
	
	local noRot = self:CheckLocation(inv, x, y, w, h, filter)
	local rot = self:CheckLocation(inv, x, y, h, w, filter)

	if not rot and not noRot then
		return -1
	end

	if rot and reqRotation then
		return 1
	end

	if noRot and not reqRotation then
		return 0
	end

	-- Default to no rotation
	return noRot and 0 or 1
end

function CaseInventory:SwapLogic(srcInv, srcId, tgtInv, tgtId, dstX, dstY, srcRot, checkOnly)
	local srcItem = srcInv.Items[srcId]
	local srcInfo = CaseInventory.ItemRegister[srcItem.ItemID]

	local tgtItem = tgtInv.Items[tgtId]
	local tgtInfo = CaseInventory.ItemRegister[tgtItem.ItemID]

	local srcW, srcH = srcInfo.Size.W, srcInfo.Size.H

	if srcRot then
		srcW = srcInfo.Size.H
		srcH = srcInfo.Size.W
	end

	local validSrc = self:CheckLocation(
		tgtInv, dstX, dstY, srcW, srcH, {
			0,
			tgtId,
			srcInv == tgtInv and srcId or nil
		}
	)

	local validTgt = self:RotationCheck(srcInv,
		srcItem.X,
		srcItem.Y,
		tgtInfo.Size.W,
		tgtInfo.Size.H,
		tgtItem.Rotated,
		{	0,
			srcId,
			srcInv == tgtInv and tgtId or nil
		})
	
	if not validSrc or validTgt == -1 then
		return false
	end

	local tgtW, tgtH = tgtInfo.Size.W, tgtInfo.Size.H
	if validTgt == 1 then
		tgtW = tgtInfo.Size.H
		tgtH = tgtInfo.Size.W
	end

	-- I'm gonna ask you to back that up with a source
	local overlapResult = self:Overlap(
		dstX,
		dstY,
		srcW,
		srcH,
		srcItem.X,
		srcItem.Y,
		tgtW,
		tgtH
	)

	if overlapResult then
		return false
	elseif not checkOnly then
		local newSrcId = 0
		local newTgtId = 0

		if tgtInv.Items[srcId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newSrcId = srcId
		else
			newSrcId = CaseInventory:FindFreeId(tgtInv)
		end

		if srcInv.Items[tgtId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newTgtId = tgtId
		else
			newTgtId = CaseInventory:FindFreeId(tgtInv)
		end

		local newTgtRotation = false

		if validTgt == 1 then
			newTgtRotation = true
		end

		local newSrcItem = CaseInventory:CreateItemInfo(
			srcItem.ItemID,
			srcItem.Count,
			srcRot,
			dstX,
			dstY
		)

		local newTgtItem = CaseInventory:CreateItemInfo(
			tgtItem.ItemID,
			tgtItem.Count,
			newTgtRotation,
			srcItem.X,
			srcItem.Y
		)

		tgtInv.Items[tgtId] = nil
		srcInv.Items[srcId] = nil

		tgtInv.Items[newSrcId] = newSrcItem
		srcInv.Items[newTgtId] = newTgtItem



		print("Logic Error!")
		CaseInventory:RefreshLoadout(srcInv)
		CaseInventory:RefreshLoadout(tgtInv)
	end

	return true
end

---Just try to force it (Internal)
---@param srcInv table
---@param srcId integer
---@param tgtInv table
---@param tgtId integer
---@param checkOnly boolean
---@param rotationInvert? integer
function CaseInventory:SwapDirect(srcInv, srcId, tgtInv, tgtId, checkOnly, rotationInvert)
	if rotationInvert == nil then
		rotationInvert = 0
	end

	local srcItem = srcInv.Items[srcId]
	local srcInfo = CaseInventory.ItemRegister[srcItem.ItemID]

	local tgtItem = tgtInv.Items[tgtId]
	local tgtInfo = CaseInventory.ItemRegister[tgtItem.ItemID]

	local srcRot = srcItem.Rotated
	local tgtRot = tgtItem.Rotated

	if bit.band(rotationInvert, 0x1) ~= 0 then
		srcRot = not srcRot
	end

	if bit.band(rotationInvert, 0x2) ~= 0 then
		tgtRot = not tgtRot
	end


	local validSrc = self:RotationCheck(tgtInv,
		tgtItem.X,
		tgtItem.Y,
		srcInfo.Size.W,
		srcInfo.Size.H,
		srcRot,
		{	0,
			tgtId,
			srcInv == tgtInv and srcId or nil
		})

	local validTgt = self:RotationCheck(srcInv,
		srcItem.X,
		srcItem.Y,
		tgtInfo.Size.W,
		tgtInfo.Size.H,
		tgtRot,
		{	0,
			srcId,
			srcInv == tgtInv and tgtId or nil
		})

	if validSrc == -1 or validTgt == -1 then
		return false
	end

	-- Flip the items around if needed
	local srcW, srcH = srcInfo.Size.W, srcInfo.Size.H
	if validSrc == 1 then
		srcW = srcInfo.Size.H
		srcH = srcInfo.Size.W
	end

	local tgtW, tgtH = tgtInfo.Size.W, tgtInfo.Size.H
	if validTgt == 1 then
		tgtW = tgtInfo.Size.H
		tgtH = tgtInfo.Size.W
	end

	-- I'm gonna ask you to back that up with a source
	local overlapResult = self:Overlap(
		tgtItem.X,
		tgtItem.Y,
		srcW,
		srcH,
		srcItem.X,
		srcItem.Y,
		tgtW,
		tgtH
	)

	if overlapResult then
		-- That was everything i had, time to give up
		if rotationInvert == 4 then
			return false
		else
			return self:SwapDirect(srcInv, srcId, tgtInv, tgtId, checkOnly, rotationInvert + 1)
		end
	end

	-- Do the thing, Shadow.
	if not checkOnly then
		local newSrcId = 0
		local newTgtId = 0

		if tgtInv.Items[srcId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newSrcId = srcId
		else
			newSrcId = CaseInventory:FindFreeId(tgtInv)
		end

		if srcInv.Items[tgtId] == nil or tgtInv == srcInv then -- Resuse the old id so it's easier on me :)
			newTgtId = tgtId
		else
			newTgtId = CaseInventory:FindFreeId(tgtInv)
		end

		local newSrcRotation = false
		local newTgtRotation = false

		if validSrc == 1 then
			newSrcRotation = true
		end

		if validTgt == 1 then
			newTgtRotation = true
		end

		local newSrcItem = CaseInventory:CreateItemInfo(
			srcItem.ItemID,
			srcItem.Count,
			newSrcRotation,
			tgtItem.X,
			tgtItem.Y
		)

		local newTgtItem = CaseInventory:CreateItemInfo(
			tgtItem.ItemID,
			tgtItem.Count,
			newTgtRotation,
			srcItem.X,
			srcItem.Y
		)

		tgtInv.Items[tgtId] = nil
		srcInv.Items[srcId] = nil

		tgtInv.Items[newSrcId] = newSrcItem
		srcInv.Items[newTgtId] = newTgtItem



		
		CaseInventory:RefreshLoadout(srcInv)
		CaseInventory:RefreshLoadout(tgtInv)
	end
	return true
end


-- Move an item and swap it with something else if possible
---@param src table Source inventory
---@param srcId integer Source invId
---@param tgt table Target inventory
---@param tgtX integer Target X Cell
---@param tgtY integer Target Y Cell
---@param tgtRot boolean Target rotation
---@param checkOnly boolean? Don't actually move anything
---@return boolean success, boolean wasSwapped 
function CaseInventory:MoveItem(src, srcId, tgt, tgtX, tgtY, tgtRot, checkOnly)

	if checkOnly == nil then
		checkOnly = false
	end

	local srcItem = src.Items[srcId]
	local srcInfo = CaseInventory.ItemRegister[srcItem.ItemID]
	local srcW = srcInfo.Size.W
	local srcH = srcInfo.Size.H

	if tgtRot then
		local _w, _h = srcW, srcH
		srcW = _h
		srcH = _w
	end


	local foundItem = tgt.Loadout[tgtX][tgtY]
	local foundSelf = false

	if foundItem == 0 or (src == tgt and foundItem == srcId) then
		for _x = tgtX, tgtX + srcW-1 do
			for _y = tgtY, tgtY + srcH-1 do
				if _x > tgt.Size[1] or _y > tgt.Size[2] then
					continue
				end

				local item = tgt.Loadout[_x][_y]
				if item ~= 0 then
					if src == tgt and item == srcId then
						continue
					else
						foundItem = item
						break
					end
					
				end
			end
		end
	end

	if foundItem == 0 and foundSelf then
		foundItem = srcId
	end

	local swap = 
		foundItem ~= 0 and not
		(foundItem == srcId and src == tgt)
		
	if CLIENT then
		if not cvar_enable_swap:GetBool() then
			swap = false
		end
	end

	-- Time to perform a swap
	if swap then
		local dstItem = tgt.Items[foundItem]
		local dstInfo = CaseInventory.ItemRegister[dstItem.ItemID]
		local dstW = dstInfo.Size.W
		local dstH = dstInfo.Size.H

		local result = self:SwapLogic(src, srcId, tgt, foundItem, tgtX, tgtY, tgtRot, checkOnly) or 
			self:SwapDirect(src, srcId, tgt, foundItem, checkOnly, 0)
		return result, true
	else -- No swap time :(
		local tgtId = 0

		-- Technically done by the found item check lol
		if not self:CheckLocation(tgt, tgtX, tgtY, srcW, srcH, {
			0,
			src == tgt and srcId or nil}) 
		then
			return false, false
		end
		
		if not checkOnly then
			if tgt.Items[srcId] == nil or tgt == src then -- Resuse the old id so it's easier on me :)
				tgtId = srcId
			else
				tgtId = CaseInventory:FindFreeId(tgt)
			end

			local newItem = CaseInventory:CreateItemInfo(
				srcItem.ItemID,
				srcItem.Count,
				tgtRot,
				tgtX,
				tgtY
			)

			src.Items[srcId] = nil
			tgt.Items[tgtId] = newItem
			

			
			CaseInventory:RefreshLoadout(src)
			CaseInventory:RefreshLoadout(tgt)
		end 
		return true, false
	end

	return false, swap
end

---Combines stacks of items together
---@param srcInv table
---@param destInv table
---@param srcID integer
---@param destID integer
---@param sync boolean Will use the srcInv player for server
---@return boolean combined, number sourceRem, number destRem
function CaseInventory:MergeItem(srcInv, destInv, srcID, destID, sync)
	-- Nice
	if srcInv == destInv and srcID == destID then
		return false, 0, 0
	end
	if srcInv.Items[srcID] == nil or destInv.Items[destID] == nil then
		return false, 0, 0
	end

	-- Can only combine items of the same type
	if srcInv.Items[srcID].ItemID ~= destInv.Items[destID].ItemID then
		return false, 0, 0
	end
	

	local itemFrom = srcInv.Items[srcID]
	local itemTo = destInv.Items[destID]
	local itemInfo = CaseInventory.ItemRegister[itemTo.ItemID]

	if itemTo.Count == itemInfo.MaxCount then
		return false, 0, 0
	end

	local added = math.min(itemInfo.MaxCount, itemFrom.Count + itemTo.Count) - itemTo.Count 
	local srcCount = 0
	-- All of the source was added to the dest
	if added == itemFrom.Count then
		srcInv.Items[srcID] = nil
		srcCount = 0
	else
		srcInv.Items[srcID].Count = srcInv.Items[srcID].Count - added
		srcCount = srcInv.Items[srcID].Count
	end

	destInv.Items[destID].Count = destInv.Items[destID].Count + added

	CaseInventory:RefreshLoadout(srcInv)
	CaseInventory:RefreshLoadout(destInv)

	if SERVER and sync then
		CaseInventory:Sync(srcInv.Player)
	end

	if CLIENT then
		CaseInventory.ClientNet.MergeItems(srcID, destID, sync)
	end

	return true, srcCount, destInv.Items[destID].Count
end

---Checks a location in a loadout table to see if it's either empty
---or only contains another thing (could be used to check for more but lmao)
---@param inv table
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param ignore table?
---@return boolean
function CaseInventory:CheckLocation(inv, x, y, w, h, ignore)
	ignore = ignore or {0} -- Items to ignore, useful for moving stuff

	if x + (w-1) > inv.Size[1] or y + (h-1) > inv.Size[2]
		or x < 1 or y < 1 then
		return false 
	end

	-- *salutes* rip performance
	for _x = x, x + (w-1) do
		for _y = y, y + (h-1) do
			local found = false
			for k, v in pairs(ignore) do
				if inv.Loadout[_x][_y] == v then
					found = true 
					break
				end
			end
			if not found then
				return false
			end
		end
	end

	return true
end

function CaseInventory:FindFreeId(inv)
	local itemSize = CaseInventory:ItemSize(inv)
	local newItemId = 0
	local foundSpace = false
	-- Check to see if there are any empty ids
	for k = 1, itemSize do
		local v = inv.Items[k]
		if v == nil then
			newItemId = k
			foundSpace = true 
			break
		end
	end

	-- None found, place at the end of the item list
	if not foundSpace then
		newItemId = itemSize + 1
	end

	return newItemId
end


---Fetches the inventory of a player from the CaseInventory.Inventories value
---Or returns the .ClientInventory value if called from the client
---Not like the .Inventories could be accessed from the client anyway
---@param ply table?
---@param toSet table? Use this to override the table set
---@return table
function CaseInventory:Inv(ply, toSet)

	-- Basic mode
	-- Inventory data is stored on the player
	-- Good for singleplayer campaigns/single level multiplayer ones
	if cvar_inventory_mode:GetInt() == 0 then
		if CLIENT then
			if toSet ~= nil then
				LocalPlayer().CaseInv = toSet
			end
			if LocalPlayer().CaseInv == nil then
				LocalPlayer().CaseInv = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], ply)
			end
			return LocalPlayer().CaseInv
		end

		if ply == nil then
			return {}
		end

		if toSet ~= nil then
			ply.CaseInv = toSet
		end

		if ply.CaseInv == nil then
			ply.CaseInv = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], ply)
		end

		return ply.CaseInv
	end

	-- On disk for transitions mode
	-- Inventory data is stored in the CaseInventory.Inventories table
	-- Inventory data is saved to disk on map change
	-- Inventory data is not saved over server restarts
	if cvar_inventory_mode:GetInt() == 1 then
		if CLIENT then
			if toSet ~= nil then
				CaseInventory.ClientInventory = toSet
			end

			if CaseInventory.ClientInventory == nil then
				CaseInventory.ClientInventory = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], ply)
			end
			return CaseInventory.ClientInventory
		end

		if ply == nil then
			return {}
		end

		if toSet ~= nil then
			CaseInventory.Inventories[ply:SteamID64()] = toSet
		end

		if CaseInventory.Inventories[ply:SteamID64()] == nil then
			ply.CaseInv = CaseInventory:GenerateInventory(CASE_INVENTORY_SIZE_DEFAULT[1], CASE_INVENTORY_SIZE_DEFAULT[2], ply)
		end

		return CaseInventory.Inventories[ply:SteamID64()]
	end

		-- On disk for transitions mode
	-- Inventory data is stored in the CaseInventory.Inventories table
	-- Inventory data is saved to disk on map change
	-- Inventory data is not saved over server restarts
	if cvar_persist_mode:GetInt() == 1 then
		
	end
end

---Shorthand CaseInventory:Inv(ply)
---@param ply table?
---@param toSet table?
---@return table
function CaseInv(ply, toSet)
	return CaseInventory:Inv(ply, toSet)
end

---Resets the loadout table for a player
---@param inv table
function CaseInventory:ClearLoadout(inv)
	inv.Loadout = {}
	for x=1, inv.Size[1] do
		inv.Loadout[x] = {}
		for y=1,inv.Size[2] do
			inv.Loadout[x][y] = 0
		end
	end
end

---Resets the loadout table for a table
---@param load table
---@param w integer
---@param h integer
function CaseInventory:ClearLoadout2(load, w, h)
	load = {}
	for x=1, w do
		load[x] = {}
		for y=1,h do
			load[x][y] = 0
		end
	end
end

---Clear and then place :)
---@param inv table
function CaseInventory:RefreshLoadout(inv)
	CaseInventory:ClearLoadout(inv)

	for k, v in pairs(inv.Items) do 
		CaseInventory:PlaceItem(inv, k, v)
	end
end

---Generates an empty inventory
---@param width? integer
---@param height? integer
---@param player table?
---@return table
function CaseInventory:GenerateInventory(width, height, player)
	local inv = {
		Size={width or 10, height or 6},
		Items={},
		Loadout={},
		Player=player -- could be any entity... maybe
	}
	if player ~= nil then
		player.UseCommand = 0
		player.CasePickupDelay = 0
	end
	
	CaseInventory:ClearLoadout(inv)
	return inv
end


-- Packet structure :)
--[[
	uint8 SizeX
	uint8 SizeY
	uint16 ItemCount
	for ItemCount
		uint16   index
		uint16   itemID
		uint32   count
		uint1    rotated
		uint8    X
		uint8    Y
]]--

---Sync the player inventory over the network
---@param ply table
function CaseInventory:Sync(ply)
	if CLIENT then
		return
	end
	-- If any items were removed we have to place them back :)
	self:ClearLoadout(CaseInventory:Inv(ply))

	for k, v in pairs(CaseInventory:Inv(ply).Items) do
		if not CaseInventory:PlaceItem(CaseInventory:Inv(ply), k, v) then -- This probably means the case shrunk
			CaseInventory:DropItem(CaseInventory:Inv(ply), -1, k, ply, false)
		end
	end

	

	net.Start("CaseSync")
		net.WriteUInt(CaseInventory:Inv(ply).Size[1], 8)   -- SizeX
		net.WriteUInt(CaseInventory:Inv(ply).Size[2], 8)   -- SizeY

		net.WriteUInt(CaseInventory:ItemSize(CaseInventory:Inv(ply)), 16) -- ItemCount
		for k, v in pairs(CaseInventory:Inv(ply).Items) do
			net.WriteUInt(k, 16)            -- Index
			net.WriteUInt(v.ItemID, 16)     -- ItemID
			net.WriteUInt(v.Count, 32)      -- Count
			net.WriteBool(v.Rotated)       -- Rotation
			net.WriteUInt(v.X, 8)   -- X
			net.WriteUInt(v.Y, 8)   -- Y
		end
		
	net.Send(ply)
	
	--PrintTable(ply.CaseInv.Items)
	--print("sent ", CaseInventory:ItemSize(ply.CaseInv), "items")
	--CaseInventory:DebugPrintLoadout(ply.CaseInv.Items)
end

---Auto generates weapon and ammo
---Probably bad and also maybe like O(n something (nothing good))
function CaseInventory:AutoGenerate()
	if not cvar_auto_generate:GetBool() then
		return
	end

	-- Copying as I don't want this to have any....
	-- Unforseen consequences
	local wepList = table.Copy(weapons.GetList())
	local ammoList = game.GetAmmoTypes()


	-- We're about to push that big O to its limits fellas
	-- Find out what is already registed and remove it from the todo list
	for k, v in pairs(CaseInventory.ItemRegister) do
		if v.ItemType ~= CASE_ITEM_WEAPON and v.ItemType ~= CASE_ITEM_GRENADE and v.ItemType ~= CASE_ITEM_DO_NOT_HANDLE then
			continue
		end
		local i = 1
		while i <= #wepList do
			local v2 = wepList[i]
			
			if v2.ClassName == v.Name then
				table.remove(wepList, i)
			else
				i = i + 1
			end
		end
	end

	for k, v in ipairs(CaseInventory.ItemRegister) do
		if v.AmmoID == -1 then
			continue
		end
		

		for k2, v2 in pairs(ammoList) do
			if k2 == v.AmmoID then
				if not SERVER then
					local ammoName = language.GetPhrase("#" .. v2 .. "_ammo")
				end
				ammoList[k2] = nil
			end
		end
	end

	for k, v in ipairs(wepList) do
		local world = v.WorldModel or "models/weapons/w_pistol.mdl"
		CaseInventory:RegisterItem(CaseWeapon(v.ClassName, CaseRenderInfo(world), 3, 2, v.Name))
	end

	for k, v in pairs(ammoList) do
		CaseInventory:RegisterItem(CaseAmmo(k,CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30))
	end

	if cvar_auto_generate:GetInt() == 2 and SERVER then
		local lua = ""
		for k, v in ipairs(wepList) do
			local world = v.WorldModel or "models/weapons/w_pistol.mdl"
			print(string.format("CaseWeapon(\"%s\", CaseRenderInfo(\"%s\"), 3, 2),", v.ClassName, world))
		end

		for k, v in pairs(ammoList) do
			print(string.format("CaseAmmo(game.GetAmmoID(\"%s\"), CaseRenderInfo(\"models/Items/357ammo.mdl\", 1.3, {25, 180, 0}), 2, 1, 30),", v))
		end
	end


end

--- Sorts item register and some other minor things
function CaseInventory:FinalizeItemRegister()

	-- Apply the item IDs obtained from the server
	if CLIENT then
		local tempRegister = {}
		for k, v in ipairs(CaseInventory.ItemRegister) do
			tempRegister[k] = v
			CaseInventory.ItemRegister[k] = nil
		end

		for newItemID, newItemName in pairs(CaseInventory.ItemRegisterLayout ) do
			for k, v in pairs(tempRegister) do
				if newItemName == v.Name then
					CaseInventory.ItemRegister[newItemID] = tempRegister[k]
					table.remove(tempRegister, k)
					break
				end
			end
		end

		-- As for anything left in the temp register, just slap it on the end
		for _, v in pairs(tempRegister) do
			table.insert(CaseInventory.ItemRegister, v)
		end
		
	end

	if SERVER then
		table.sort(CaseInventory.ItemRegister, function (a, b)
			return a.Name < b.Name
		end)
	end

	-- Give the item info a way to reference its own id
	for k, v in ipairs(CaseInventory.ItemRegister) do
		v.ItemID = k
	end
end

function CaseInventory:TryLocalize(string)
	local attempt0 = language.GetPhrase(string)
	local attempt1 = language.GetPhrase("#" .. string)

	if attempt0 ~= string then
		return attempt0
	end

	if attempt1 ~= "#" .. string then
		return attempt1
	end

	return string
end

--- Funny check to see if an item is a weapon
---@param itemID integer
---@return boolean
function CaseInventory:IsWeapon(itemID)
	local item = CaseInventory.ItemRegister[itemID]
	if item == nil then
		return false
	end

	return item.ItemType == CASE_ITEM_WEAPON or item.ItemType == CASE_ITEM_GRENADE
end

--- Funny check to see if an item is a weapon
---@param itemID integer
---@return boolean
function CaseInventory:IsAmmo(itemID)
	local item = CaseInventory.ItemRegister[itemID]
	if item == nil then
		return false
	end

	return item.ItemType == CASE_ITEM_AMMO
end

--- Checks if an item is a proper item that can be placed in an inventory
---@param itemID integer
---@return boolean
function CaseInventory:IsItem(itemID)
	local item = CaseInventory.ItemRegister[itemID]
	if item == nil then
		return false
	end

	return item.ItemType ~= CASE_ITEM_GLOW_ONLY
end

---Client only
function CaseInventory:PopulateNames()
	for k, v in ipairs(CaseInventory.ItemRegister) do
		if v.PrintName ~= nil then
			CaseInventory:TryLocalize(v.PrintName)
			continue
		end

		if v.ItemType == CASE_ITEM_WEAPON or v.ItemType == CASE_ITEM_GRENADE then
			local info = weapons.Get(v.Name)
			if info ~= nil then
				v.PrintName = CaseInventory:TryLocalize(info.PrintName)
			else
				v.PrintName = ""
			end
		end
	end
end



function CaseInventory:DebugPrintLoadout(inv)
	local s = ""
	for y=1,inv.Size[2] do
		for x=1,inv.Size[1] do
			s = s .. string.format("[%i]", inv.Loadout[x][y])
		end
		s = s .. "\n"
	end
	print(s)
	return s
end