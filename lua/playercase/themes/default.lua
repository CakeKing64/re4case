local tDefault = {
	["Inventory.Background"] = {
		Color = Color(42, 41, 37)
	},

	["Inventory.Item"] = {
		Color = Color(25,25,25, 200)
	},

	["Inventory.ItemHovered"] = {
		Color = Color(128, 128, 128, 128)
	},
	
	["Inventory.ItemCanPlace"] = {
		Color = Color(0, 128, 0, 128)
	},

	["Inventory.ItemWillSwap"] = {
		Color = Color(0, 128, 128, 128)
	},

	["Inventory.ItemCantPlace"] = {
		Color = Color(128, 0, 0, 128)
	},

	["Inventory.ExitButton"] = {
		Color = Color(220, 53, 69),

		-- The X
		Details = {
			Draw = true,
			Color = Color(255, 255, 255)
		}
	},

	["Inventory.EditZoneButton"] = {
		Color = Color(0xCC, 0x58, 0x01),

		-- Funny 3 lines
		Details = {
			Draw = true,
			Color = Color(255, 255, 255)
		}
	},

	["Inventory.ContextBackground"] = {
		Color = Color(90, 90, 85)
	},

	["Inventory.ContextButton"] = {
		Color = Color(60, 60, 55),

		-- The text
		Details = {
			Color = Color(255, 255, 255)
		}
	},

	["Inventory.ContextButtonHovered"] = {
		Color = Color(80, 80, 75),
		-- The text
		Details = {
			Color = Color(255, 255, 255)
		}
	},

	["Inventory.ContextButtonDisabled"] = {
		Color = Color(30, 30, 27),
		-- The text
		Details = {
			Color = Color(110, 110, 105)
		}
	},

	-- This is used for buttons that haven't been specifically setup
	-- This includes
	-- ToCraftButton
	-- ToInventoryButton
	-- CraftButton
	-- CraftMaxButton
	["Button.Disabled"] = {
		Color = Color(30, 30, 27, 255),
		Details = {
			Draw = true,
			Color = Color(110, 110, 105, 255)
		}
	},

	["Button.Enabled"] = {
		Color = Color(80, 80, 75, 255),
		Details = {
			Draw = true,
			Color = Color(255,255,255, 255)
		}
	},

	["Button.Hovered"] = {
		Color = Color(60, 60, 55, 255),
		Details = {
			Draw = true,
			Color = Color(255,255,255, 255)
		}
	},


	-- COLOR ONLY
	-- These will ignore anything other than Color
		
	["Inventory.ItemCount"] = {
		Color = Color(247, 237, 227, 255)
	},

    ["Inventory.ItemCountEmpty"] = {
		Color = Color(250, 61, 61, 255)
	},

    ["Inventory.ItemCountFull"] = {
		Color = Color(99, 199, 99, 255)
	},

	["Inventory.Grid"] = {
		Color = Color(255, 255, 255, 20)
	},
}

hook.Add("CaseRegisterThemes", "CaseDefaultTheme", function ()
	CaseGUITheme:AddTheme("Default", tDefault)
end)