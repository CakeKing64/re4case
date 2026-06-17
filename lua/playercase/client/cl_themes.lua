local cvar_theme = CreateConVar("case_theme", "Default", {FCVAR_ARCHIVE, FCVAR_PRINTABLEONLY})

CaseGUITheme =  {
	Current = {},
	Themes = {}
}








function CaseGUITheme:GetItem(itemName)
	local item = self.Current[itemName]
	if item == nil then
		return self.Themes["Default"][itemName]
	end

	return item
end

function CaseGUITheme:LoadTexture(itemName, textureName)
	local item = self:GetItem(itemName)

	-- If it's already cached, return it
	if item[textureName .. "MAT"] ~= nil then
		return item[textureName .. "MAT"]
	end

	-- If not load it up then return
	item[textureName .. "MAT"] =  Material(item[textureName])
	return item[textureName .. "MAT"]
end

---Where all the magic happens
---@param itemName string
---@param x number
---@param y number
---@param w number
---@param h number
function CaseGUITheme:Draw(itemName, x, y, w, h)
	local item = self:GetItem(itemName)
	if item == nil then
		return
	end

	local color = Color(255, 255, 255, 255)
	if item.Color ~= nil then
		color = item.Color
	end
	surface.SetDrawColor(color)

	-- Priority time

	-- Next, single image
	if item.Image ~= nil then
		local image = self:LoadTexture(itemName, "Image")
		surface.SetMaterial(image)
		surface.DrawTexturedRect(x, y, w, h)
		return
	end

	-- Finally, if nothing else exists just throw out the color
	if item.Color ~= nil then
		surface.DrawRect(x, y, w, h)
		return
	end
end

---Draw with a fallback if itemName doesn't exist
---Primarially for buttons
---@param itemName string
---@param x number
---@param y number
---@param w number
---@param h number
function CaseGUITheme:DrawFallback(itemName, fallbackName, x, y, w, h)
	if self.Current[itemName] == nil then
		self:Draw(fallbackName, x, y, w, h)
	else
		self:Draw(itemName, x, y, w, h)
	end
end

---Gets the .Color of an item
---@param itemName string
---@return unknown
function CaseGUITheme:GetColor(itemName)
	local item = self:GetItem(itemName)
	if item == nil or item["Color"] == nil then
		return Color(255, 255, 255, 255)
	end

	return item.Color
end

function CaseGUITheme:GetDetailColor(itemName)
	local item = self:GetDetails(itemName)
	if item == nil or item["Color"] == nil then
		return Color(255, 255, 255, 255)
	end

	return item.Color
end

function CaseGUITheme:GetDetailColorFallback(itemName, fallback)
	if self.Current[itemName] == nil then
		return self:GetDetailColor(fallback)
	else
		return self:GetDetailColor(itemName)
	end
end

function CaseGUITheme:GetDetails(itemName)
	local item = self:GetItem(itemName)
	if item == nil then
		return nil
	end

	return item.Details
end

function CaseGUITheme:GetDetailsFallback(itemName, fallback)
	if self.Current[itemName] == nil then
		return self:GetDetails(fallback)
	else
		return self:GetDetails(itemName)
	end
end

function CaseGUITheme:AddTheme(name, data)
	self.Themes[name] = data

	if name == "Default" then
		self.Current = data
	end
end

function CaseGUITheme:RegisterThemes()
	self.Themes = {}
	self.Current = {}
	hook.Run("CaseRegisterThemes")

	-- Revert to default
	local theme = cvar_theme:GetString()
	if self.Themes[theme] == nil then
		cvar_theme:SetString("Default")
	end
end

cvars.AddChangeCallback("case_theme", function (name, oldValue, newValue)
	-- Neither exist, revert to default
	if CaseGUITheme.Themes[newValue] == nil and CaseGUITheme.Themes[oldValue] == nil then
		cvar_theme:SetString("Default")
		return
	end


	CaseGUITheme.Current = CaseGUITheme.Themes[newValue]
end)

concommand.Add("case_print_themes", function ()
	PrintTable(CaseGUITheme)
end)

concommand.Add("case_reload_themes", function ()
	CaseGUITheme:RegisterThemes()
end)