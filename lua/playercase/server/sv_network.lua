local commands = {}



function commands.DropItem(ply, invID, count, sync)
    CaseInventory:DropItem(CaseInventory:Inv(ply), invID, count, ply, sync)
end

function commands.Use(ply, invID, sync)
    CaseInventory:UseItem(ply, invID, sync)
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

function commands.MergeItems(ply, srcID, destID, sync)
    CaseInventory:MergeItem(CaseInv(ply), CaseInv(ply), srcID, destID, sync)
end
-- Client to server command packet structure
--[[
    uint4 command
]]--
net.Receive("CaseCommandEvent", function (len, ply)
    local cmd = net.ReadUInt(4)

    if cmd == CASE_COMMAND_DROP then
        local invID = net.ReadUInt(16)
        local count = net.ReadInt(16)
        local sync = net.ReadBool()
        commands.DropItem(ply, invID, count, sync)
    end

    if cmd == CASE_COMMAND_SYNC then
        local newItems = {}
        for k, v in pairs(CaseInventory:Inv(ply).Items) do
            local invId = net.ReadUInt(16)
            local x = net.ReadUInt(8)
            local y = net.ReadUInt(8)
            local rotated = net.ReadBool()


            if CaseInventory:Inv(ply).Items[invId] == nil then
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
    
    if cmd == CASE_COMMAND_USE then
        local invID = net.ReadUInt(16)
        local sync = net.ReadBool()
        commands.Use(ply, invID, sync)
    end

    if cmd == CASE_COMMAND_MERGE then
        local srcID = net.ReadUInt(16)
        local destID = net.ReadUInt(16)
        local sync = net.ReadBool()
        commands.MergeItems(ply, srcID, destID, sync)
    end

    if cmd == CASE_COMMAND_SYNC_OVERRIDES then
        -- Admin only thing, now die
        if not ply:IsAdmin() then
            return
        end

        local itemID = net.ReadUInt(16)
		local delete = net.ReadBool()

		if delete then
			CaseInventory:SetOverride(itemID, true)
        else
            local model = net.ReadString()

            local size = {
                net.ReadUInt(16),
                net.ReadUInt(16)
            }

            -- Only size needs to be checked as the others are visual only
            if size[1] <= 0 then
                size[1] = 1
            end

            if size[2] <= 0 then
                size[2] = 1
            end

            local scale = net.ReadFloat()

            local offset = {
                net.ReadFloat(),
                net.ReadFloat(),
                net.ReadFloat()
            }
            
            local rotation = {
                net.ReadFloat(),
                net.ReadFloat(),
                net.ReadFloat()
            }

            -- Store it away
            CaseInventory:SetOverride(itemID, false, size, CaseRenderInfo(model, scale, rotation, offset, 0))
        end -- END NO DELETE

		-- Now time to replicate this to all clients
		CaseInventory:SendOverride(itemID)

		-- As a little bonus if items can't fit now drop them on the floor
		for k, v in ipairs(player.GetAll()) do
			if not IsValid(v) then
				continue
			end

			CaseInventory:Sync(v)
		end

		-- Save everything to disk
		CaseInventory:SaveOverrides()
    end

	--[[
	if cmd == CASE_COMMAND_REQUEST_OVERRIDES then
		if ply.HasSyncedOverrides == nil or not ply.HasSyncedOverrides then
			-- Only allow this once
			ply.HasSyncedOverrides = true
			for k, v in pairs(CaseInventory.RegisterOverrides) do
				CaseInventory:SendOverride(k, ply)
			end
		end
	end
	]]
end)