local ogWidth, ogHeight = 1920, 1080 -- not my screen size, hopefully that makes it better for testing????
__CASE_UI_CELL_SIZE = 64 -- #define
__CASE_UI_BORDER = 32
CaseGUI = {
    TempLoadout = {},
    HeldItem = {    
        InvID=-1,
        Rotation=0
    }
}

local function _setupcasegui()
    return {
        TempLoadout = {},
        HeldItem = {    
            InvID=-1,
            Rotation=0,
            OldInfo={} -- Store info to reset the pos & rot of an item
        },
        ModifiedItems={}
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

local PANEL = {}

function PANEL:OnRemove()
    CaseGUI = _setupcasegui()
end

vgui.Register("CaseInvFrame", PANEL, "DFrame")

-- thank u chat gee pea tei
local function OpenBasicPanel()
    local xxy = CaseInventory:DebugPrintLoadout(LocalPlayer())
    local window = vgui.Create("CaseInvFrame")
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()

    window:SetSize(
        (player.CaseInv.Size[3] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
        (player.CaseInv.Size[4] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
    )

    window:Center()
    window:MakePopup()
    --window:ShowCloseButton(false)
    window:SetDraggable(false)
    window:SetBackgroundBlur(true)

    local inventory = vgui.Create("CaseInvPanel", window)
    inventory:SetSize(
        (player.CaseInv.Size[3] * __CASE_UI_CELL_SIZE * scaleW) + (__CASE_UI_BORDER * 2 * scaleW),
        (player.CaseInv.Size[4] * __CASE_UI_CELL_SIZE * scaleH) + (__CASE_UI_BORDER * 2 * scaleH)
    )
    inventory.SlotRect = {
        1, 1,
        player.CaseInv.Size[3], player.CaseInv.Size[4]
    }
    inventory.Player = player


    -- Create a DButton (button)
    local button = vgui.Create("DButton", window)
    button:SetText("Close")           -- Button text
    button:SetSize(100, 30)          -- Button size
    button:SetPos(100, 120)          -- Button position within the frame
    button.DoClick = function()      -- Function to run when clicked
        window:Close()                -- Closes the frame
    end
end

-- Command to open the panel (type "openvgui" in console)
concommand.Add("openvgui", OpenBasicPanel)