
-- Packet structure :)
--[[
    uint8 SizeX
    uint8 SizeY
    uint16 ItemCount
    for ItemCount
        uint16   index
        uint16   itemID
        uint32   count
        uint2    rotation
        uint8    X
        uint8    Y
]]--
net.Receive("CaseSync", function ()
    local ply = LocalPlayer()
    ply.CaseInv = {} -- Reset case
    ply.CaseInv.Size = {}
    ply.CaseInv.Items = {}
    ply.CaseInv.Loadout = {}

    local _ogSizeX, _ogSizeY = net.ReadUInt(8), net.ReadUInt(8)
    ply.CaseInv.Size = { -- add some extra space on for managment clientside only
        _ogSizeX + 6, -- SizeX
        math.max(_ogSizeY, 9), -- SizeY
        _ogSizeX,
        _ogSizeY
    }

    CaseInventory:ClearLoadout(ply)

    
    local itemCount = net.ReadUInt(16)
    print("Recv item count:", itemCount)
    for i=1, itemCount do
        local index = net.ReadUInt(16)
        local newItem = {
            ItemID=net.ReadUInt(16),
            Count=net.ReadUInt(32),
            Rotation=net.ReadUInt(2),
            X=net.ReadUInt(8),
            Y=net.ReadUInt(8)
        }

        PrintTable(newItem)
        ply.CaseInv.Items[index] = newItem
        CaseInventory:PlaceItem(ply.CaseInv.Loadout, index, newItem, {
            1, 1, _ogSizeX, _ogSizeY,
        })
    end

end)