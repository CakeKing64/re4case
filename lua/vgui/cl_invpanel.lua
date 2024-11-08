local invpanel = {}
invpanel.Player = nil
invpanel.RenderTarget = GetRenderTargetEx( "ExampleMaskRT", 512,512, RT_SIZE_OFFSCREEN,
MATERIAL_RT_DEPTH_SHARED --[[IMPORTANT]], 0, 0, IMAGE_FORMAT_RGBA8888 )

local ourMat = Material( "models/shadertest/shader5" )

function invpanel:DrawGrid(w, h)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
    local baseX, baseY = __CASE_UI_BORDER * scaleW, __CASE_UI_BORDER * scaleH

    surface.SetDrawColor(Color(255, 255, 255))

    -- Vert Lines
    for x = 0, player.CaseInv.Size[1] do
        surface.DrawLine(
            -- From
            baseX + __CASE_UI_CELL_SIZE * x * scaleW,
            baseY,
            -- To
            baseX + __CASE_UI_CELL_SIZE * x * scaleW,
            baseY + player.CaseInv.Size[2] * __CASE_UI_CELL_SIZE * scaleH
        )
    end

    -- Horiz Lines
    for y = 0, player.CaseInv.Size[2] do
        surface.DrawLine(
            -- From
            baseX,
            baseY + __CASE_UI_CELL_SIZE * y * scaleH,
            -- To
            baseX + player.CaseInv.Size[1] * __CASE_UI_CELL_SIZE * scaleW,
            baseY + __CASE_UI_CELL_SIZE * y * scaleH
        )
    end
end

function invpanel:DrawItem(itemID, gridX, gridY, gridW, gridH, rot)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
    local posX, posY = self:LocalToScreen(self:GetPos())

    local _x, _y, _w, _h = 
        posX + (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW),
        posY+ (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleW),
        __CASE_UI_CELL_SIZE * gridW * scaleW,
        __CASE_UI_CELL_SIZE * gridH * scaleH

    if rot % 2 == 0 then
        local tw = _w
        _w = _h
        _h = tw
    end

    cam.Start({
        x=_x,
        y=_y,
        w=_w,
        h=_h,
        type="3D",
        origin=Vector(-10,0,0),
        angles=Vector(0,0,0),
        fov=70
    })

    local model = ClientsideModel(itemID)
    if IsValid(model) then
        model:SetPos(Vector(0, 0, 0))
        model:SetAngles(Angle(0, RealTime() * 50 % 360, 0))
        model:DrawModel()
        model:Remove()
    end
    cam.End3D()
end

function invpanel:Init()
end

function invpanel:Paint(w, h)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
   

    surface.SetDrawColor(Color(42, 41, 37))
    surface.DrawRect(0, 0, w, h)
    self:DrawGrid(w, h)

    for k, v in pairs(player.CaseInv.Items) do
        local info = CaseInventory.ItemRegister[v.ItemID]
        self:DrawItem("models/props_interiors/BathTub01a.mdl", v.X, v.Y, info.Size.W, info.Size.H, v.Rotation)
    end
end

vgui.Register("CaseInvPanel", invpanel, "DPanel")