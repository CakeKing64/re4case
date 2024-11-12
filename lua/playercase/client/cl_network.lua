CaseInventory.ClientNet = {
    DropItem = function (invId, sync)
        net.Start("CaseCommandEvent")
        net.WriteUInt(CASE_COMMAND_DROP, 4)
        net.WriteUInt(invId, 16)
        net.WriteBool(sync)
        net.SendToServer()
    end,
    SyncItems = function ()
        net.Start("CaseCommandEvent")
        net.WriteUInt(CASE_COMMAND_SYNC, 4)
        for k, v in pairs(LocalPlayer().CaseInv.Items) do
            print("sending",k)
            net.WriteUInt(k, 16)
            net.WriteUInt(v.X, 8)
            net.WriteUInt(v.Y, 8)
            net.WriteBool(v.Rotated)
        end
        net.SendToServer()
    end


}


-- Packet structure :)
--[[
    uint8 SizeX
    uint8 SizeY
    uint16 ItemCount
    for ItemCount
        uint16   index
        uint16   itemID
        uint32   count
        uint1    rotated
        uint8    X
        uint8    Y
]]--
net.Receive("CaseSync", function ()
    local ply = LocalPlayer()
    ply.CaseInv = CaseInventory:GenerateInventory(net.ReadUInt(8), net.ReadUInt(8), LocalPlayer())
    CaseInventory:ClearLoadout(ply.CaseInv)

    
    local itemCount = net.ReadUInt(16)
    --print("Recv item count:", itemCount)
    for i=1, itemCount do
        local index = net.ReadUInt(16)
        local newItem = CaseInventory:CreateItemInfo(
            net.ReadUInt(16),   -- ItemID
            net.ReadUInt(32),   -- Count
            net.ReadBool(),     -- Rotated
            net.ReadUInt(8),    -- X
            net.ReadUInt(8)     -- Y

        )


        ply.CaseInv.Items[index] = newItem
        CaseInventory:PlaceItem(ply.CaseInv, index, newItem)
    end
    

    if CaseGUI.IsOpen then -- fuck you re-do your sorting
        for k, v in pairs(CaseGUI.InvTargets["SortingWindow"]:Inv().Items) do
            CaseGUI.InvTargets["SortingWindow"]:Inv().Items[v] = nil
        end
    end

end)