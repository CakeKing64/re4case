hook.Add("PreDrawHalos", "CASE_PreDrawHalos", function ()
    local lookTarget = LocalPlayer():GetEyeTrace().Entity

    if IsValid(lookTarget) and
        LocalPlayer():GetPos():Distance(lookTarget:GetPos()) < 75
    then
        if lookTarget:IsWeapon() or lookTarget:IsScripted() or CaseInventory:IsValid(lookTarget:GetClass()) then
            halo.Add({lookTarget}, Color(0,255,0), 2, 2, 2)
        end
    end
end)

hook.Add("Think", "CASE_Think", function ()
    if CaseGUI.SortingWindow != nil then
        CaseGUI.SortingWindow:MoveToFront()
    end
end)

hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    
end)