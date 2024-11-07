hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, _)
    plr.CaseInv = {} -- Reset case
    plr.CaseInv.Size = {6,10}
    plr.CaseInv.Items = {}
    plr.CaseInv.Loadout = {}
    plr.CaseInv.UseCommand = 0
end)

