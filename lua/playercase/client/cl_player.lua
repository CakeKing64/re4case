local mStatus = {
    Left = false,
    Right = false,
    Up = false,
    Down = false
}

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

-- Very fancy way of doing this
hook.Add("CreateMove", "CASE_CreateMove", function (cmd)
    mStatus.Left = input.WasMousePressed( MOUSE_LEFT )
    mStatus.Right = input.WasMousePressed( MOUSE_RIGHT )

    mStatus.Up = input.WasMousePressed( MOUSE_WHEEL_UP )
    mStatus.Down = input.WasMousePressed( MOUSE_WHEEL_DOWN )
end)

-- This hook is only really for the GUI
hook.Add("Think", "CASE_Think", function ()

    if CaseGUI.IsOpen then
        -- Reset the held item back to its last position
        if mStatus.Right then
            CaseGUI.HeldItem.InvID = -1
        end

        if mStatus.Up or mStatus.Down then
            CaseGUI.HeldItem.Rotated = not CaseGUI.HeldItem.Rotated
        end

    end


    if CaseGUI.SortingWindow ~= nil then
        -- Move the second window to the front so it's not obscured by the blur
        CaseGUI.SortingWindow:MoveToFront()

        if CaseGUI.HeldItem.InvID == -1 then-- and CaseInventory:ItemSize(CaseGUI.SortingWindow:Inv().Items) == 0 then
            CaseGUI.SortingWindow:Hide()
        else
            CaseGUI.SortingWindow:Show()
        end
    end
end)

hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    
end)