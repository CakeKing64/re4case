
hook.Add("InitPostEntity", "CASE_Initialize", function ()
    hook.Run("CaseRegisterItems")
    print("items should be registered by now...")
    CaseInventory:AutoGenerate()
end)