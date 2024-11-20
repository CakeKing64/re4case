local CVARS = {
    case_drop_on_death = CreateConVar("case_drop_on_death", "1", {FCVAR_ARCHIVE}, "", 0, 1),
    case_drop_excess_ammo = CreateConVar("case_drop_excess_ammo", "1", {FCVAR_ARCHIVE},"", 0, 1),
    case_pickup_mode = CreateConVar("case_pickup_mode", "1", {FCVAR_ARCHIVE}, [[0 -> Items can be walked over to be picked up
    1 -> Items must be +used to pickup (will still be picked up if in a vehicle)
    2 -> Items must be +used no matter what]], 0, 2),
    case_persist_mode = CreateConVar("case_persist_mode", "0", {FCVAR_ARCHIVE}, "???", 0, 2)
}

function CaseInventory:GetCVAR(name)
    return CVARS[name]
end