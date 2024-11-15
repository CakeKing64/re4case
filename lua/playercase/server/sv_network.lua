local commands = {}



function commands.DropItem(ply, invID, sync)
    CaseInventory:DropItem(CaseInventory:Inv(ply), invID, ply, sync)
end

function commands.SyncLocations(ply, toPlace)
    local plyCopy = table.Copy(CaseInventory:Inv(ply))
    CaseInventory:ClearLoadout(plyCopy)

    

    for k, v in pairs(plyCopy.Items) do
        plyCopy.Items[k].X = toPlace[k].X
        plyCopy.Items[k].Y = toPlace[k].Y
        plyCopy.Items[k].Rotated = toPlace[k].Rotated
    end

    for k, v in pairs(plyCopy.Items) do
        -- If a **SINGLE** item can't be placed bail
        if not CaseInventory:PlaceItem(plyCopy, k, v) then
            return false
        end
    end

    CaseInventory:Inv(ply).Items = plyCopy.Items
    CaseInventory:Inv(ply).Loadout = plyCopy.Loadout
end
-- Client to server command packet structure
--[[
    uint4 command
]]--
net.Receive("CaseCommandEvent", function (len, ply)
    local cmd = net.ReadUInt(4)

    if cmd == CASE_COMMAND_DROP then
        local invID = net.ReadUInt(16)
        local sync = net.ReadBool()
        commands.DropItem(ply, invID, sync)
    end

    if cmd == CASE_COMMAND_SYNC then
        local newItems = {}
        for k, v in pairs(CaseInventory:Inv(ply).Items) do
            local invId = net.ReadUInt(16)
            local x = net.ReadUInt(8)
            local y = net.ReadUInt(8)
            local rotated = net.ReadBool()


            if CaseInventory:Inv(ply).Items[invId] == nil then
                print("id outside inventory :(", invId)
                return
            end

            newItems[invId] = {
                X=x,
                Y=y,
                Rotated=rotated
            }
        end

        commands.SyncLocations(ply, newItems)
        CaseInventory:Sync(ply)
    end
end)