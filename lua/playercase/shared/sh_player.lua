hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, trans)

    if not trans or plr.CaseInv == nil then
        plr.CaseInv = {} -- Reset case
        plr.CaseInv.Size = {10,6}
        plr.CaseInv.Items = {}
        plr.CaseInv.Loadout = {}
        plr.CaseInv.UseCommand = 0

        for x=1,plr.CaseInv.Size[1] do
            plr.CaseInv.Loadout[x] = {}
            for y=1,plr.CaseInv.Size[2] do
                plr.CaseInv.Loadout[x][y] = 0
            end
        end
    end
end)

