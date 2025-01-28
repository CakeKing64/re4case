
hook.Add("Initialize", "CASE_Initialize", function ()


end)


-- This is done later to make sure everything that can be auto-generated will be
-- I --ran into-- keep running into some issues with ammo generation at some point
hook.Add("InitPostEntity", "CASE_InitPostEntity", function ()
    hook.Run("CaseRegisterItems")
    CaseInventory:AutoGenerate()

    if CLIENT and not CaseInventory.ItemRegisterApply then
        return
    end

    -- Serverside stuff
    CaseInventory:FinalizeItemRegister()

    if CLIENT then
        CaseInventory:RefreshLoadout(CaseInv())
    end
end)

