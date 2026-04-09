CaseInventory.ClientNet = {
	DropItem = function (invId, count, sync)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_DROP, 4)
		net.WriteUInt(invId, 16)
		net.WriteInt(count, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	UseItem = function (invId, sync)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_USE, 4)
		net.WriteUInt(invId, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	MergeItems = function (srcID, destID, sync)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_MERGE, 4)
		net.WriteUInt(srcID, 16)
		net.WriteUInt(destID, 16)
		net.WriteBool(sync)
		net.SendToServer()
	end,
	SyncItems = function ()
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_SYNC, 4)
		for k, v in pairs(CaseInventory:Inv().Items) do
			net.WriteUInt(k, 16)
			net.WriteUInt(v.X, 8)
			net.WriteUInt(v.Y, 8)
			net.WriteBool(v.Rotated)
		end
		net.SendToServer()
	end,
	UpdateOverride = function (itemID, info)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_SYNC_OVERRIDES, 4)
			net.WriteUInt(itemID, 16)
			net.WriteBool(info == nil)

			-- Break the packet off here
			if info == nil then
				net.SendToServer()
				return
			end


			net.WriteString(info.RenderInfo.Model)

			-- Write size
			net.WriteUInt(info.Size[1] ~= nil and info.Size[1] or 1, 16)
			net.WriteUInt(info.Size[2] ~= nil and info.Size[2] or 1, 16)

			-- Write scale
			net.WriteFloat(info.RenderInfo.Scale)

			-- Write offset
			net.WriteFloat(info.RenderInfo.Offset.X)
			net.WriteFloat(info.RenderInfo.Offset.Y)
			net.WriteFloat(info.RenderInfo.Offset.Z)

			-- Write rotation
			net.WriteFloat(info.RenderInfo.Rotations[1])
			net.WriteFloat(info.RenderInfo.Rotations[2])
			net.WriteFloat(info.RenderInfo.Rotations[3])

			-- Write max count
			net.WriteUInt(info.MaxCount, 16)
			
			-- Write blacklist
			net.WriteBool(info.Blacklist)

			-- Write model skin
			net.WriteUInt(info.RenderInfo.Skin, 8)

		net.SendToServer()
	end,
	RequestOverrides = function ()
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_REQUEST_OVERRIDES, 4)
		net.SendToServer()
	end,
	SyncTemp = nil

}


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
net.Receive("CaseSync", function ()
	local ply = LocalPlayer()
	local ready = IsValid(ply) -- uh oh

	if not ready then
		CaseInventory.ClientNet.SyncTemp = {
			W=net.ReadUInt(8),
			H=net.ReadUInt(8),
			Items={}
		}
		local itemCount = net.ReadUInt(16)
		for i=1, itemCount do
			local index = net.ReadUInt(16)
			local newItem = CaseInventory:CreateItemInfo(
				net.ReadUInt(16),   -- ItemID
				net.ReadUInt(32),   -- Count
				net.ReadBool(),     -- Rotated
				net.ReadUInt(8),    -- X
				net.ReadUInt(8)     -- Y
	
			)
	
			CaseInventory.ClientNet.SyncTemp.Items[index] = newItem
		end
		return
	end

	CaseInv(LocalPlayer(), CaseInventory:GenerateInventory(net.ReadUInt(8), net.ReadUInt(8), LocalPlayer())) -- Setup local thing
	CaseInventory:ClearLoadout(CaseInv(LocalPlayer()))

	
	local itemCount = net.ReadUInt(16)
	--print("Recv item count:", itemCount)
	for i=1, itemCount do
		local index = net.ReadUInt(16)
		local newItem = CaseInventory:CreateItemInfo(
			net.ReadUInt(16),   -- ItemID
			net.ReadUInt(32),   -- Count
			net.ReadBool(),     -- Rotated
			net.ReadUInt(8),    -- X
			net.ReadUInt(8)     -- Y

		)


		CaseInventory:Inv().Items[index] = newItem
		CaseInventory:PlaceItem(CaseInventory:Inv(), index, newItem)
	end
	

	if CaseGUI.IsOpen then -- fuck you re-do your sorting
		CaseGUI.InvTargets["SortingWindow"]:Inv().Items = {}
		CaseInventory:RefreshLoadout(CaseGUI.InvTargets["SortingWindow"]:Inv())
	end

end)

net.Receive("CaseSyncIDs", function ()
	local count = net.ReadUInt(8)
	if count == 0 then
		CaseInventory.ItemRegisterApply = true
		return
	end

	for id=1, count do
		local id = net.ReadUInt(32)
		local name = net.ReadString()
		CaseInventory.ItemRegisterLayout[id] = name
	end
end)

net.Receive("CaseSyncOverride", function ()
	local itemID = net.ReadUInt(16)
	local delete = net.ReadBool()

	if delete then
		CaseInventory:SetOverride(itemID, nil)
		return
	end

	local model = net.ReadString()

	local size = {
		net.ReadInt(16),
		net.ReadInt(16)
	}

	local scale = net.ReadFloat()

	local offset = {
		net.ReadFloat(),
		net.ReadFloat(),
		net.ReadFloat()
	}
	
	local rotation = {
		net.ReadFloat(),
		net.ReadFloat(),
		net.ReadFloat()
	}

	local maxCount = net.ReadUInt(16)
	local blacklist = net.ReadBool()
	local skin = net.ReadUInt(8)

	CaseInventory:SetOverride(itemID, {
		Size=size,
		MaxCount=maxCount,
		Blacklist=blacklist,
		RenderInfo=CaseRenderInfo(model, scale, rotation, offset, 0, skin)
	})

end)