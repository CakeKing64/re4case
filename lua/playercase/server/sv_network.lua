-- Client to server command packet structure
--[[
    uint8 SizeX
    uint8 SizeY
    uint16 ItemCount
    for ItemCount
        uint16   index
        uint16   itemID
        uint32   count
        uint1    rotation
        uint8    X
        uint8    Y
]]--
net.Receive("CaseSync", function ()
    local ply = LocalPlayer()
    ply.CaseInv = {} -- Reset case
    ply.CaseInv.Size = {}
    ply.CaseInv.Items = {}
    ply.CaseInv.Loadout = {}


    ply.CaseInv.Size = {
        net.ReadUInt(8), -- SizeX
        net.ReadUInt(8) -- SizeY
    }

    CaseInventory:ClearLoadout(ply)

    
    local itemCount = net.ReadUInt(16)
    print("Recv item count:", itemCount)
    for i=1, itemCount do
        local index = net.ReadUInt(16)
        local newItem = {
            ItemID=net.ReadUInt(16),
            Count=net.ReadUInt(32),
            Rotated=net.ReadUInt(2),
            X=net.ReadUInt(8),
            Y=net.ReadUInt(8)
        }

        PrintTable(newItem)
        ply.CaseInv.Items[index] = newItem
        CaseInventory:PlaceItem(ply, index, newItem)
    end

end)