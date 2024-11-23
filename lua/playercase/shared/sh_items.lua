--[[
    Some info, read if you're gonna add something :)

    .OnUse/.CanUse are given three arguments, the player, the info table 
    and the inventoryID (will be -1 if not yet in the inventory!), you'll probably only need to use the player but do whatever
    BOTH are used client and serverside

    .CanUse returns true or false
    You can set CanUse to nil to indicate always usable

    .OnUse can return two items, a boolean (true/false) to indicate if an item was used and a number to indicate how many were used (optional, will default to 1)
    It will also be called both CLIENTSIDE AND SERVERSIDE
    clientside is ONLY used to calculate if the item would've actually been used, make sure to account for this :)

    You might want to set the player variable .CasePickup to the entity you want them to pickup instantly if you're gonna spawn the item to pickup

]]
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
---@param canUse function?
---@param ammoID number
---@param renderInfo table?
---@param printName string?
function CaseItem(name, sizeW, sizeH, maxSize, itemType, onUse, canUse, ammoID, renderInfo, printName)
    return {
        Name=name,
        PrintName=printName or "",
        Size={
            W=sizeW,
            H=sizeH
        },
        OnUse=onUse,
        CanUse=canUse,
        AmmoID=ammoID,
        MaxCount=maxSize,
        ItemType=itemType,
        RenderInfo=renderInfo or CaseRenderInfo(
            "models/error",
            1,
            {0,0,0}
        )
    }
end

---@param model string
---@param scale number?
---@param rotVec table|boolean? Uses this vector to apply rotations post xDiff/yDiff OR if it's true/false it'll apply 90 degrees instead
---@param offset table? Vector offset
---@param diffMode integer? 0 -> Use xDiff > yDiff, 1 -> Force yDiff, 2 -> Force xDiff
---@return table
function CaseRenderInfo(model, scale, rotVec, offset, diffMode)
    return {
        Model = model or "",
        Scale = scale, -- Ok to be nil
        Rotations = rotVec or {0, 0, 0},
        DiffMode = diffMode or 0,
        Offset = offset or Vector(0, 0)
    }


end

---Generic item
---@param name string
---@param printName string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@return table
function CaseGeneric(name, printName, renderInfo, sizeW, sizeH, maxSize)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, nil, nil, -1, renderInfo)
end

---Usable item
---@param name string
---@param printName string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param maxSize integer
---@param onUse function
---@param canUse function?
---@return table
function CaseConsumable(name, printName, renderInfo, sizeW, sizeH, maxSize, onUse, canUse)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, onUse, canUse, -1, renderInfo,  printName)
end

---Weapon :)
---@param name string
---@param renderInfo table?
---@param sizeW integer
---@param sizeH integer
---@param printName string? Last because only HL2 weapons will need to be manually added (their pickup names are all caps :()
---@return table
function CaseWeapon(name, renderInfo, sizeW, sizeH, printName)
    if printName == nil then
        local info = weapons.GetStored( name )
        if info ~= nil then
            printName = info.PrintName
        end
    end
    return CaseItem(name, sizeW, sizeH, 1, CASE_ITEM_WEAPON, nil, nil,-1, renderInfo, printName)
end

function CaseGrenade(name, renderInfo, sizeW, sizeH, maxSize, grenadeAmmo)
    return CaseItem(name, sizeW, sizeH, maxSize, CASE_ITEM_GRENADE, nil, nil, grenadeAmmo, renderInfo, game.GetAmmoName( grenadeAmmo ))
end

function CaseAmmo(ammoID, renderInfo, sizeW, sizeH, maxSize, printName)
    if printName == nil and not SERVER then
        printName = language.GetPhrase("#" .. game.GetAmmoName( ammoID ) .. "_ammo")
    end
    return CaseItem("case_ammo_" .. ammoID, sizeW, sizeH, maxSize, CASE_ITEM_AMMO, nil, nil, ammoID, renderInfo, printName)
end

function CaseGlowOnly(name)
   return CaseItem(name, 0, 0, 0, CASE_ITEM_GLOW_ONLY, nil, nil, -1, {}, "") 
end

-- Maybe move these to a different file?


local function _registerItemTable(tbl)
    for k, v in pairs(tbl) do
        CaseInventory:RegisterItem(v)
    end
end

local itemsHL2 = {
    -- Ammo
    CaseAmmo(game.GetAmmoID("AR2"),CaseRenderInfo("models/Items/combine_rifle_cartridge01.mdl", 2.7), 2, 1, 60),
    CaseAmmo(game.GetAmmoID("AR2AltFire"),CaseRenderInfo("models/Items/combine_rifle_ammo01.mdl", 2.1), 1, 2, 3),
    CaseAmmo(game.GetAmmoID("Pistol"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 1), 2, 1, 50),
    CaseAmmo(game.GetAmmoID("SMG1"),CaseRenderInfo("models/Items/BoxMRounds.mdl", 1.7), 2, 1, 90),
    CaseAmmo(game.GetAmmoID("357"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 6),
    CaseAmmo(game.GetAmmoID("XBowBolt"), CaseRenderInfo("models/Items/CrossbowRounds.mdl", 5), 4, 1, 20),
    CaseAmmo(game.GetAmmoID("Buckshot"), CaseRenderInfo("models/Items/BoxBuckshot.mdl", 1.3, {15, 180, 0}), 2, 1, 25),
    CaseAmmo(game.GetAmmoID("RPG_Round"),CaseRenderInfo("models/weapons/w_missile_closed.mdl", 4), 4, 1, 3),
    CaseAmmo(game.GetAmmoID("SMG1_Grenade"),CaseRenderInfo("models/Items/AR2_Grenade.mdl", 4), 2, 1, 5),
    CaseAmmo(game.GetAmmoID("AlyxGun"),CaseRenderInfo("models/Items/BoxSRounds.mdl", 3), 2, 1, 90),

    -- I have NO idea if any mods will use these or not
    -- (They're used by the combine)
    CaseAmmo(game.GetAmmoID("SniperRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 10, "Sniper Round"),
    CaseAmmo(game.GetAmmoID("SniperPenetratedRound"),CaseRenderInfo("models/Items/357ammo.mdl", 1.3, {25, 180, 0}), 2, 1, 10),
    
    -- Melee + Other
    CaseWeapon("weapon_crowbar",CaseRenderInfo("models/weapons/w_crowbar.mdl", 5, {90, 0, 90}), 2, 3, "Crowbar"),
    CaseWeapon("weapon_stunstick",CaseRenderInfo("models/weapons/w_stunbaton.mdl", 5, {90, 0, 90}, Vector(0, -1, -1.5)), 2, 3, "Stunstick"),
    CaseWeapon("weapon_physcannon",CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 180, 0}, Vector(0, 22)), 5, 2, "Gravity Gun"),
    CaseWeapon("weapon_crossbow",CaseRenderInfo("models/weapons/w_crossbow.mdl", 4.9, {0, 180,0}, Vector(0, 16.5)), 5, 3, "Crossbow"),
    CaseWeapon("weapon_rpg",CaseRenderInfo("models/weapons/w_rocket_launcher.mdl", 5, {0,0,0}, Vector(0,0,1)), 8, 2, "RPG Launcher"),

    -- Thrown
    CaseWeapon("weapon_bugbait", CaseRenderInfo("models/weapons/w_bugbait.mdl", 4), 1, 1),
    CaseGrenade("weapon_frag", CaseRenderInfo("models/Items/grenadeAmmo.mdl", 1.6), 1, 2, 3, game.GetAmmoID("Grenade")),
    CaseGrenade("weapon_slam",CaseRenderInfo("models/weapons/w_slam.mdl", 3, {0,90,-90}), 1, 2, 3, game.GetAmmoID("slam")),

    -- Pistol
    CaseWeapon("weapon_357",CaseRenderInfo("models/weapons/w_357.mdl", 4.5, {5, 180, 0}, Vector(0, 13)), 3, 2, ".347 Magnum"),
    CaseWeapon("weapon_pistol",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2, "9mm Pistol"),


    -- Shotgun
    CaseWeapon("weapon_shotgun",CaseRenderInfo("models/weapons/w_shotgun.mdl", 6), 6, 2, "Shotgun"),
    CaseWeapon("weapon_annabelle",CaseRenderInfo("models/weapons/w_annabelle.mdl", 1.5), 8, 2, "Annabelle"), -- tee hee


    -- Auto
    CaseWeapon("weapon_smg1",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2, "SMG"),
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
        kit:Use(ply)
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
        vial:Use(ply)
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
        battery:Use(ply)
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
        vial:Use(ply)
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


}

local itemsGMOD = {
    CaseWeapon("gmod_tool", CaseRenderInfo("models/weapons/w_toolgun.mdl", 3.5, {0, -90, 0}, Vector(0, 12)), 3, 2),
    CaseWeapon("gmod_camera", CaseRenderInfo("models/maxofs2d/camera.mdl", 3.5, {0, 210, 0}), 3, 2),
    CaseWeapon("weapon_physgun", CaseRenderInfo("models/weapons/w_physics.mdl", 4, {0, 0, 0}), 3, 2),
    CaseWeapon("weapon_medkit",  CaseRenderInfo("models/Items/HealthKit.mdl", 3.2, {90,90,0}, Vector(0,5,8)), 2, 3),
    CaseWeapon("manhack_welder",CaseRenderInfo("models/weapons/w_pistol.mdl", 4.3), 3, 2),
    CaseWeapon("weapon_flechettegun",CaseRenderInfo("models/weapons/w_smg1.mdl", 5, {0,180,0}, Vector(0,-8,0)), 3, 2),
}

--[[
    Basically all HL1 items don't give a :GetEyeTrace().Entity
    or barely give a ent_dump !picker
local itemsHL1 = {
    CaseWeapon("weapon_357_hl1", CaseRenderInfo("models/w_357.mdl"), 2, 3),
    CaseWeapon("weapon_shotgun_hl1",CaseRenderInfo("models/weapons/w_shotgun.mdl", 6), 6, 2),
}]]

hook.Add("CaseRegisterItems", "CaseDefaultItemRegister", function ()
    _registerItemTable(itemsGMOD)
    _registerItemTable(itemsHL2)
end)

