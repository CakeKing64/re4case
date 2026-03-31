local CaseEditor = {}

CaseEditor.Panel = nil

-- All the panels/stuff
-- Listed here so i can refer back to them
CaseEditor.WeaponList = nil
CaseEditor.ApplyButton = nil
CaseEditor.ResetButton = nil
CaseEditor.Filter = nil
CaseEditor.Model = nil
CaseEditor.Scale = nil
CaseEditor.Offset = nil
CaseEditor.Size = nil
CaseEditor.Count = nil
CaseEditor.Blacklist = nil
CaseEditor.Rotation = nil
CaseEditor.CurrentID = 1

CaseEditor.IsWeapon = false


function CaseEditor:Populate(panel)

	-- Add a combo box and slap all the weapon names in it
	CaseEditor.WeaponList = vgui.Create("DComboBox")

	CaseEditor.Filter = panel:TextEntry("Filter")
	CaseEditor.Filter.OnTextChanged = function ()
		CaseEditor:FilterChanged(CaseEditor.Filter:GetText())
	end



	CaseEditor.WeaponList.OnSelect = function (_, _, _, data)
		CaseEditor:WeaponChanged(data, true)
	end

	panel:AddItem(CaseEditor.WeaponList)


	CaseEditor.ApplyButton = panel:Button("Apply")
	CaseEditor.ApplyButton.DoClick = function()
		CaseEditor:ApplyChanges()
	end

	CaseEditor.ResetButton = panel:Button("Reset")
	CaseEditor.ResetButton.DoClick = function ()
		CaseEditor:ResetInfo()
	end

	CaseEditor.CopyAsCode = panel:Button("Copy As Lua Code")
	CaseEditor.CopyAsCode.DoClick = function ()
		CaseEditor:CopyToClipboard()
	end



	CaseEditor.Model = panel:TextEntry("Model")
	CaseEditor.Size = panel:TextEntry("Size")
	CaseEditor.Scale = panel:TextEntry("Scale")
	CaseEditor.Offset = panel:TextEntry("Offset")
	CaseEditor.Rotation = panel:TextEntry("Rotation")

	CaseEditor.Blacklist = panel:CheckBox("Blacklisted")
	CaseEditor.Count 	= panel:TextEntry("Max Count")
	

	
	CaseEditor:FilterChanged("")
end

local function GetValue(val, default)
	if val == nil then return default end
	return val
end

function CaseEditor:WeaponChanged(itemID, useGetItemInfo)
	local register = nil

	local realType = CaseInventory.ItemRegister[itemID].ItemType
	
	if useGetItemInfo then
		register = CaseInventory:GetItemInfo(itemID)
	else
		register = CaseInventory.ItemRegister[itemID]
	end

	if not register then
		return
	end

	CaseEditor.CurrentID = itemID
	
	CaseEditor.Model:SetText(register.RenderInfo.Model)
	CaseEditor.Size:SetText("" .. GetValue(register.Size.W, 1) .. " " .. GetValue(register.Size.H, 1))
	CaseEditor.Scale:SetText(GetValue(register.RenderInfo.Scale, 1.0))
	CaseEditor.Offset:SetText("" .. GetValue(register.RenderInfo.Offset.X, 0) .. " " .. GetValue(register.RenderInfo.Offset.Y, 0) .. " " .. GetValue(register.RenderInfo.Offset.Z, 0))
	CaseEditor.Rotation:SetText("" .. GetValue(register.RenderInfo.Rotations[1], 0) .. " " .. GetValue(register.RenderInfo.Rotations[2], 0) .. " " .. GetValue(register.RenderInfo.Rotations[3], 0))

	if realType == CASE_ITEM_WEAPON then
		CaseEditor.Count:SetEnabled(false)
		CaseEditor.Count:SetText("")

		CaseEditor.Blacklist:SetEnabled(true)
		CaseEditor.Blacklist:SetChecked(register.ItemType == CASE_ITEM_DO_NOT_HANDLE)

		CaseEditor.IsWeapon = true
	else
		CaseEditor.Count:SetText("" .. GetValue(register.MaxCount))
		CaseEditor.Count:SetEnabled(true)
		CaseEditor.Blacklist:SetEnabled(false)
		CaseEditor.Blacklist:SetChecked(false)

		CaseEditor.IsWeapon = false
	end




end

function CaseEditor:ApplyChanges()
	local i = 1

	local model = CaseEditor.Model:GetText()
	local size = {
		1,
		1
	}

	local offset = {
		0,
		0,
		0
	}

	local rotation = {
		0,
		0,
		0
	}

	local scale = tonumber(CaseEditor.Scale:GetText())
	
	

	for word in string.gmatch(CaseEditor.Size:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		size[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Offset:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		offset[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Rotation:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		rotation[i] = tonumber(word)
		i = i + 1
	end

	local maxCount = CaseEditor.IsWeapon and 1 or tonumber(CaseEditor.Count:GetText())
	local blacklist = CaseEditor.Blacklist:GetChecked()

	CaseInventory.ClientNet.UpdateOverride(
		CaseEditor.CurrentID,
		{
			Size=size,
			MaxCount=maxCount ~= nil and maxCount or 1,
			Blacklist=blacklist,
			RenderInfo=CaseRenderInfo(model, scale, rotation, offset, 0)
		}
	)
end

function CaseEditor:CopyToClipboard()
	local i = 1

	local model = CaseEditor.Model:GetText()
	local size = {
		1,
		1
	}

	local offset = {
		0,
		0,
		0
	}

	local rotation = {
		0,
		0,
		0
	}

	local scale = tonumber(CaseEditor.Scale:GetText())
	
	

	for word in string.gmatch(CaseEditor.Size:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		size[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Offset:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		offset[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Rotation:GetText(), '([^ ]+)') do
		if word == "" then
			continue
		end
		rotation[i] = tonumber(word)
		i = i + 1
	end

	local maxCount = CaseEditor.IsWeapon and 1 or tonumber(CaseEditor.Count:GetText())
	local blacklist = CaseEditor.Blacklist:GetChecked()

	local copyString = ""
	local renderInfo = string.format("CaseRenderInfo(\"%s\", %g, {%g, %g, %g}, Vector(%g, %g, %g))",
			model,
			scale,
			rotation[1],
			rotation[2],
			rotation[3],
			offset[1],
			offset[2],
			offset[3]
		)
		

	local itemType = CaseInventory.ItemRegister[CaseEditor.CurrentID].ItemType
	local itemName = CaseInventory.ItemRegister[CaseEditor.CurrentID].Name

	if blacklist then
		itemType = CASE_ITEM_DO_NOT_HANDLE
	end

	if blacklist then
		copyString = "CaseDoNotHandle(\"" .. itemName .. "\")"
	end

	if itemType == CASE_ITEM_WEAPON then
		copyString = string.format("CaseWeapon(\"%s\", %s, %g, %g)", itemName, renderInfo, size[1], size[2])
	end

	if itemType == CASE_ITEM_AMMO then
		local ammoName = game.GetAmmoName(CaseInventory.ItemRegister[CaseEditor.CurrentID].AmmoID)
		copyString = string.format("CaseAmmo(game.GetAmmoID(\"%s\"), %s, %g, %g, %g)", ammoName, renderInfo, size[1], size[2], maxCount)
	end
	
	SetClipboardText(copyString)
end

function CaseEditor:ResetInfo()
	CaseEditor:WeaponChanged(CaseEditor.CurrentID, false)

	-- Delete the item from the overrides
	CaseInventory.ClientNet.UpdateOverride(
		CaseEditor.CurrentID,
		nil
	)
end

function CaseEditor:FilterChanged(filter)

	local foundWeapon = false
	CaseEditor.WeaponList:CloseMenu()
	CaseEditor.WeaponList:Clear()

	for i in ipairs(CaseInventory.ItemRegister) do
		local type = CaseInventory.ItemRegister[i].ItemType

		if type == CASE_ITEM_GLOW_ONLY or type == CASE_ITEM_DO_NOT_HANDLE or type == CASE_ITEM_AMMO_SPECIAL then
			continue
		end

		local name = string.lower(CaseInventory.ItemRegister[i].Name ~= nil and CaseInventory.ItemRegister[i].Name or "")
		local printName = string.lower(CaseInventory.ItemRegister[i].PrintName ~= nil and CaseInventory.ItemRegister[i].PrintName or "")
		local fitlerLower = string.lower(filter)

		local found = filter == "" or (string.find(name, fitlerLower) or string.find(printName, fitlerLower))

		if found then
			foundWeapon = true
			CaseEditor.WeaponList:AddChoice(
				CaseInventory.ItemRegister[i].Name .. " (" .. CaseInventory.ItemRegister[i].PrintName .. ")",
				i -- Store the index just because
			)
		end
	end

	-- nothing found, just throw everything back on
	if not foundWeapon then
		CaseEditor:FilterChanged("")
	else
		CaseEditor.WeaponList:ChooseOptionID(1)
	end
end


hook.Add("AddToolMenuCategories", "CaseAddUtilCategory", function()
    spawnmenu.AddToolCategory("Utilities", "RE4 Case", "#RE4 Case")
end)

hook.Add("PopulateToolMenu", "CaseAddOption", function()
    spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseEditor", "#Item Editor", "", "", function(panel)
		CaseEditor.Panel = panel
		CaseEditor:Populate(panel)
    end)
end)