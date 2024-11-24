
hook.Add("Initialize", "CASE_Initialize", function ()
    hook.Run("CaseRegisterItems")
    
end)

-- This is done later to make sure everything that can be auto-generated will be
-- I ran into some issues with ammo generation at some point
hook.Add("InitPostEntity", "CASE_InitPostEntity", function ()
    CaseInventory:AutoGenerate()
    for k, v in ipairs(player.GetAll()) do
        CaseInventory:Sync(v)
    end
end)