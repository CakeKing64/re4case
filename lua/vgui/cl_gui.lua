local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32

CaseGUI = {
    HeldItem = {
        InvID=-1,
        SourceWindow=nil,
        Rotated=false,
        X=1,
        Y=1,
        OldInfo={} -- Store info to reset the pos & rot of an item
    },
    SortingWindow = nil,
    MainWindow = nil,
    HoveredWindow = nil,
    IsOpen = false,
    Context = {
        Panel=nil,
        Parent=nil,
        Item=-1
    },
    InvTargets = {
    },
    ShouldPlaySounds = CreateClientConVar("case_play_sounds", "1", true, false, [[Should sounds be played?
    Set to 2 to replace the more annoying sounds]], 0, 2 ),
    PlaySound = function (sound, replace)
        if not CaseGUI.ShouldPlaySounds:GetBool() then
            return
        end

        if replace ~= nil and CaseGUI.ShouldPlaySounds:GetInt() == 2 then
            surface.PlaySound(replace)
            return
        end

        surface.PlaySound(sound)
    end
}

-- The bane of GUI progammers world wide
-- Different hardware configurations
-- / Ultrawide users
function _CaseUIGetScaledSize()
    local height = ScrH()
    local width = height * (16/9) -- banish the ultrawide users to brazil

    return width, height
end

function _CaseUIGetScaledDiff()
    local newW, newH = _CaseUIGetScaledSize()
    
    return newW/ ogWidth, newH /ogHeight 
end

function _CaseUIGetCell(arguments)
    
end

function CaseGUI:Sync()
    -- Start by dropping all items stored in the sorting menu
    for k, v in pairs(self.InvTargets["SortingWindow"]:Inv().Items) do
        CaseInventory.ClientNet.DropItem(k, -1, false)
    end

    CaseInventory.ClientNet.SyncItems()
end

function CaseGUI:Close()
    self:Sync()
    self.SortingWindow:Close()
    self.MainWindow:Close()
    if self.Context.Panel ~= nil then
        self.Context.Panel:Remove()
    end
    self.SortingWindow = nil
    self.MainWindow = nil
    self.IsOpen = false
    self.Context = {
        Panel=nil,
        Parent=nil,
        Item=-1
    }
    self.HeldItem.InvID = -1

    if CaseGUI.ShouldPlaySounds:GetBool() then
        surface.PlaySound("ui/re4case/case_close.wav")
    end
end

function CaseGUI:CloseContext()
    if self.Context.Panel ~= nil then
        self.Context.Panel:Remove()
        self.Context.Panel = nil
        self.Context.Parent = nil
    end
end

---Creates a context item
---@param text string
---@param callback function
---@param allowed function?
---@param sound string?
function CaseGUI:AddContext(list, text, callback, allowed, sound)
    table.insert(list, {
        Text=text,
        Callback=callback,
        Allowed=allowed,
        Sound=sound
    })
end


hook.Add("CaseFillContext", "CaseDefaultFillContext", function (list, info)
    local itemInfo = info.ItemInfo
    if itemInfo.OnUse ~= nil then
        CaseGUI:AddContext(list, "Use", function () -- Actually use the item
            CaseInventory.ClientNet.UseItem(info.InvID, false) -- Request for the server to use the item
            -- Cool line
            local used, useCount = itemInfo.OnUse(LocalPlayer(), itemInfo, info.InvID)
            useCount = useCount and math.max(0, useCount) or 1

            if used then
                info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - useCount
                if info.Inv.Items[info.InvID].Count == 0 then
                    info.Inv.Items[info.InvID] = nil
                    CaseInventory:RefreshLoadout(info.Inv)
                    CaseGUI:CloseContext()
                end
            end


        end,
        function () -- Avail check
            if itemInfo.CanUse == nil then
                return true
            end
            return itemInfo.CanUse(LocalPlayer(), itemInfo, info.InvID)
        end
    )
    end

    if itemInfo.ItemType == CASE_ITEM_WEAPON or itemInfo.ItemType == CASE_ITEM_GRENADE then
        CaseGUI:AddContext(list, "Equip", function ()
            for _, wep in ipairs( LocalPlayer():GetWeapons() ) do
                if wep:GetClass() == itemInfo.Name then
                    input.SelectWeapon(wep)
                    break
                end
            end
            CaseGUI:CloseContext()
        end,
        function ()
            if not IsValid(LocalPlayer():GetActiveWeapon()) then
                return true
            end
            return LocalPlayer():GetActiveWeapon():GetClass() ~= itemInfo.Name
        end,
        "ui/re4case/case_equip.wav"
    )
    end
    
    if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
        CaseGUI:AddContext(list, "Drop 1", function ()
            CaseInventory.ClientNet.DropItem(info.InvID, 1, false)
            info.Inv.Items[info.InvID].Count = info.Inv.Items[info.InvID].Count - 1
            if info.Inv.Items[info.InvID].Count == 0 then
                info.Inv.Items[info.InvID] = nil
                CaseInventory:RefreshLoadout(info.Inv)
                CaseGUI:CloseContext()
            end


        end)
    end

end)


---Fills the context menu with that fits with whatever item was selected
---Params here just for ease of use
---@param panel table
---@param parent table
---@param itm integer
function CaseGUI:FillContext(panel, parent)
    local itemID = self.Context.Parent:Inv().Items[CaseGUI.Context.Item].ItemID
    local itemInfo = CaseInventory.ItemRegister[itemID]
    local list = {}

    hook.Call("CaseFillContext", nil, list, {
        Menu=self.Context.Panel,
        ItemID=itemID,
        ItemInfo=itemInfo,
        Inv=self.Context.Parent:Inv(),
        InvID=CaseGUI.Context.Item}
    )

    -- All items have this :)
    CaseGUI:AddContext(list,"Drop", function ()
        CaseInventory.ClientNet.DropItem(CaseGUI.Context.Item, -1, false)
        parent:Inv().Items[CaseGUI.Context.Item] = nil

        CaseInventory:RefreshLoadout(self.Context.Parent:Inv())
        CaseGUI:CloseContext()
    end)

    for k, v in pairs(list) do
        panel:AddOption(v.Text, v.Callback, v.Allowed, v.Sound)
    end
end




local function _createWindow(name, inv, parent, isMain)
    local window = vgui.Create("DFrame")
    window:NoClipping(true)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()

    window:SetSize(
        (inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
        (inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
    )

    window:Center()
    window:MakePopup()
    --window:ShowCloseButton(false)
    window:SetDraggable(false)
    if parent then
        window:SetBackgroundBlur(true)
    end

    local inventory = vgui.Create("CaseInvPanel", window)
    inventory:SetSize(
        (inv.Size[1] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
        (inv.Size[2] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
    )
    inventory.InvTarget = inv
    inventory:NoClipping(true)
    CaseGUI.InvTargets[name] = inventory

    inventory.IsMainPanel = isMain

    return window
end
-- thank u chat gee pea tei
local function OpenBasicPanel()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local mwX, mwY = 0, 0 
    CaseGUI.MainWindow = _createWindow("MainWindow", CaseInv(LocalPlayer()), true, true)
    CaseGUI.MainWindow:Center()

    mwX, mwY = CaseGUI.MainWindow:GetPos()
    mwX = mwX - ((__CASE_UI_BORDER/1.5) * scaleW)

    -- Nobody will notice it's slightly off center yeah?
    -- **YOU** won't tell about this right?
    CaseGUI.MainWindow:SetPos(mwX , mwY)
    CaseGUI.SortingWindow = _createWindow("SortingWindow", CaseInventory:GenerateInventory(6, 9), false, false)

    CaseGUI.SortingWindow:SetPos(mwX + CaseGUI.MainWindow:GetSize() + ((__CASE_UI_BORDER/2) * scaleW), mwY)
    CaseGUI.IsOpen = true


    local mainWindowW = CaseGUI.MainWindow:GetSize()
    local button = vgui.Create("CaseInvExitButton", CaseGUI.MainWindow)
    button:SetText("")
    button:SetSize(25 * scaleH, 25 * scaleH)
    button:SetPos(mainWindowW - ((5*scaleW) +  (25 * scaleH)), (5*scaleW))
    button.DoClick = function()
        CaseGUI:Close()
    end

    if CaseGUI.ShouldPlaySounds:GetBool() then
        CaseGUI.PlaySound("ui/re4case/case_open.wav")
    end
end

concommand.Add("case_open", OpenBasicPanel)