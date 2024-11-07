CASE_ITEM_GENERIC       = 0
CASE_ITEM_WEAPON        = 1
CASE_ITEM_GRENADE       = 2
CASE_ITEM_AMMO_HOLDER   = 3 -- Gives CASE_ITEM_AMMO 
CASE_ITEM_AMMO          = 4
CASE_ITEM_AMMO_SPECIAL  = 5 -- Used for the caseammo entity to store any type of ammo


function CaseItem(sizeW, sizeH, maxSize, itemType, onUse, ammoID)
    return {
        Name="Placeholder :)",
        Size={
            W=sizeW,
            H=sizeH
        },
        OnUse=nil,
        AmmoID=ammoID,
        MaxCount=maxSize,
        ItemType=itemType
    }
end

function CaseGeneric(sizeW, sizeH, maxSize)
    return CaseItem(sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, nil, -1)
end

function CaseConsumable(sizeW, sizeH, maxSize, onUse)
    return CaseItem(sizeW, sizeH, maxSize, CASE_ITEM_GENERIC, onUse, -1)
end

function CaseWeapon(sizeW, sizeH)
    return CaseItem(sizeW, sizeH, 1, CASE_ITEM_WEAPON)
end

function CaseGrenade(sizeW, sizeH, maxSize)
    
end

function CaseAmmo(sizeW, sizeH, maxSize, ammoID)
    return CaseItem(sizeW, sizeH, maxSize, CASE_ITEM_AMMO, nil, ammoID)
end

function CaseAmmoCrate()
    
end


local function _registerItemTable(tbl)
    for k, v in pairs(tbl) do
        CaseInventory:RegisterItem(k, v)
    end
end

local function _registerAmmoTable(tbl)
    for k, v in pairs(tbl) do
        CaseInventory:RegisterItem(
            "case_ammo_" .. game.GetAmmoID(k),
            v)
    end
end

local ammoGMOD = {
    CaseAmmo(2, 1, 50, game.GetAmmoID("Pistol"))
}

local itemsGMOD = {
    item_ammo_pistol = CaseAmmoCrate()
}


_registerAmmoTable(ammoGMOD)
_registerItemTable(itemsGMOD)
