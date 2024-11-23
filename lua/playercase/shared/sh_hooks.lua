
hook.Add("InitPostEntity", "CASE_Initialize", function ()
    hook.Run("CaseRegisterItems")
    CaseInventory:AutoGenerate()
end)
