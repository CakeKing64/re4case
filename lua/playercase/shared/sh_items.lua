CASE_ITEM_GENERIC       = 0
CASE_ITEM_WEAPON        = 1
CASE_ITEM_GRENADE       = 2
CASE_ITEM_GLOW_ONLY     = 3 -- Only used to show that ammo can be obtained
CASE_ITEM_AMMO          = 4
CASE_ITEM_AMMO_SPECIAL  = 5 -- Used for the caseammo entity to store any type of ammo


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
            Vector(0, 0, 0)
        )
    }
end

function CaseRenderInfo(model, scale, vecOffset)
    return {
        Model = model or "",
        Scale = scale, -- Ok to be nil
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

-- Maybe move these to a different file?


local function _registerItemTable(tbl)
    for k, v in pairs(tbl) do
        CaseInventory:RegisterItem(v)
    end
end

local itemsGMOD = {
    -- Ammo
    CaseAmmo(game.GetAmmoID("AR2"), 2, 1, 60),
    CaseAmmo(game.GetAmmoID("AR2AltFire"), 1, 2, 3),
    CaseAmmo(game.GetAmmoID("Pistol"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 50),
    CaseAmmo(game.GetAmmoID("SMG1"),CaseRenderInfo("models/Items/BoxMRounds.mdl", 3), 2, 1, 90),
    CaseAmmo(game.GetAmmoID("357"),CaseRenderInfo("models/Items/356ammo.mdl"), 2, 1, 6),
    CaseAmmo(game.GetAmmoID("XBowBolt"), CaseRenderInfo("models/Items/CrossbowRounds.mdl"), 4, 1, 20),
    CaseAmmo(game.GetAmmoID("Buckshot"), CaseRenderInfo("models/Items/BoxBuckshot.mdl"), 2, 1, 25),
    CaseAmmo(game.GetAmmoID("RPG_Round"), 4, 1, 3),
    CaseAmmo(game.GetAmmoID("SMG1_Grenade"),CaseRenderInfo("models/Items/AR2_Grenade.mdl", 3), 2, 1, 5),
    CaseAmmo(game.GetAmmoID("AlyxGun"), 2, 1, 90),

    -- I have NO idea if any mods will use these or not
    -- (They're used by the combine)
    CaseAmmo(game.GetAmmoID("SniperRound"), 2, 1, 10),
    CaseAmmo(game.GetAmmoID("SniperPenetratedRound"), 2, 1, 10),
    
    -- Melee + Other
    CaseWeapon("weapon_crowbar",CaseRenderInfo("models/weapons/w_crowbar.mdl", 4.4), 2, 3),
    CaseWeapon("weapon_stunstick", 2, 3),
    CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 4.4), 5, 2),
    CaseWeapon("weapon_crossbow",CaseRenderInfo("models/weapons/w_crossbow.mdl", 4.5), 5, 3),
    CaseWeapon("weapon_rpg", 8, 2),
    CaseWeapon("gmod_tool", 3, 2),

    -- Thrown
    CaseWeapon("weapon_bugbait", 1, 1),
    CaseGrenade("weapon_frag", CaseRenderInfo("models/Items/grenadeAmmo.mdl", 2.8), 1, 2, 3, game.GetAmmoID("Grenade")),
    CaseGrenade("weapon_slam", 1, 2, 3, game.GetAmmoID("slam")),

    -- Pistol
    CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 6), 3, 2),
    CaseWeapon("weapon_pistol",CaseRenderInfo("models/weapons/w_pistol.mdl", 4), 3, 2),


    -- Shotgun
    CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 4.5), 8, 2),
    CaseWeapon("weapon_annabelle", 8, 2), -- tee hee


    -- Auto
    CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 4.5), 3, 2),
    CaseWeapon("weapon_ar2", 5, 2),
    CaseWeapon("weapon_alyxgun", 3, 2), -- tee hee 2

    -- Consumables (yummers)
    CaseConsumable("item_healthkit", 4, 4, 3, function (arguments)
        
    end),
    CaseConsumable("item_healthvial", 1, 2, 3, function (arguments)
        
    end),
    CaseConsumable("item_battery", 1, 2, 3, function (arguments)
        
    end)
    
}

_registerItemTable(itemsGMOD)
