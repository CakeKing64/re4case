-- General hooks 'n stuff


hook.Add("Tick", "CASE_ServerTick", function ()
    for k, v in ipairs(player.GetAll()) do
        if v.CasePickupDelay > 0 then
            v.CasePickupDelay = v.CasePickupDelay - 1
        end
    end
end)