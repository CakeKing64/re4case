hook.Add("PlayerSpawn", "CASE_PlayerSpawn", function(plr, _)
    plr.PlayerCase = {} -- Reset case
    plr.PlayerCase.Size = 4
    plr.PlayerCase.Items = {}
    plr.PlayerCase.Loadout = {} -- Client only stuff
    plr.PlayerCase.PickupDelay = false
end)

