CASE_ITEM_GENERIC       = 0 -- :Use will be called when picking up normally, holding Alt/walk will add it to inventory (useful for healing/armor)
CASE_ITEM_WEAPON        = 1
CASE_ITEM_GRENADE       = 2
CASE_ITEM_GLOW_ONLY     = 3 -- Only used to show that ammo can be obtained, :Use will be called instead of adding to inventory
CASE_ITEM_AMMO          = 4
CASE_ITEM_AMMO_SPECIAL  = 5 -- Used for the caseammo entity to store any type of ammo

---@param name string
---@param sizeW number
---@param sizeH number
---@param maxSize number
---@param itemType number
---@param onUse function?
---@param ammoID number
---@param renderInfo table
function CaseItem(name, sizeW, sizeH, maxSize, itemType, onUse, ammoID, renderInfo)
    return {
        Name=name,
        Size={
            W=sizeW,
            H=sizeH
        },
        OnUse=onUse,
        AmmoID=ammoID,
        MaxCount=maxSize,
        ItemType=itemType,
        RenderInfo=renderInfo or CaseRenderInfo(
            "models/error",
            nil,
            false,
            Vector(0, 0, 0)
        )
    }
end

---@param model string
---@param scale number?
---@param rotate boolean?
---@param forceRot integer? 0 -> Use xDiff > yDiff, 1 -> Force yDiff (0 deg rotation), 2 -> Force xDiff (90 deg rotation)
---@param vecOffset table?
function CaseRenderInfo(model, scale, rotate, forceRot,  vecOffset)
    return {
        Model = model or "",
        Scale = scale, -- Ok to be nil
        Rotate = rotate or false,
        ForceRot = forceRot or 0,
        VecOffset = vecOffset or Vector(0, 0, 0)
    }


end

function CaseGeneric(name, renderInfo, sizeW, sizeH, maxSize)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, nil, -1, renderInfo)
end

function CaseConsumable(name, renderInfo, sizeW, sizeH, maxSize, onUse)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, onUse, -1, renderInfo)
end

function CaseWeapon(name, renderInfo, sizeW, sizeH)
    return CaseItem(name, sizeW, sizeH, 1, CASE_ITEM_WEAPON, nil, -1, renderInfo)
end

function CaseGrenade(name, renderInfo, sizeW, sizeH, maxSize, grenadeAmmo)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GRENADE, nil, grenadeAmmo, renderInfo)
end

function CaseAmmo(ammoID, renderInfo, sizeW, sizeH, maxSize)
    return CaseItem("case_ammo_" .. ammoID, sizeW, sizeH, maxSize, CASE_ITEM_AMMO, nil, ammoID, renderInfo)
end

function CaseGlowOnly(name)
   return CaseItem(name, 0, 0, 0, CASE_ITEM_GLOW_ONLY, nil, -1, {}) 
end

-- Maybe move these to a different file?


local function _registerItemTable(tbl)
    for k, v in pairs(tbl) do
        CaseInventory:RegisterItem(v)
    end
end

local itemsGMOD = {
    -- Ammo
    CaseAmmo(game.GetAmmoID("AR2"),CaseRenderInfo("models/Items/combine_rifle_cartridge01.mdl", 2.7), 2, 1, 60),
    CaseAmmo(game.GetAmmoID("AR2AltFire"),CaseRenderInfo("models/Items/combine_rifle_ammo01.mdl", 2.1), 1, 2, 3),
    CaseAmmo(game.GetAmmoID("Pistol"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 50),
    CaseAmmo(game.GetAmmoID("SMG1"),CaseRenderInfo("models/Items/BoxMRounds.mdl", 2.7), 2, 1, 90),
    CaseAmmo(game.GetAmmoID("357"),CaseRenderInfo("models/Items/357ammo.mdl", 3), 2, 1, 6),
    CaseAmmo(game.GetAmmoID("XBowBolt"), CaseRenderInfo("models/Items/CrossbowRounds.mdl", 5), 4, 1, 20),
    CaseAmmo(game.GetAmmoID("Buckshot"), CaseRenderInfo("models/Items/BoxBuckshot.mdl", 2), 2, 1, 25),
    CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4), 4, 1, 3),
    CaseAmmo(game.GetAmmoID("SMG1_Grenade"),CaseRenderInfo("models/Items/AR2_Grenade.mdl", 4), 2, 1, 5),
    CaseAmmo(game.GetAmmoID("AlyxGun"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 90),

    -- I have NO idea if any mods will use these or not
    -- (They're used by the combine)
    CaseAmmo(game.GetAmmoID("SniperRound"),CaseRenderInfo("models/Items/357ammo.mdl", 3), 2, 1, 10),
    CaseAmmo(game.GetAmmoID("SniperPenetratedRound"),CaseRenderInfo("models/Items/357ammo.mdl", 3), 2, 1, 10),
    
    -- Melee + Other
    CaseWeapon("weapon_crowbar",CaseRenderInfo("models/weapons/w_crowbar.mdl", 5, true), 2, 3),
    CaseWeapon("weapon_stunstick",CaseRenderInfo("models/weapons/w_stunbaton.mdl", 5, true), 2, 3),
    CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 4), 5, 2),
    CaseWeapon("weapon_crossbow",CaseRenderInfo("models/weapons/w_crossbow.mdl", 4.5), 5, 3),
    CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5), 8, 2),
    CaseWeapon("gmod_tool", CaseRenderInfo("models/weapons/w_toolgun.mdl", 0.55, false, 2), 3, 2),
    CaseWeapon("gmod_camera", CaseRenderInfo("models/weapons/w_toolgun.mdl", 0.55, false, 2), 3, 2),

    -- Thrown
    CaseWeapon("weapon_bugbait", CaseRenderInfo("models/weapons/w_bugbait.mdl", 4), 1, 1),
    CaseGrenade("weapon_frag", CaseRenderInfo("models/Items/grenadeAmmo.mdl", 1.6), 1, 2, 3, game.GetAmmoID("Grenade")),
    CaseGrenade("weapon_slam",CaseRenderInfo("models/weapons/w_slam.mdl", 1.6, true, 0), 1, 2, 3, game.GetAmmoID("slam")),

    -- Pistol
    CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.3), 3, 2),
    CaseWeapon("weapon_pistol",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2),


    -- Shotgun
    CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 6), 6, 2),
    CaseWeapon("weapon_annabelle",CaseRenderInfo("models/weapons/w_annabelle.mdl", 1.5), 8, 2), -- tee hee


    -- Auto
    CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 4), 3, 2),
    CaseWeapon("weapon_ar2",CaseRenderInfo("models/weapons/w_irifle.mdl", 5.6), 5, 2),
    CaseWeapon("weapon_alyxgun",CaseRenderInfo("models/weapons/w_alyx_gun.mdl", 0.5), 3, 2), -- tee hee 2

    -- Consumables (yummers)
    CaseConsumable("item_healthkit", CaseRenderInfo("models/Items/HealthKit.mdl", 4), 2, 3, 1, function (arguments)
        
    end),
    CaseConsumable("item_healthvial",CaseRenderInfo("models/healthvial.mdl", 2, false, 0),  1, 2, 1, function (arguments)
        
    end),
    CaseConsumable("item_battery", CaseRenderInfo("models/weapons/w_bugbait.mdl", 4), 1, 2, 1, function (arguments)
        
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
}

_registerItemTable(itemsGMOD)
