
function CaseInventory:SetupNetworkStrings()
    util.AddNetworkString("CASE_SyncItems")
end

function CaseInventory:PlayerItemSync(plr)
    PrintTable(plr.PlayerCase)
    net.Start("CASE_SyncItems")
    --net.WriteUInt(#plr.PlayerCase.Items)
    for k, v in pairs(plr.PlayerCase.Items) do
        --net.
    end
    net.Send(plr)
end