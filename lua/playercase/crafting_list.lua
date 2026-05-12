hook.Add("CaseRegisterRecipes", "CaseDefaultRecipes", function ()

	CaseInventory:RegisterCraftingRecipe("item_healthkit", 1, {weapon_crowbar = 1, re9_green_herb = 1})

	CaseInventory:RegisterCraftingRecipe("re9_mixed_herb", 1, {re9_green_herb = 3})
	CaseInventory:RegisterCraftingRecipe("re9_mixed_herb", 1, {re9_green_herb = 1, re9_red_herb = 1})
end)