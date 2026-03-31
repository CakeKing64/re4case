--[[

	The built in compat list
	Hooray

]]--


local function _registerItemTable(tbl)
	for k, v in pairs(tbl) do
		CaseInventory:RegisterItem(v)
	end
end

-- Each entry should be setup like this
-- List of workshop ids that trigger it, function to call
local ItemList = {
}


local itemsHL2 = {
	-- Ammo
	CaseAmmo(game.GetAmmoID("AR2"),CaseRenderInfo("models/Items/combine_rifle_cartridge01.mdl", 2.7), 2, 1, 60),
	CaseAmmo(game.GetAmmoID("AR2AltFire"),CaseRenderInfo("models/Items/combine_rifle_ammo01.mdl", 2.1), 1, 2, 3),
	CaseAmmo(game.GetAmmoID("Pistol"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 1), 2, 1, 50),
	CaseAmmo(game.GetAmmoID("SMG1"),CaseRenderInfo("models/Items/BoxMRounds.mdl", 1.7), 2, 1, 90),
	CaseAmmo(game.GetAmmoID("357"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 10),
	CaseAmmo(game.GetAmmoID("XBowBolt"), CaseRenderInfo("models/Items/CrossbowRounds.mdl", 5), 4, 1, 20),
	CaseAmmo(game.GetAmmoID("Buckshot"), CaseRenderInfo("models/Items/BoxBuckshot.mdl", 1.3, {15, 180, 0}), 2, 1, 25),
	CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4), 4, 1, 3),
	CaseAmmo(game.GetAmmoID("SMG1_Grenade"),CaseRenderInfo("models/Items/AR2_Grenade.mdl", 4), 2, 1, 5),
	CaseAmmo(game.GetAmmoID("AlyxGun"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 90),

	-- Mods like to use these ones :(
	CaseAmmo(game.GetAmmoID("SniperRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 15),
	CaseAmmo(game.GetAmmoID("SniperPenetratedRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 15),
	
	-- Melee + Other
	CaseWeapon("weapon_crowbar",CaseRenderInfo("models/weapons/w_crowbar.mdl", 5, {90, 0, 90}), 2, 3, "Crowbar"),
	CaseWeapon("weapon_stunstick",CaseRenderInfo("models/weapons/w_stunbaton.mdl", 5, {90, 0, 90}, Vector(0, -1, -1.5)), 2, 3, "Stunstick"),
	CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 180, 0}, Vector(0, 22)), 5, 2, "Gravity Gun"),
	CaseWeapon("weapon_crossbow",CaseRenderInfo("models/weapons/w_crossbow.mdl", 4.9, {0, 180,0}, Vector(0, 16.5)), 5, 2, "Crossbow"),
	CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5, {0,0,0}, Vector(0,0,1)), 8, 2, "RPG Launcher"),

	-- Thrown
	CaseWeapon("weapon_bugbait", CaseRenderInfo("models/weapons/w_bugbait.mdl", 4), 1, 1),
	CaseGrenade("weapon_frag", CaseRenderInfo("models/Items/grenadeAmmo.mdl", 1.6), 1, 2, 3, game.GetAmmoID("Grenade")),
	CaseGrenade("weapon_slam",CaseRenderInfo("models/weapons/w_slam.mdl", 3, {0,90,-90}), 1, 2, 3, game.GetAmmoID("slam")),

	-- Pistol
	CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.5, {5, 180, 0}, Vector(0, 13)), 3, 2, ".357 Magnum"),
	CaseWeapon("weapon_pistol",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2, "9mm Pistol"),


	-- Shotgun
	CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 5.5, {}, Vector(0, 0, -1)), 6, 2, "Shotgun"),
	CaseWeapon("weapon_annabelle",CaseRenderInfo("models/weapons/w_annabelle.mdl", 7, {}, Vector(0, 0, -1)), 8, 2, "Annabelle"), -- tee hee


	-- Auto
	CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-3,0)), 3, 2, "SMG"),
	CaseWeapon("weapon_ar2",CaseRenderInfo("models/weapons/w_irifle.mdl", 5.6), 5, 2, "Pulse-Rifle"),
	CaseWeapon("weapon_alyxgun",CaseRenderInfo("models/weapons/w_alyx_gun.mdl", 0.5), 3, 2, "Alyx's Gun"), -- tee hee 2

	-- Consumables (yummers)
	CaseConsumable("item_healthkit", "Health Kit", CaseRenderInfo("models/Items/HealthKit.mdl", 3.2, {90,90,0}, Vector(0,5,8)), 2, 3, 3,
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end

		local kit = ents.Create("item_healthkit")
		kit:Spawn()
		ply.CasePickup = kit
		kit:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end),

	CaseConsumable("item_healthvial", "Health Vial", CaseRenderInfo("models/healthvial.mdl", 1.9, {0,125}, Vector(0,0.2)),  1, 2, 3, 
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end
		local vial = ents.Create("item_healthvial")
		vial:Spawn()
		ply.CasePickup = vial
		vial:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end),

	CaseConsumable("item_battery", "Suit Battery", CaseRenderInfo("models/items/battery.mdl", 2.1, {0,-60,180}, Vector(0,-0.2,10)), 1, 2, 3,
	function (ply) -- OnUse
		if CLIENT then
			return true
		end

		local battery = ents.Create("item_battery")
		battery:Spawn()
		ply.CasePickup = battery
		battery:SetPos(ply:GetPos())
		return true
	end,    
	function (ply) -- CanUse
		if ply:Armor() >= ply:GetMaxArmor() then
			return false
		end
		return true
	end),

	-- Forgot this was a thing until i was playing EP2
	-- All of these will probably only restore 4 health
	-- Mostly just cus yeah
	-- ent_dump reveals they can do more but i'm lazy
	CaseConsumable("item_grubnugget", "Grub Nugget", CaseRenderInfo("models/grub_nugget_small.mdl", 3),  1, 1, 5, 
	function (ply, tbl) -- OnUse
		if CLIENT then
			return true
		end
		local vial = ents.Create("item_grubnugget")
		vial:Spawn()
		ply.CasePickup = vial
		vial:SetPos(ply:GetPos())
		return true
	end,
	function (ply) -- CanUse
		if ply:Health() >= ply:GetMaxHealth() then
			return false
		end
		return true
	end),


	CaseGlowOnly("ent_caseammo"),
	CaseGlowOnly("ent_caseupgrade"),
	CaseGlowOnly("ent_caseupgrade_m"),
	CaseGlowOnly("ent_caseupgrade_l"),
	CaseGlowOnly("ent_caseupgrade_xl"),
	CaseGlowOnly("ent_caseupgrade_xxl"),

	CaseGlowOnly("item_ammo_357"),
	CaseGlowOnly("item_ammo_357_large"),

	CaseGlowOnly("item_ammo_ar2"),
	CaseGlowOnly("item_ammo_ar2_altfire"),
	CaseGlowOnly("item_ammo_ar2_large"),

	CaseGlowOnly("item_ammo_pistol"),
	CaseGlowOnly("item_ammo_pistol_large"),

	CaseGlowOnly("item_ammo_crossbow"),

	CaseGlowOnly("item_ammo_smg1"),
	CaseGlowOnly("item_ammo_smg1_large"),
	CaseGlowOnly("item_ammo_smg1_grenade"),

	CaseGlowOnly("item_box_buckshot"),

	CaseGlowOnly("item_rpg_round"),



	--[[
		Some generic ammo types :shrug:
	]]
	CaseAmmo(game.GetAmmoID("Thumper"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Gravity"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Battery"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("GaussEnergy"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("CombineCannon"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("AirboatGun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("StriderMinigun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("HelicopterGun"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("StriderMinigunDirect"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("CombineHeavyCannon"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),

	--[[
		HL:S Ammo
	]]
	CaseAmmo(game.GetAmmoID("9mmRound"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("357Round"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("BuckshotHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("XBowBoltHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("MP5_Grenade"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("RPG_Rocket"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Uranium"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("GrenadeHL1"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Hornet"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Snark"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("TripMine"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("Satchel"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30),
	CaseAmmo(game.GetAmmoID("12mmRound"), CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 30)
}

local itemsGMOD = {
	CaseDoNotHandle("weapon_fists"),
	CaseWeapon("gmod_tool", CaseRenderInfo("models/weapons/w_toolgun.mdl", 3.5, {0, -90, 0}, Vector(0, 12)), 3, 2),
	CaseWeapon("gmod_camera", CaseRenderInfo("models/maxofs2d/camera.mdl", 3.5, {0, 210, 0}), 3, 2),
	CaseWeapon("weapon_physgun", CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 0, 0}), 3, 2),
	CaseWeapon("weapon_medkit",  CaseRenderInfo("models/Items/HealthKit.mdl", 3.2, {90,90,0}, Vector(0,5,8)), 2, 3),
	CaseWeapon("manhack_welder",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2),
	CaseWeapon("weapon_flechettegun",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2),
	CaseWeapon("weapon_base", CaseRenderInfo("models/weapons/w_357.mdl"), 3, 2),
}

-- https://steamcommunity.com/sharedfiles/filedetails/?id=1606822274
-- MMod Weapon Replacement #1
table.insert(ItemList, {{"1606822274"}, function()
	return {
		CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2, "SMG"),
		CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 6), 6, 2, "Shotgun")
	}
end})

-- https://steamcommunity.com/sharedfiles/filedetails/?id=2035609495
-- MMod Weapon Replacement #2
table.insert(ItemList, {{"1606822274"}, function()
	return {
		CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 3.5, {0, 0, 0}, Vector(0, 5)), 5, 2, "Gravity Gun"),
		CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl",6, {0,180,0}, Vector(0,-7,0)), 3, 2, "SMG"),
		CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5.5, {0,0,40}, Vector(0,0,4.5)), 8, 2, "RPG Launcher"),
		CaseWeapon("weapon_ar2",CaseRenderInfo("models/weapons/w_irifle.mdl", 6, {}, Vector(0, -3, 0.25)), 5, 2, "Pulse-Rifle"),
		CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.5, {0, 0, 0}, Vector(0, 0)), 3, 2, ".357 Magnum"),
		CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4, {0, 180}), 4, 1, 3),
	}
end})

-- ARC9 Base
table.insert(ItemList, {{"2910505837"}, function()
	return {
		CaseWeapon("arc9_base", CaseRenderInfo(""), 3, 2),
		CaseWeapon("arc9_base_nade", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("arc9_uplp_grenade_base", CaseRenderInfo("models/weapons/w_eq_fraggrenade.mdl"), 3, 2),
	}
end})

-- TFA Base
table.insert(ItemList, {{"2840031720"}, function()
	return {
		CaseWeapon("tfa_sword_advanced_base", CaseRenderInfo(""), 3, 2),
		CaseWeapon("tfa_3dbash_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_shotty_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_gun_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_cssnade_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nade_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_knife_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_bash_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_melee_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_scoped_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_bow_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_akimbo_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_3dscoped_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2)
	}
end})

local function __NMRINH()
	return {
		CaseWeapon("tfa_nmrimelee_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nmrih_base_3d", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),
		CaseWeapon("tfa_nmrih_base_fa", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),

		-- Melee
		CaseWeapon("tfa_nmrih_fists", CaseRenderInfo(""), 1, 1),
		CaseWeapon("tfa_nmrih_hatchet", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_hatchet.mdl", 3.5, {0,-90}, Vector(0,1.5)), 2, 3),
		CaseWeapon("tfa_nmrih_bat", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_bat_metal.mdl", 0.75, {}, Vector(0,-0.5)), 1, 4),
		CaseWeapon("tfa_nmrih_bcd", CaseRenderInfo("models/weapons/tfa_nmrih/w_tool_barricade.mdl", 1.5, {0, 180}, Vector(0, 0, -2)), 1, 3),
		CaseWeapon("tfa_nmrih_wrench", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_wrench.mdl", 4, {0, 180}, Vector(0, 1, -1)), 1, 2),
		CaseWeapon("tfa_nmrih_chainsaw", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_chainsaw.mdl", 5, {-9, 180, 0}, Vector(0,45, -2)), 4, 2),
		CaseWeapon("tfa_nmrih_sledge", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_sledge.mdl", 1.2), 2, 4),
		CaseWeapon("tfa_nmrih_machete", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_machete.mdl", 2.7, {0,180}), 1, 3),
		CaseWeapon("tfa_nmrih_etool", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_etool.mdl", 0.5), 2, 3),
		CaseWeapon("tfa_nmrih_spade", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_spade.mdl", 1.3),2, 4),
		CaseWeapon("tfa_nmrih_fireaxe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_axe_fire.mdl", 2.5, {0, 180}, Vector(0, 2)), 2, 3),
		CaseWeapon("tfa_nmrih_crowbar", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_crowbar.mdl", 2.5, {0, 180}), 2, 3),
		CaseWeapon("tfa_nmrih_kknife", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_kitknife.mdl", 5, {0, 180}), 1, 2),
		CaseWeapon("tfa_nmrih_lpipe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_pipe_lead.mdl", 2.7, {0, 180}), 2, 3),
		CaseWeapon("tfa_nmrih_fubar", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_fubar.mdl", 1.3, {0, 180}, Vector(0, 7)), 2, 4),
		CaseWeapon("tfa_nmrih_pickaxe", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_pickaxe.mdl", 2.8, {0, 180}, Vector(0, 5.5)), 2, 3),
		CaseWeapon("tfa_nmrih_cleaver", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_cleaver.mdl", 3.9, {0, 180}, Vector(0, 6, -1)), 1, 2),
		CaseWeapon("tfa_nmrih_asaw", CaseRenderInfo("models/weapons/tfa_nmrih/w_me_abrasivesaw.mdl", 4, {0, 180}, Vector(0, 29)), 4, 2),

		-- Pistol
		CaseWeapon("tfa_nmrih_m92fs", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m92fs.mdl", 15, {0, -90}, Vector(0,15, -1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_1911", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_1911.mdl",6, {0, -90}, Vector(0, 2, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_g17", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_glock17.mdl", 6, {0, -90}, Vector(0, 1, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_mkiii", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mkiii.mdl", 6, {0, -90}, Vector(0, 2, 1.5)), 3, 2),
		CaseWeapon("tfa_nmrih_sw686", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sw686.mdl", 6, {0, -90}, Vector(0, 22, -1.5)), 3, 2),

		-- AR
		CaseWeapon("tfa_nmrih_m16_ch", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m16a4_carryhandle.mdl", 5, {0, 180}, Vector(0, 18.5)), 5, 2),
		CaseWeapon("tfa_nmrih_m16_rt", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_m16a4.mdl", 5, {0, 180}, Vector(0, 18.5)), 5, 2),
		CaseWeapon("tfa_nmrih_cz", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_cz858.mdl", 5, {0, 180}, Vector(0, 10.5)), 5, 2),
		CaseWeapon("tfa_nmrih_fal", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_fnfal.mdl",4 , {0, -90}), 6, 2),

		-- SMG
		CaseWeapon("tfa_nmrih_mp5", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mp5.mdl", 5, {0, 180}, Vector(0, 3.5)), 3, 2),
		CaseWeapon("tfa_nmrih_mac10", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_mac10.mdl", 5, {0, -90}, Vector(0,-2)), 2, 2),

		-- Shogun (funny)
		CaseWeapon("tfa_nmrih_sv10", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sv10.mdl", 5, {0, 180}, Vector(0, 3)), 6, 2),
		CaseWeapon("tfa_nmrih_500a", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_500a.mdl", 5, {0, 180}, Vector(0, 23, -1)), 6, 2),
		CaseWeapon("tfa_nmrih_870", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_870.mdl", 5, {0, 180}, Vector(0, 15, 0)), 6, 2),
		CaseWeapon("tfa_nmrih_superx3", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_superx3.mdl", 4, {0, -90}, Vector(0, 0, 0)), 7, 2),


		-- Rifle (no A?????)
		CaseWeapon("tfa_nmrih_jae700", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_jae700.mdl", 4.5, {0, 180, -50}, Vector(0, 25, 0.4)), 7, 1),
		CaseWeapon("tfa_nmrih_rug1022", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_ruger1022.mdl", 4, {0, -90, -50}), 6, 1),
		CaseWeapon("tfa_nmrih_rug1022_25", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_ruger1022_25mag.mdl", 4, {0, -90, -50}), 6, 2),
		CaseWeapon("tfa_nmrih_sako", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sako85.mdl", 4, {0, -90}, Vector(0, -1)), 6, 2),
		CaseWeapon("tfa_nmrih_sako_is", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sako85_ironsights.mdl", 4, {0, -90, -50}, Vector(0, -1.9, 0.5)), 6, 1),
		CaseWeapon("tfa_nmrih_sks", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sks.mdl", 5, {0, 180, -50}, Vector(0, 30)), 7, 1),
		CaseWeapon("tfa_nmrih_sks_nb", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_sks_nobayo.mdl", 6, {0, 180, -50}, Vector(0, 25)), 6, 1),
		CaseWeapon("tfa_nmrih_1892", CaseRenderInfo("models/weapons/tfa_nmrih/w_fa_win1892.mdl", 3.5, {0, -90}, Vector(0, 0, 0)), 6, 2),


		-- Ammo
		-- This should probably be pretty universal for any other mods that want to use it
		CaseAmmo("gasoline", CaseRenderInfo("models/props_junk/gascan001a.mdl", 1), 2, 3, 300),
	}
end

-- No more room in hell melee + guns
table.insert(ItemList, {{"828059724", "2849966415"}, __NMRINH})

-- Poly Arms
table.insert(ItemList, {{"3098824960"}, function ()
	return {
		CaseWeapon("arc9_uplp_knife", CaseRenderInfo("models/weapons/arc9/w_uplp_knife.mdl", 2, {}, Vector(0,-1,0)), 1 , 3),
		CaseGrenade("arc9_uplp_grenade_flash", CaseRenderInfo("models/weapons/arc9/w_uplp_m84.mdl"),1,2,1, game.GetAmmoID("arc9_uplp_grenade_flash")),
		CaseGrenade("arc9_uplp_grenade_frag", CaseRenderInfo("models/weapons/arc9/w_uplp_m26.mdl"),1,2,1, game.GetAmmoID("arc9_uplp_grenade_frag")),  



		-- SMG
		CaseWeapon("arc9_uplp_ak_smg", CaseRenderInfo("models/weapons/arc9/w_uplp_ak_smol.mdl", 7, {0, 180}, Vector(0,-7)), 4, 2),
		CaseWeapon("arc9_uplp_mac", CaseRenderInfo("models/weapons/arc9/w_uplp_mac11.mdl", 5, {0, 180}, Vector(0, 2)), 2, 2),
		CaseWeapon("arc9_uplp_mp9", CaseRenderInfo("models/weapons/arc9/w_uplp_mp9.mdl", 10, {0, 180}, Vector(0,-14)), 3, 2),
		CaseWeapon("arc9_uplp_mp5", CaseRenderInfo("models/weapons/arc9/w_uplp_mp5.mdl", 7, {0, 180}, Vector(0,-9)), 4, 2),
		CaseWeapon("arc9_uplp_mp7", CaseRenderInfo("models/weapons/arc9/w_uplp_mp7.mdl", 9, {0, 180}, Vector(0,-14)), 3, 2),
		CaseWeapon("arc9_uplp_g36", CaseRenderInfo("models/weapons/arc9/w_uplp_g36.mdl", 7, {0, 180, 0}, Vector(0, -5, 0)), 3, 2),
		CaseWeapon("arc9_uplp_ar57", CaseRenderInfo("models/weapons/arc9/w_uplp_ar57.mdl", 7.5, {0, 180, 0}, Vector(0, -5.2, 0)), 4, 2),

		-- Sniper
		CaseWeapon("arc9_uplp_awp", CaseRenderInfo("models/weapons/arc9/w_uplp_awp.mdl", 5.2, {0, 180}, Vector(0, 2)), 7, 2),
		CaseWeapon("arc9_uplp_orsis", CaseRenderInfo("models/weapons/arc9/w_uplp_orsis.mdl", 5 ,{0, 180}, Vector(0, 10)), 7, 2),
		CaseWeapon("arc9_uplp_mjolnir", CaseRenderInfo("models/weapons/arc9/w_uplp_mjolnir.mdl", 6, {0, 180, 0}, Vector(0, 3, -2)), 7, 2),
		CaseWeapon("arc9_uplp_sr25", CaseRenderInfo("models/weapons/arc9/w_uplp_sr25.mdl", 5.5, {0, 180, 0}, Vector(0, -2.5, 0)), 6, 2),
		CaseWeapon("arc9_uplp_marlin", CaseRenderInfo("models/weapons/arc9/w_uplp_marlin.mdl", 5.5, {0, 180, 0}, Vector(0, -1.5, 0)), 6, 2),

		-- Shotguns
		CaseWeapon("arc9_uplp_molot", CaseRenderInfo("models/weapons/arc9/w_uplp_molot.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_spas", CaseRenderInfo("models/weapons/arc9/w_uplp_spas.mdl", 5.2, {0, 180}, Vector(0,-2)),6 ,2 ),
		CaseWeapon("arc9_uplp_m590", CaseRenderInfo("models/weapons/arc9/w_uplp_590.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_r870", CaseRenderInfo("models/weapons/arc9/w_uplp_870.mdl", 5.2, {0, 180}, Vector(0, -2)),6 ,2 ),
		CaseWeapon("arc9_uplp_dbs", CaseRenderInfo("models/weapons/arc9/w_uplp_db.mdl", 5.2, {0, 180, 0}, Vector(0, -4, 0)), 6, 2),
		CaseWeapon("arc9_uplp_ks23", CaseRenderInfo("models/weapons/arc9/w_uplp_ks23.mdl", 5.2, {0, 180, 0}, Vector(0, 0, 0)), 6, 2),

		-- funny guns
		CaseWeapon("arc9_uplp_deagle", CaseRenderInfo("models/weapons/arc9/w_uplp_deagle.mdl", 4.5, {0, 180}, Vector(0, 4.5)), 3, 2),
		CaseWeapon("arc9_uplp_fn57", CaseRenderInfo("models/weapons/arc9/w_uplp_fn57.mdl", 4.5, {0, 180}, Vector(0,3.5)), 3, 2),
		CaseWeapon("arc9_uplp_m9", CaseRenderInfo("models/weapons/arc9/w_uplp_beretta.mdl", 4.5, {0, 180}, Vector(0, 4.5)), 3, 2),
		CaseWeapon("arc9_uplp_rsh12", CaseRenderInfo("models/weapons/arc9/w_uplp_rsh12.mdl", 5, {0, 180}, Vector(0, 10)), 3, 2),
		CaseWeapon("arc9_uplp_usp", CaseRenderInfo("models/weapons/arc9/w_uplp_usp.mdl", 5, {0, 180, 0}, Vector(0, 4.5, 0)), 3, 2),


		-- ARs
		CaseWeapon("arc9_uplp_ak", CaseRenderInfo("models/weapons/arc9/w_uplp_ak.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_ak12", CaseRenderInfo("models/weapons/arc9/w_uplp_ak12.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_ar15", CaseRenderInfo("models/weapons/arc9/w_uplp_ar15.mdl",8, {0, 180}, Vector(0, -6)), 5, 2),
		CaseWeapon("arc9_uplp_aug", CaseRenderInfo("models/weapons/arc9/w_uplp_aug.mdl",7.5, {0, 180}, Vector(0, -8.5)), 5, 2),
		CaseWeapon("arc9_uplp_fal", CaseRenderInfo("models/weapons/arc9/w_uplp_fal.mdl",5.25, {0, 180}, Vector(0, 2)), 6, 2),
		CaseWeapon("arc9_uplp_ar18", CaseRenderInfo("models/weapons/arc9/w_uplp_ar18.mdl",6, {0, 180}, Vector(0, -3)), 5, 2),
		CaseWeapon("arc9_uplp_asval", CaseRenderInfo("models/weapons/arc9/w_uplp_asval.mdl",6, {0, 180}, Vector(0, -5)), 5, 2),
		CaseWeapon("arc9_uplp_scar", CaseRenderInfo("models/weapons/arc9/w_uplp_scar.mdl",5.7, {0, 180}, Vector(0, -4)), 6, 2),
		CaseWeapon("arc9_uplp_mutant", CaseRenderInfo("models/weapons/arc9/w_uplp_mutant.mdl", 6.7, {0, 180, 0}, Vector(0, -5, 0)), 5, 2),
		CaseWeapon("arc9_uplp_base", CaseRenderInfo("models/weapons/w_pistol.mdl"), 3, 2),

		-- big gun
		CaseWeapon("arc9_uplp_pkm", CaseRenderInfo("models/weapons/arc9/w_uplp_pkm.mdl", 5.6, {0, 180, 0}, Vector(0, 0, 0)), 5, 2),
		CaseWeapon("arc9_uplp_minigun", CaseRenderInfo("models/weapons/arc9/w_uplp_minigun.mdl", 6, {0, 180, 0}, Vector(0, 18, 0)), 6, 3)
	}
end})

local function _RegisterItems()
	_registerItemTable(itemsGMOD)
	_registerItemTable(itemsHL2)

	-- 
	for _, addon in ipairs(engine.GetAddons()) do
		if not addon.mounted then
			continue
		end

		local workshopID = addon.wsid

		for _, item in ipairs(ItemList) do
			if item.Used ~= nil and item.Used then
				continue
			end

			for _, wID in ipairs(item[1]) do
				if wID == workshopID then
					item.Used = true
					_registerItemTable(item[2]()) -- Register stuff
				end
			end
		end
	end
end

hook.Add("CaseRegisterItems", "CaseDefaultItemRegister", function ()
	_RegisterItems()
end)