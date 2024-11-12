local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32
local function _setupcasegui()
    return {
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
        InvTargets = {

        }
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
    CaseGUI.MainWindow = _createWindow("MainWindow", LocalPlayer().CaseInv, true)
    CaseGUI.MainWindow:Center()
    mwX, mwY = CaseGUI.MainWindow:GetPos()
    mwX = mwX - ((__CASE_UI_BORDER/1.5) * scaleW)

    -- Nobody will notice it's slightly off center yeah?
    -- **YOU** won't tell about this right?
    CaseGUI.MainWindow:SetPos(mwX , mwY)
    CaseGUI.SortingWindow = _createWindow("SortingWindow", CaseInventory:GenerateInventory(6, 8))

    CaseGUI.SortingWindow:SetPos(mwX + CaseGUI.MainWindow:GetSize() + ((__CASE_UI_BORDER/2) * scaleW), mwY)
    CaseGUI.IsOpen = true

    -- Create a DButton (button)
    local button = vgui.Create("DButton", CaseGUI.MainWindow)
    button:SetText("Close")           -- Button text
    button:SetSize(100, 30)          -- Button size
    button:SetPos(100, 120)          -- Button position within the frame
    button.DoClick = function()      -- Function to run when clicked
        CaseGUI.SortingWindow:Close()
        CaseGUI.MainWindow:Close()                -- Closes the frame`
        CaseGUI.SortingWindow = nil
        CaseGUI.IsOpen = false
    end
end

-- Command to open the panel (type "openvgui" in console)
concommand.Add("openvgui", OpenBasicPanel)