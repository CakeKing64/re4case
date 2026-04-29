local ClientSettings = {}
ClientSettings.BlurBG = nil
ClientSettings.DrawWeaponNames = nil
ClientSettings.EnableSwapping = nil
ClientSettings.InvertPickup = nil
ClientSettings.MenuFPS = nil
ClientSettings.PlaySounds = nil
ClientSettings.PreferSprites = nil


function ClientSettings:Populate(panel)
	self.BlurBG = panel:CheckBox("Blur Case Background", "case_cl_blur_bg")
	self.DrawWeaponNames = panel:CheckBox("Draw Weapon Names", "case_cl_draw_weapon_names")
	self.EnableSwapping = panel:CheckBox("Enable Swapping", "case_cl_enable_swapping")
	self.MenuFPS = panel:TextEntry("Menu FPS")
	self.MenuFPS.OnChange = function()
		local fps = tonumber(self.MenuFPS:GetText())
		if fps == nil then
			fps = 40
		end
		GetConVar("case_cl_menu_fps"):SetInt(fps)
	end

	self.MenuFPS:SetText(GetConVar("case_cl_menu_fps"):GetString())
	self.InvertPickup = panel:CheckBox("Invert Pickup Mode", "case_cl_invert_pickup")
	panel:ControlHelp("If off, using an item will use it otherwise holding walk (alt) will pick it up\nIf on, using an item will pick it up while holding walk will try to use it")

	self.PickupMode = panel:ComboBox("Pickup Mode", "case_cl_pickup_mode")
	self.PickupMode:AddChoice("Walk over to pickup items", 0)
	self.PickupMode:AddChoice("Use to pickup, unless in vehicle", 1)
	self.PickupMode:AddChoice("Use to pickup", 2)
	panel:ControlHelp("This setting can be overridden by the server\nAlso Walk over to pickup will only work with items that would do that normally without this mod")
	
	
	self.PlaySounds = panel:ComboBox("Play Sounds", "case_cl_play_sounds")
	self.PlaySounds:AddChoice("Disable Sounds", 0)
	self.PlaySounds:AddChoice("Enable Sounds", 1)
	self.PlaySounds:AddChoice("Enable Sounds (Alt. sounds)", 2)

	self.ShowEditButton = panel:CheckBox("Show edit button", "case_cl_show_edit")

	self.PreferSprites = panel:ComboBox("Prefer Sprites", "case_cl_prefer_sprites")
    self.PreferSprites:AddChoice("Only If Setup", 0)
    self.PreferSprites:AddChoice("Only sprite files", 1)
    self.PreferSprites:AddChoice("Always", 2)
	panel:ControlHelp("If set to no, only items that have specifically be overridden to use a sprite / have been setup that way will use a sprite\n")
	panel:ControlHelp("If set to Always, the inventory will try to use spawn icons as well")

end

hook.Add("PopulateToolMenu", "CaseAddSettings", function()
	spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseSettings", "#Client Settings", "", "", function(panel)
		ClientSettings.Panel = panel
		ClientSettings:Populate(panel)
	end)
end)