local ClientSettings = {}
ClientSettings.DropExtraAmmo = nil
ClientSettings.DropOnDeath = nil
ClientSettings.Frame0Pickup = nil
ClientSettings.PickupMode = nil
ClientSettings.DefaultCaseSize = nil
ClientSettings.CustomCaseSize = nil
ClientSettings.AutoGenerate = nil


function ClientSettings:Populate(panel)
	ClientSettings.DropExtraAmmo = panel:CheckBox("Drop Excess Ammo", "case_sv_drop_excess_ammo")
	ClientSettings.DropOnDeath = panel:CheckBox("Drop Items On Death", "case_sv_drop_on_death")
	ClientSettings.Frame0Pickup = panel:CheckBox("Pickup Items Frame 0", "case_sv_frame_0_pickup")
	ClientSettings.PickupMode = panel:ComboBox("Pickup Mode", "case_sv_pickup_mode")
	self.PickupMode:AddChoice("Allow the client to decide", -1)
	self.PickupMode:AddChoice("Walk over to pickup items", 0)
	self.PickupMode:AddChoice("Use to pickup, unless in vehicle", 1)
	self.PickupMode:AddChoice("Use to pickup", 2)

	ClientSettings.DefaultCaseSize = panel:ComboBox("Default Case Size")
	self.DefaultCaseSize:AddChoice("Small")
	self.DefaultCaseSize:AddChoice("Medium")
	self.DefaultCaseSize:AddChoice("Large")
	self.DefaultCaseSize:AddChoice("Extra Large")
	self.DefaultCaseSize:AddChoice("Extra Extra Large")
	self.DefaultCaseSize:AddChoice("Custom")
	self.DefaultCaseSize.OnSelect = function( _, index, _ )
		local sizes = {
			"s",
			"m",
			"l",
			"xl",
			"xxl"
		}

		if index ~= 6 then
			RunConsoleCommand("case_sh_default_size", sizes[index])
			ClientSettings.CustomCaseSize:SetEnabled(false)
		else
			ClientSettings.CustomCaseSize:SetEnabled(true)
			RunConsoleCommand("case_sh_default_size", ClientSettings.CustomCaseSize:GetText())
		end
	end




	ClientSettings.CustomCaseSize = panel:TextEntry("Custom Case Size")
	ClientSettings.CustomCaseSize:SetText("5 9")
	ClientSettings.CustomCaseSize.OnChange = function()
        RunConsoleCommand("case_sh_default_size", ClientSettings.CustomCaseSize:GetText())
    end

	ClientSettings.AutoGenerate = nil


	
	local caseSize = string.lower(GetConVar("case_sh_default_size"):GetString())
	if caseSize == "s" then
		self.DefaultCaseSize:ChooseOptionID(1)
	elseif caseSize == "m" then
		self.DefaultCaseSize:ChooseOptionID(2)
	elseif caseSize == "l" then
		self.DefaultCaseSize:ChooseOptionID(3)
	elseif caseSize == "xl" then
		self.DefaultCaseSize:ChooseOptionID(4)
	elseif caseSize == "xxl" then
		self.DefaultCaseSize:ChooseOptionID(5)
	else
		self.DefaultCaseSize:ChooseOptionID(6)
		self.CustomCaseSize:SetText(caseSize)
	end
	
end

hook.Add("PopulateToolMenu", "CaseAddServerSettings", function()
	spawnmenu.AddToolMenuOption("Utilities", "RE4 Case", "RE4CaseServerSettings", "#Server Settings", "", "", function(panel)
		ClientSettings.Panel = panel
		ClientSettings:Populate(panel)
	end)
end)