local cvar_blur_bg = CreateClientConVar("case_cl_blur_bg", "1", true, false, "Blur the background for the UI", 0, 1)
local cvar_show_edit_button = CreateClientConVar("case_cl_show_edit", "1", true, false, "Shows the edit button in the case menu", 0, 1)
local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32

CaseGUI = {
	HeldItem = {
		InvID=-1,
		SourceWindow=nil,
		Rotated=false,
		X=1,
		Y=1,
		OldInfo={} -- Store info to reset the pos & rot of an item
	},
	SortingWindow = nil,
	MainWindow = nil,
	EditWindow = {
		Panel = nil
	},
	HoveredWindow = nil,
	IsOpen = false,
	ReadyToClose=false,
	Context = {
		Panel=nil,
		Parent=nil,
		InvID=-1
	},
	InvTargets = {
	},
	ShouldPlaySounds = CreateClientConVar("case_cl_play_sounds", "1", true, false, [[Should sounds be played?
	Set to 2 to replace the more annoying sounds]], 0, 2 ),
	PlaySound = function (sound, replace)
		if not CaseGUI.ShouldPlaySounds:GetBool() then
			return
		end

		if replace ~= nil and CaseGUI.ShouldPlaySounds:GetInt() == 2 then
			surface.PlaySound(replace)
			return
		end

		surface.PlaySound(sound)
	end,
	ModelCache={},
	CaseFPS = CreateClientConVar("case_cl_menu_fps", "40", true, false, "Framerate at which the case menu should be drawn", 0, 999)
}

-- The bane of GUI progammers world wide
-- Different hardware configurations
-- / Ultrawide users
function _CaseUIGetScaledSize()
	local height = ScrH()
	local width = height * (16/9) -- banish the ultrawide users to brazil

	return width, height
end

function _CaseUIGetScaledDiff()
	local newW, newH = _CaseUIGetScaledSize()
	
	return newW/ ogWidth, newH /ogHeight 
end

function _CaseUIGetCell(arguments)
	
end

function CaseGUI:Sync()
	-- Start by dropping all items stored in the sorting menu
	for k, v in pairs(self.InvTargets["SortingWindow"]:Inv().Items) do
		CaseInventory.ClientNet.DropItem(k, -1, false)
	end

	CaseInventory.ClientNet.SyncItems()
end

-- Sick cleanup
function CaseGUI:Close()
	self:Sync()
	self.SortingWindow:Close()
	self.MainWindow:Close()
	if self.Context.Panel ~= nil then
		self.Context.Panel:Remove()
	end
	self:CloseEditMenu()
	self.SortingWindow = nil
	self.MainWindow = nil
	self.IsOpen = false
	self.Context = {
		Panel=nil,
		Parent=nil,
		Item=-1
	}
	self.HeldItem.InvID = -1
	self.ReadyToClose = false

	CaseGUI.PlaySound("ui/re4case/case_close.wav")

	for k, v in pairs(self.ModelCache) do
		v:Remove()
	end

	self.ModelCache = {}
end

function CaseGUI:CloseContext()
	if self.Context.Panel ~= nil then
		self.Context.Panel:Remove()
	end

	self.Context.Panel = nil
	self.Context.Parent = nil
	self.Context.Item = -1
end

---Creates a context item
---@param text string
---@param callback function
---@param allowed function?
---@param sound string?
function CaseGUI:AddContext(list, text, callback, allowed, sound)
	table.insert(list, {
		Text=text,
		Callback=callback,
		Allowed=allowed,
		Sound=sound
	})
end


local function _Use(info)
	local itemInfo = info.ItemInfo
	CaseInventory.ClientNet.UseItem(info.InvID, false) -- Request for the server to use the item
	-- Cool line
	local used, useCount = itemInfo.OnUse(LocalPlayer(), itemInfo, info.InvID)
	useCount = useCount and math.max(0, useCount) or 1
	if used then
		info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - useCount
		if info.Inv.Items[info.InvID].Count == 0 then
			info.Inv.Items[info.InvID] = nil
			CaseInventory:RefreshLoadout(info.Inv)
			CaseGUI:CloseContext()
		end
	end
end

local function _UseCheck(info)
	local itemInfo = info.ItemInfo
	if itemInfo.CanUse == nil then
		return true
	end
	return itemInfo.CanUse(LocalPlayer(), itemInfo, info.InvID)
end

local function _Equip(info)
	local itemInfo = info.ItemInfo
	for _, wep in ipairs( LocalPlayer():GetWeapons() ) do
		if wep:GetClass() == itemInfo.Name then
			input.SelectWeapon(wep)
			break
		end
	end
	CaseGUI:CloseContext()
end

local function _EquipCheck(info)
	local itemInfo = info.ItemInfo
	if not IsValid(LocalPlayer():GetActiveWeapon()) then
		return true
	end
	return LocalPlayer():GetActiveWeapon():GetClass() ~= itemInfo.Name
end

local function _Drop1(info)
	local itemInfo = info.ItemInfo
	CaseInventory.ClientNet.DropItem(info.InvID, 1, false)
	info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - 1
	if info.Inv.Items[info.InvID].Count == 0 then
		info.Inv.Items[info.InvID] = nil
		CaseInventory:RefreshLoadout(info.Inv)
		CaseGUI:CloseContext()
	end
end

local function _Drop(info)
	CaseInventory.ClientNet.DropItem(info.InvID, -1, false)
	info.Inv.Items[info.InvID] = nil

	CaseInventory:RefreshLoadout(info.Inv)
	CaseGUI:CloseContext()
end

local function _DropHalf(info)
	local count = info.Inv.Items[info.InvID].Count
	count = math.ceil(count / 2)
	CaseInventory.ClientNet.DropItem(info.InvID, count, false)
	info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - count


	if info.Inv.Items[info.InvID].Count == 0 then
		info.Inv.Items[info.InvID] = nil
		CaseInventory:RefreshLoadout(info.Inv)
		CaseGUI:CloseContext()
	end
end


hook.Add("CaseFillContext", "CaseDefaultFillContext", function (list, info)
	local itemInfo = info.ItemInfo
	if itemInfo.OnUse ~= nil then
		CaseGUI:AddContext(list, "Use", _Use, _UseCheck)
	end

	if itemInfo.ItemType == CASE_ITEM_WEAPON or itemInfo.ItemType == CASE_ITEM_GRENADE then
		CaseGUI:AddContext(list, "Equip", _Equip, _EquipCheck, "ui/re4case/case_equip.wav")
	end
	
	if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
		CaseGUI:AddContext(list, "Drop 1", _Drop1)
	end

	if itemInfo.ItemType == CASE_ITEM_AMMO then
		CaseGUI:AddContext(list, "Drop Half", _DropHalf)
		CaseGUI:AddContext(list, "Drop 1", _Drop1)
	end

end)


---Fills the context menu with that fits with whatever item was selected
---Params here just for ease of use
---@param panel table
---@param parent table
---@param itm integer
function CaseGUI:FillContext(panel, parent)
	local itemID = self.Context.Parent:Inv().Items[CaseGUI.Context.InvID].ItemID
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	local list = {}

	local info = self:GenerateInfo()
	if info ~= nil then
		hook.Call("CaseFillContext", nil, list, info)		
	end


	-- All items have this :)
	CaseGUI:AddContext(list,"Drop", _Drop)

	for k, v in pairs(list) do
		panel:AddOption(v.Text, v.Callback, v.Allowed, v.Sound)
	end
end

---Generates some info to pass to a context option
---@return table?
function CaseGUI:GenerateInfo()
	if self.Context.Parent == nil or
		CaseGUI.Context.InvID == nil or
		self.Context.Parent:Inv().Items[CaseGUI.Context.InvID] == nil then
		return nil	
	end

	local itemID = self.Context.Parent:Inv().Items[CaseGUI.Context.InvID].ItemID
	local itemInfo = CaseInventory:GetItemInfo(itemID)
	return {
		Menu=self.Context.Panel,
		ItemID=itemID,
		ItemInfo=itemInfo,
		Inv=self.Context.Parent:Inv(),
		InvID=CaseGUI.Context.InvID}
end

function CaseGUI:OpenEditMenu()
	local sizeW, sizeH = 400, 700

	self.EditWindow.Window = vgui.Create("DFrame")
	self.EditWindow.Window:InvalidateLayout(true)
	self.EditWindow.Window:SetSize(sizeW, sizeH)
	self.EditWindow.Window:SetSizable( true )
	self.EditWindow.Window:NoClipping(true)
	self.EditWindow.Window:MakePopup()
	self.EditWindow.Window:Center()
	self.EditWindow.Window:SetTitle("The Edit Zone")

	local backgroundPanel = vgui.Create( "DPanel", self.EditWindow.Window )
	backgroundPanel:Dock( TOP )
	backgroundPanel:DockPadding( 4, 4, 4, 4 )
	backgroundPanel:DockMargin( 0, 0, 0, 4 )
	backgroundPanel:SetSize(sizeW - 4, sizeH- 8)
	

	local panel, b = vgui.Create("DForm", backgroundPanel)

	panel:InvalidateLayout(true)
	panel:SizeToChildren( true, true )
	panel:SetSize(sizeW- 4, sizeH - 8)
	panel:SetLabel("The Edit Zone")


	CaseEditor:Populate(panel)

	panel:ControlHelp("\n\nYou can hide the button that opens this menu in the settings :)")
end

function CaseGUI:CloseEditMenu()
	if not IsValid(self.EditWindow.Window) then
		return
	end

	self.EditWindow.Window:Remove()
end

-- Quick shortcut for using an item in an inventory with +use/E
local function _windowOnKeyboardInput(self, keycode)
	if CaseGUI.HoveredWindow == nil then
		return false
	end
	local window = CaseGUI.HoveredWindow
	if window == nil then
		return false
	end

	-- i uh i uhm i um what????
	-- not the best practice to just ignore it buuuuut
	-- i don't care :)
	if window.GetMouseItem == nil then
		return
	end

	local invId = window:GetMouseItem()
	if invId == 0 then
		return false
	end

	local invInfo = window:Inv().Items[invId]
	local itemInfo = CaseInventory:GetItemInfo(invInfo.ItemID)

	local use = input.LookupBinding("use") == input.GetKeyName(keycode)
	if use and CaseInventory:CanUse(LocalPlayer(), invId) then
		CaseInventory.ClientNet.UseItem(invId, false) -- Request for the server to use the item
		-- Cool line
		local used, useCount = itemInfo.OnUse(LocalPlayer(), itemInfo, invId)
		useCount = useCount and math.max(0, useCount) or 1
		if used then
			invInfo.Count = invInfo.Count - useCount
			if invInfo.Count == 0 then
				window:Inv().Items[invId] = nil
				CaseInventory:RefreshLoadout(window:Inv())
				CaseGUI:CloseContext()
			end
		end
	end

	return true
end


local function _createWindow(name, inv, parent, isMain, rtName)
	local window = vgui.Create("DFrame")
	window:NoClipping(true)
	local screenW, screenH = _CaseUIGetScaledSize()
	local scaleW, scaleH = _CaseUIGetScaledDiff()

	window:SetSize(
		(inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
		(inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
	)

	window:Center()
	window:MakePopup()
	--window:ShowCloseButton(false)
	window:SetDraggable(false)
	window.OnKeyCodePressed = _windowOnKeyboardInput
	if parent and cvar_blur_bg:GetBool() then
		window:SetBackgroundBlur(true)
	end

	local inventory = vgui.Create("CaseInvPanel", window)
	inventory:SetSize(
		(inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
		(inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
	)
	inventory.InvTarget = inv

	if rtName ~= nil then
		inventory.RT = GetRenderTarget("re4case_RT_" .. rtName, ScrW(), ScrH())
		inventory.RTMat = CreateMaterial("re4case_MAT_" .. rtName, "UnlitGeneric", {
			["$basetexture"] = inventory.RT:GetName()
		})
	end

	inventory:NoClipping(true)
	CaseGUI.InvTargets[name] = inventory

	inventory.IsMainPanel = isMain

	return window
end

function CaseGUI.OpenInventory()
	if CaseGUI.IsOpen then
		return
	end

	local scaleW, scaleH = _CaseUIGetScaledDiff()
	local mwX, mwY = 0, 0 
	CaseGUI.MainWindow = _createWindow("MainWindow", CaseInv(LocalPlayer()), true, true, "MainWindow")
	CaseGUI.MainWindow:Center()

	mwX, mwY = CaseGUI.MainWindow:GetPos()
	mwX = mwX - ((__CASE_UI_BORDER/1.5) * scaleW)

	-- Nobody will notice it's slightly off center yeah?
	-- **YOU** won't tell about this right?
	CaseGUI.MainWindow:SetPos(mwX , mwY)
	CaseGUI.SortingWindow = _createWindow("SortingWindow", CaseInventory:GenerateInventory(6, 9), false, false, "SortingWindow")
	CaseGUI.MainWindow:SetPaintedManually(true)

	CaseGUI.SortingWindow:SetPos(mwX + CaseGUI.MainWindow:GetSize() + ((__CASE_UI_BORDER/2) * scaleW), mwY)
	CaseGUI.SortingWindow:SetPaintedManually(true)
	CaseGUI.IsOpen = true


	local mainWindowW = CaseGUI.MainWindow:GetSize()
	local button = vgui.Create("CaseInvExitButton", CaseGUI.MainWindow)
	button:SetText("")
	button:SetSize(25 * scaleH, 25 * scaleH)
	button:SetPos(mainWindowW - ((5*scaleW) +  (25 * scaleH)), (5*scaleW))
	button.DoClick = function()
		CaseGUI:Close()
	end

	if cvar_show_edit_button:GetBool() then
		local editButton = vgui.Create("CaseInvEditButton", CaseGUI.MainWindow)
		editButton:SetText("")
		editButton:SetSize(25 * scaleH, 25 * scaleH)
		editButton:SetPos(5*scaleW, 5*scaleH)
		editButton.DoClick = function()
			if IsValid(CaseGUI.EditWindow.Window) then
				CaseGUI:CloseEditMenu()
			else
				CaseGUI:OpenEditMenu()
			end
		end
	end

	if CaseGUI.ShouldPlaySounds:GetBool() then
		CaseGUI.PlaySound("ui/re4case/case_open.wav")
	end
end

concommand.Add("case_open", CaseGUI.OpenInventory)

-- Do this manually to remove flickering :)
hook.Add( "PostDrawHUD", "CASE_PostDrawHUD", function()
	if CaseGUI.IsOpen then
		-- Make a new 2D context so there isn't a 1px border where there isn't a blur
		cam.Start2D()
			CaseGUI.MainWindow:PaintManual()
			CaseGUI.SortingWindow:PaintManual()
		cam.End2D()
	end
end )