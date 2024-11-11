local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32
local function _setupcasegui()
    return {
        TempLoadout = {},
        HeldItem = {
            InvID=-1,
            Rotation=0,
            OldInfo={} -- Store info to reset the pos & rot of an item
        },
        SortingWindow = nil,
        MainWindow = nil,
        ModifiedItems={},
        IsOpen = false,
        SyncRequest = false
    }
end
CaseGUI = _setupcasegui()

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


local function _createWindow(inv, parent)
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

    return window
end
-- thank u chat gee pea tei
local function OpenBasicPanel()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    CaseGUI.MainWindow = _createWindow(LocalPlayer().CaseInv, true)
    CaseGUI.MainWindow:Center()
    
    CaseGUI.SortingWindow = _createWindow(CaseInventory:GenerateInventory(6, 8))
    local x, y =  CaseGUI.MainWindow:GetPos()
    --local w, h = CaseGUI.MainWindow:GetSize()
    x = x + CaseGUI.MainWindow:GetSize() + (__CASE_UI_BORDER * scaleW)

    CaseGUI.SortingWindow:SetPos(x, y)
    CaseGUI.IsOpen = false

    -- Create a DButton (button)
    local button = vgui.Create("DButton", CaseGUI.MainWindow)
    button:SetText("Close")           -- Button text
    button:SetSize(100, 30)          -- Button size
    button:SetPos(100, 120)          -- Button position within the frame
    button.DoClick = function()      -- Function to run when clicked
        CaseGUI.SortingWindow:Close()
        CaseGUI.MainWindow:Close()                -- Closes the frame`
        CaseGUI.SortingWindow = nil
    end
end

-- Command to open the panel (type "openvgui" in console)
concommand.Add("openvgui", OpenBasicPanel)