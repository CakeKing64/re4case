local mStatus = {
    Left = 0,
    Right = 0,
    Up = 0,
    Down = 0
}

local function _checkInput(name, thing)

    if mStatus[name] < 0 then
        mStatus[name] = mStatus[name] + 1
    end

    if input.IsMouseDown(thing) and mStatus[name] ~= 2 then
        mStatus[name] = mStatus[name] + 1
    else
        mStatus[name] = 0
    end
end

hook.Add("PreDrawHalos", "CASE_PreDrawHalos", function ()
    local lookTarget = LocalPlayer():GetEyeTrace().Entity

    if IsValid(lookTarget) and
        LocalPlayer():GetPos():Distance(lookTarget:GetPos()) < 75
    then
        local itemID = CaseInventory:GetItemID(lookTarget:GetClass())
        if itemID == -1 then
            return
        end

        local itemInfo = CaseInventory.ItemRegister[itemID]
        local drawColor = Color(0, 255, 0)

        -- Weapons will just give ammo if we already have one
        if itemInfo.ItemType == CASE_ITEM_WEAPON and not CaseInventory:HasItem(CaseInv(), itemID) then
            if not CaseInventory:FindValidSpot(CaseInv(), itemID) then
                drawColor = Color(255, 0, 0)
            end
        end

        if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
            local freeSpace = false
            local canUse = false

            if itemInfo.ItemType == CASE_ITEM_GENERIC and not LocalPlayer():KeyDown(IN_WALK) and itemInfo.CanUse(LocalPlayer(), itemInfo, -1) then
                canUse = true
                drawColor = Color(0, 0, 255)
            end

            if not canUse then
                for k, v in pairs(CaseInv().Items) do
                    if v.ItemID == itemID and v.Count < itemInfo.MaxCount then
                        freeSpace = true
                        break
                    end
                end
            end

            if not freeSpace and not canUse and not CaseInventory:FindValidSpot(CaseInv(), itemID) then
                drawColor = Color(255, 0, 0)
            end
        end
        
        halo.Add({lookTarget}, drawColor, 2, 2, 2)
    end
end)

-- Very fancy way of doing this
hook.Add("CreateMove", "testMouseWheel", function(cmd)
    if input.WasMousePressed(MOUSE_WHEEL_UP) then
        mStatus.Up = 1
    end

    if input.WasMousePressed(MOUSE_WHEEL_DOWN) then
        mStatus.Down = 1
    end
end)

-- This hook is only really for the GUI
hook.Add("Think", "CASE_Think", function ()

    _checkInput("Left", MOUSE_LEFT)
    _checkInput("Right", MOUSE_RIGHT)


    if CaseGUI.IsOpen then
        -- Reset the held item back to its last position
        if mStatus.Right == 1 then
            CaseGUI.HeldItem.InvID = -1
        end

        if mStatus.Up == 1 or mStatus.Down == 1 then
            mStatus.Up = 0
            mStatus.Down = 0

            CaseGUI.HeldItem.Rotated = not CaseGUI.HeldItem.Rotated
        end

    end


    if CaseGUI.SortingWindow ~= nil then
        -- Move the second window to the front so it's not obscured by the blur
        CaseGUI.SortingWindow:MoveToFront()
        local hasItem = false
        for k, v in pairs(CaseGUI.InvTargets["SortingWindow"]:Inv().Items) do
            if v ~= nil then
                hasItem = true
                break
            end
        end

        if CaseGUI.HeldItem.InvID == -1 and not hasItem then-- and  then
            CaseGUI.SortingWindow:Hide()
        else
            CaseGUI.SortingWindow:Show()
        end
    end

    if CaseGUI.Context.Panel ~= nil then
        if CaseGUI.Context.Parent:Inv().Items[CaseGUI.Context.Item] == nil then
            CaseGUI.Context.Panel:Remove()
            CaseGUI.Context.Panel = nil
            return
        end
        CaseGUI.Context.Panel:MoveToFront()
        if CaseGUI.Context.Parent == CaseGUI.InvTargets["SortingWindow"] and not CaseGUI.SortingWindow:IsVisible() then
            CaseGUI.Context.Panel:Remove()
            CaseGUI.Context.Panel = nil
        else 
            CaseGUI.Context.Panel:MoveToFront()
        end
    end
end)

hook.Add("PlayerDeath", "CASE_PlayerDeath", function (victim, inflictor, attacker)
    
end)


hook.Add( "InitPostEntity", "CASE_PostInit", function()
    -- A sync event happened before the client was ready, apply it now
	if CaseInventory.ClientNet.SyncTemp ~= nil then 
        local ply = LocalPlayer()
        PrintTable(CaseInventory.ClientNet.SyncTemp)
        CaseInventory.ClientInventory = CaseInventory:GenerateInventory(
            CaseInventory.ClientNet.SyncTemp.W,
            CaseInventory.ClientNet.SyncTemp.H, ply)

        for k, v in pairs(CaseInventory.ClientNet.SyncTemp.Items) do
            CaseInventory:Inv().Items[k] = v
            CaseInventory:PlaceItem(CaseInventory:Inv(), k, v)
        end
        CaseInventory.ClientNet.SyncTemp = nil
    end
end )

-- Hook into the pause menu (ESC) so we can close the case if it's open
hook.Add( "OnPauseMenuShow", "CASE_OnyPauseMenuShow", function()
	if CaseGUI.IsOpen then
        CaseGUI:Close()
        return false
    end
	return true
end )