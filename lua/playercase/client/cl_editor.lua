local CaseEditor = {}

CaseEditor.Panel = nil

-- All the panels/stuff
-- Listed here so i can refer back to them
CaseEditor.WeaponList = nil
CaseEditor.ApplyButton = nil
CaseEditor.ResetButton = nil
CaseEditor.Model = nil
CaseEditor.Scale = nil
CaseEditor.Offset = nil
CaseEditor.Size = nil
CaseEditor.Rotation = nil
CaseEditor.CurrentID = 1

function CaseEditor:Populate(panel)

	-- Add a combo box and slap all the weapon names in it
	CaseEditor.WeaponList = vgui.Create("DComboBox")

	for i in ipairs(CaseInventory.ItemRegister) do
		CaseEditor.WeaponList:AddChoice(
			CaseInventory.ItemRegister[i].Name .. " (" .. CaseInventory.ItemRegister[i].PrintName .. ")",
			i -- Store the index just because
		)
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

	CaseEditor.Model = panel:TextEntry("Model")
	CaseEditor.Size = panel:TextEntry("Size")
	CaseEditor.Scale = panel:TextEntry("Scale")
	CaseEditor.Offset = panel:TextEntry("Offset")
	CaseEditor.Rotation = panel:TextEntry("Rotation")


	-- And finally setup everything
	CaseEditor.WeaponList:ChooseOptionID(1)
end

local function GetValue(val, default)
	if val == nil then return default end
	return val
end

function CaseEditor:WeaponChanged(itemID, useGetItemInfo)
	local register = nil
	
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
		size[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Offset:GetText(), '([^ ]+)') do
		offset[i] = tonumber(word)
		i = i + 1
	end

	i = 1
	for word in string.gmatch(CaseEditor.Rotation:GetText(), '([^ ]+)') do
		rotation[i] = tonumber(word)
		i = i + 1
	end

	CaseInventory.ClientNet.UpdateOverride(
		CaseEditor.CurrentID,
		false,
		model,
		size,
		scale,
		offset,
		rotation
	)
end

function CaseEditor:ResetInfo()
	CaseEditor:WeaponChanged(CaseEditor.CurrentID, false)

	-- Delete the item from the overrides
	CaseInventory.ClientNet.UpdateOverride(
		CaseEditor.CurrentID,
		true
	)
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