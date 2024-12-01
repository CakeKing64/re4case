-- General hooks 'n stuff


hook.Add("Tick", "CASE_ServerTick", function ()
    for k, v in ipairs(player.GetAll()) do
        if v.CasePickupDelay > 0 then
            v.CasePickupDelay = v.CasePickupDelay - 1
        end
    end
end)

hook.Add("PlayerSay", "AAAAA_C", function (ply, text, team)
    if text == "debug" then
        for k, v in ipairs(CaseInventory.ItemRegister) do
            PrintTable(v)
        end
    end
    local n = tonumber(text)
    if n ~= nil then
        local nm = game.GetAmmoName(n)
        PrintMessage(HUD_PRINTTALK, nm)
        ply:GiveAmmo(5, n)
    end
    n = game.GetAmmoID(text)
    if n ~= -1 then
        PrintMessage(HUD_PRINTTALK, string.format("%s -> %i", text, n))
    end
end)