
hook.Add("Initialize", "CASE_Initialize", function ()
    hook.Run("CaseRegisterItems")
    CaseInventory:AutoGenerate()
end)