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
    }
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
        Parent=nil
    }
    self.HeldItem.InvID = -1
end

function CaseGUI:CloseContext()
    if self.Context.Panel ~= nil then
        self.Context.Panel:Remove()
        self.Context.Panel = nil
        self.Context.Parent = nil
    end
end


---Fills the context menu with that fits with whatever item was selected
---Params here just for ease of use
---@param panel table
---@param parent table
---@param itm integer
function CaseGUI:FillContext(panel, parent)
    
    local itemInfo = CaseInventory.ItemRegister[self.Context.Parent:Inv().Items[CaseGUI.Context.Item].ItemID]

    if itemInfo.OnUse ~= nil then
        panel:AddOption("Use", function () -- Actually use the item
            CaseInventory.ClientNet.UseItem(CaseGUI.Context.Item, false) -- Request for the server to use the item
            local item = CaseInventory.ItemRegister[parent:Inv().Items[CaseGUI.Context.Item].ItemID]
            -- Cool line
            local used, useCount = item.OnUse(LocalPlayer(), item, CaseGUI.Context.Item)
            useCount = useCount and math.max(0, useCount) or 1

            if used then
                parent:Inv().Items[CaseGUI.Context.Item].Count = parent:Inv().Items[CaseGUI.Context.Item].Count - useCount
                if parent:Inv().Items[CaseGUI.Context.Item].Count == 0 then
                    parent:Inv().Items[CaseGUI.Context.Item] = nil
                    CaseInventory:RefreshLoadout(self.Context.Parent:Inv())
                    self:CloseContext()
                end
            end


        end,
        function () -- Avail check
            local item = CaseInventory.ItemRegister[parent:Inv().Items[CaseGUI.Context.Item].ItemID]
            if item.CanUse == nil then
                return true
            end
            return item.CanUse(LocalPlayer(), item, CaseGUI.Context.Item)
        end
    )
    end

    if itemInfo.ItemType == CASE_ITEM_WEAPON or itemInfo.ItemType == CASE_ITEM_GRENADE then
        panel:AddOption("Equip", function ()
            for _, wep in ipairs( LocalPlayer():GetWeapons() ) do
                if wep:GetClass() == itemInfo.Name then
                    input.SelectWeapon(wep)
                    break
                end
            end
            self:CloseContext()
        end,
        function ()
            if not IsValid(LocalPlayer():GetActiveWeapon()) then
                return true
            end
            return LocalPlayer():GetActiveWeapon():GetClass() ~= itemInfo.Name
        end
    )
    end

    if itemInfo.ItemType == CASE_ITEM_GENERIC or itemInfo.ItemType == CASE_ITEM_GRENADE then
        panel:AddOption("Drop 1", function ()
            CaseInventory.ClientNet.DropItem(CaseGUI.Context.Item, 1, false)
            parent:Inv().Items[CaseGUI.Context.Item].Count = parent:Inv().Items[CaseGUI.Context.Item].Count - 1
            if parent:Inv().Items[CaseGUI.Context.Item].Count == 0 then
                parent:Inv().Items[CaseGUI.Context.Item] = nil
                CaseInventory:RefreshLoadout(self.Context.Parent:Inv())
                self:CloseContext()
            end


        end)
    end
    -- All items have this :)
    panel:AddOption("Drop", function ()
        CaseInventory.ClientNet.DropItem(CaseGUI.Context.Item, -1, false)
        parent:Inv().Items[CaseGUI.Context.Item] = nil

        CaseInventory:RefreshLoadout(self.Context.Parent:Inv())
        self:CloseContext()

    end)
end




local function _createWindow(name, inv, parent)
    local window = vgui.Create("DFrame")
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
    CaseGUI.InvTargets[name] = inventory

    return window
end
-- thank u chat gee pea tei
local function OpenBasicPanel()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local mwX, mwY = 0, 0 
    CaseGUI.MainWindow = _createWindow("MainWindow", CaseInv(LocalPlayer()), true)
    CaseGUI.MainWindow:Center()
    mwX, mwY = CaseGUI.MainWindow:GetPos()
    mwX = mwX - ((__CASE_UI_BORDER/1.5) * scaleW)

    -- Nobody will notice it's slightly off center yeah?
    -- **YOU** won't tell about this right?
    CaseGUI.MainWindow:SetPos(mwX , mwY)
    CaseGUI.SortingWindow = _createWindow("SortingWindow", CaseInventory:GenerateInventory(6, 8))

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
end

concommand.Add("case_open", OpenBasicPanel)