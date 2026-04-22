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
	CreateItem = function (name, model, printName)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 4)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_CREATE, 4)

			net.WriteString(printName)
			net.WriteString(model)

		net.SendToServer()
	end,
	UpdateItem = function (name, printName, itemType, useCondition)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 4)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_EDIT, 4)
			net.WriteString(printName)
			net.WriteUInt(itemType, 8)
			net.WriteUInt(useCondition, 8)
		net.SendToServer()
	end,
	RemoveItem = function (name)
		net.Start("CaseCommandEvent")
		net.WriteUInt(CASE_COMMAND_SYNC_ITEM, 4)
			net.WriteString(name)
			net.WriteUInt(CASE_ITEM_REMOVE, 4)
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
		RenderInfo=CaseRenderInfo(model, scale, rotation, offset, skin)
	})

end)

net.Receive("CaseOnPickup", function ()
	local itemID = net.ReadUInt(16)
	local info = CaseInventory:GetItemInfo(itemID)


	if info ~= nil then
		if info.ItemType == CASE_ITEM_GENERIC then
			CaseGUI.PlaySound("ui/re4case/case_pickup_item.wav")
		end
	end
end)

--[[
	bool isToolSelect
		(if true)
		string name
		string model

	(if false)
		uint16 itemID
		string name
		string printName
		string model
		uint8 type
		uint8 canUseCondition
]]
net.Receive("CaseSyncCustomItems", function ()
	local isToolSelect = net.ReadBool()
	if isToolSelect then
		local class = net.ReadString()
		local name = net.ReadString()
		local model = net.ReadString()

		CaseItemCreator.Current.Model = model
		CaseItemCreator.Current.PrintName = name
		CaseItemCreator:SelectEntity(class)
		return
	else

		local itemID = net.ReadUInt(16)
		local delete = net.ReadBool()

		if delete then
			local name = CaseInventory.ItemRegister[itemID].Name
			CaseInventory.CustomItems[itemID] = nil

			CaseInventory.ItemRegister[itemID] = nil
			CaseInventory.RegisterOverrides[itemID] = nil

			if CaseItemCreator.Current.Class == name then
				CaseItemCreator:SelectEntity(CaseItemCreator.Current.Class)
			end

			return
		end

		local name = net.ReadString()
		local printName = net.ReadString()
		local model = net.ReadString()
		local type = net.ReadUInt(8)
		local useMode = net.ReadUInt(8)

		

		CaseInventory.CustomItems[itemID] = {
			Class = name,
			PrintName = printName,
			Type = type,
			CanUse = useMode,
			Model = model
		}

		local item = CaseInventory:GenerateCustomItemInfo(name, printName, model, type)
		item.ItemID = itemID

		CaseInventory:UpdateCustomTags(item, type, useMode)

		CaseInventory.ItemRegister[itemID] = item

		-- As a treat, check the override register
		if CaseInventory.RegisterOverrides[itemID] ~= nil then
			CaseInventory.RegisterOverrides[itemID].PrintName = printName
			CaseInventory.RegisterOverrides[itemID].OnUse = item.OnUse
			CaseInventory.RegisterOverrides[itemID].CanUse = item.CanUse
		end

		-- Reselect to update stuff
		if CaseItemCreator.Current.Class == name then
			CaseItemCreator:SelectEntity(name)
		end

	end
end)

net.Receive("CaseAutoGenWeapons", function ()
	local done = net.ReadBool()
	if done then
		CaseInventory.ObtainedAutoGenerate = true
		return
	end

	local count = net.ReadUInt(8)
	for i=1, count do

		local autoGen = {
			Type = net.ReadUInt(4),
			Name = net.ReadString(),
			PrintName = net.ReadString(),
			Model = net.ReadString(),
			Scale = net.ReadFloat(),
			Rotation = {net.ReadFloat(), net.ReadFloat(), net.ReadFloat()},
			Size = {net.ReadInt(8), net.ReadInt(8)},
			Count = net.ReadUInt(16),
			AmmoID = net.ReadInt(16)
		}
		table.insert(CaseInventory.AutoGenerateInfo, autoGen)
	end
	
end)