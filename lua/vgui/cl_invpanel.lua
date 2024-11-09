local invpanel = {}
invpanel.Player = nil
local ratio = 16/9

function invpanel:DrawGrid(w, h)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
    local baseX, baseY = __CASE_UI_BORDER * scaleW, __CASE_UI_BORDER * scaleH

    surface.SetDrawColor(Color(255, 255, 255, 20))

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

-- Some of this shamelessly stolen from 
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmodelpanel.lua
-- https://github.com/louiefox/tetris-inventory/blob/master/lua/vgui/tetris_inv_main.lua
function invpanel:DrawItem(itemID, gridX, gridY, gridW, gridH, rot, count)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
    local posX, posY = self:LocalToScreen(self:GetPos())
    local itemInfo = CaseInventory.ItemRegister[itemID]
    local renderInfo = itemInfo.RenderInfo
    local model = ClientsideModel(renderInfo.Model)
    local baseX, baseY = __CASE_UI_BORDER*scaleW, (__CASE_UI_BORDER*scaleH)
    local isRotated = rot % 2 == 0


    local _x, _y, _w, _h = 
        posX + (__CASE_UI_BORDER*scaleW) + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW),
        posY+ (__CASE_UI_BORDER*scaleH) + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH),
        __CASE_UI_CELL_SIZE * gridW * scaleW,
        __CASE_UI_CELL_SIZE * gridH * scaleH

    local _ogW, _ogH = _w, _h
    local _scale = renderInfo.Scale or gridW

    if isRotated then
        local tw = _w
        _w = _h
        _h = tw

    end


    surface.SetDrawColor(Color(25,25,25, 200))
    surface.DrawRect(
        baseX + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW) + (5 * scaleW),
        baseY + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH) + (5 * scaleH),
        _w - (7.5 * scaleW),
        _h - (7.5 * scaleH)
     )
     surface.SetDrawColor(Color(0,0,0, 255))


    if IsValid(model) then
        local min, max = model:GetRenderBounds()

        local function getOffset( val )
            return math.abs( min[val] )-(max[val]-min[val])/2
        end
        
        -- If the x width of the model is larger rotate it 90 degrees
        local xDiff, yDiff = max[1]-min[1], max[2]-min[2]

        if( xDiff > yDiff ) then
            model:SetPos( Vector( getOffset( 2 ), getOffset( 1 ), getOffset( 3 ) ) )
            model:SetAngles( Angle( 0, 90, 0 ) )
        else
            model:SetPos( Vector( getOffset( 1 ), getOffset( 2 ), getOffset( 3 ) ) )
            model:SetAngles( Angle( 0, 0, 90 ) )
        end

        --render.SetScissorRect( _x, _y, _x+_w, _y+_h, true ) -- Enable the rect

        local modelWidth = math.max( xDiff, yDiff )
        cam.Start({
            x=(_x - 1280/2) + _w/2,
            y=(_y - 720/2) + _h/2,
            w=1280,
            h=720,
            type="3D",
            angles = Angle(0, 0, 0),
            --angles= Angle(0, 0, -90),
            origin = Vector(-modelWidth*4/(_scale or 1), 0, 0 ),
            fov=70,
            aspect=ratio -- tee hee
        })
    


        model:DrawModel()
        model:Remove()
        cam.End3D()

        --render.SetScissorRect( 0, 0, 0, 0, false ) -- Disable after you are done
    end

    if (itemInfo.ItemType != CASE_ITEM_WEAPON) then
        draw.DrawText(tostring(count), "DermaDefault",
        baseX + (__CASE_UI_CELL_SIZE * (gridX+gridW-1) * scaleW) - (5 * scaleW),
        baseY + (__CASE_UI_CELL_SIZE * (gridY+gridH-1) * scaleH) - (10 * scaleH),
        Color(255, 255, 255),TEXT_ALIGN_RIGHT)
    end

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

    render.SuppressEngineLighting( true )
    for k, v in pairs(player.CaseInv.Items) do
        local info = CaseInventory.ItemRegister[v.ItemID]
        self:DrawItem(v.ItemID, v.X, v.Y, info.Size.W, info.Size.H, v.Rotation, v.Count)
    end
    render.SuppressEngineLighting( false )
end

vgui.Register("CaseInvPanel", invpanel, "DPanel")