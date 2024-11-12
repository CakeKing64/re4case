local cmd = {}



function cmd:CombineItems()
    
end


function cmd:NewItemLoadout()
    
end

-- Client to server command packet structure
--[[
    uint4 command
]]--
net.Receive("CaseCommandEvent", function ()
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