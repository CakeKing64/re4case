hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, _)
    plr.CaseInv = {} -- Reset case
    plr.CaseInv.Size = {6,10}
    plr.CaseInv.Items = {}
    plr.CaseInv.Loadout = {}
    plr.CaseInv.UseCommand = 0
    plr.CaseInvUse = 0 -- Only thing that doesn't need to persist over saves

    --[[
    plr:SetVar("CaseInv", {
        Size={6,10},
        Items={},
        Loadout={}
    })
    ]]--
end)

