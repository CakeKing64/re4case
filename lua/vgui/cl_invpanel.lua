local invpanel = {}
invpanel.Player = nil
invpanel.SlotRect = {
    0, 0, 255, 255
}


local itemColors = {
    Color(250, 61, 61, 255), -- Empty **SHOULD** only be visible on guns >:(
    Color(247, 237, 227, 255), -- Somewhere inbetween
    Color(99, 199, 99, 255) -- Full/Max count
}

local ratio = 16/9

function invpanel:SlotX()
    return self.SlotRect[1]
end

function invpanel:SlotY()
    return self.SlotRect[2]
end

function invpanel:SlotW()
    return self.SlotRect[3] - (self.SlotRect[1]-1)
end

function invpanel:SlotH()
    return self.SlotRect[4] - (self.SlotRect[2]-1)
end

function invpanel:GetMouseSlot()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local posX, posY = self:LocalToScreen(self:GetPos())
    local relX, relY = gui.MouseX() - posX, gui.MouseY() - posY

    if relX < __CASE_UI_BORDER*scaleW or relY < __CASE_UI_BORDER*scaleH then
        return nil, nil
    end
    

    return math.floor((relX - __CASE_UI_BORDER*scaleW) / (__CASE_UI_CELL_SIZE * scaleW)) + 1,
            math.floor((relY - __CASE_UI_BORDER*scaleH) / (__CASE_UI_CELL_SIZE * scaleH)) + 1
end

function invpanel:GetMouseItem()
    local slotX, slotY = self:GetMouseSlot()

    if slotX == nil or slotY == nil then
        return 0
    end

    if slotX < self.SlotRect[1] or slotX > self.SlotRect[1] + self.SlotRect[3] or 
        slotY < self.SlotRect[2] or slotY > self.SlotRect[2] + self.SlotRect[4] then
            return 0
    end

    return self.Player.CaseInv.Loadout[slotX][slotY]
end

function invpanel:DrawGrid(w, h)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local player = LocalPlayer()
    local baseX, baseY = __CASE_UI_BORDER * scaleW, __CASE_UI_BORDER * scaleH

    surface.SetDrawColor(Color(255, 255, 255, 20))
    local _x, _y = 0, 0

    -- Vert Lines
    for x = self:SlotX()-1, self:SlotW() do
        surface.DrawLine(
            -- From
            baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
            baseY,
            -- To
            baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
            baseY + self:SlotH() * __CASE_UI_CELL_SIZE * scaleH
        )
        _x = _x + 1
    end

    -- Horiz Lines
    for y = self:SlotY()-1, self:SlotH() do
        surface.DrawLine(
            -- From
            baseX,
            baseY + __CASE_UI_CELL_SIZE * _y * scaleH,
            -- To
            baseX + self:SlotW() * __CASE_UI_CELL_SIZE * scaleW,
            baseY + __CASE_UI_CELL_SIZE * _y * scaleH
        )
        _y = _y + 1
    end
end

-- Some of this shamelessly stolen from 
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmodelpanel.lua
-- https://github.com/louiefox/tetris-inventory/blob/master/lua/vgui/tetris_inv_main.lua
function invpanel:DrawItem(itemID, invId, gridX, gridY, gridW, gridH, rot, count )
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



    if invId == CaseGUI.HeldItem.InvID then
        surface.SetDrawColor(Color(128, 128, 128, 128))
    elseif CaseGUI.HeldItem.InvID == -1 and invId == self:GetMouseItem() then
        surface.SetDrawColor(Color(128, 128, 128, 128))
    else
        surface.SetDrawColor(Color(25,25,25, 200))
    end

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
        
        --[[ Gotta remind myself :)
        X -> Forward/Back
        Y -> Left/Right
        Z -> Up/Down
        ]]--

        -- If the x width of the model is larger rotate it 90 degrees
        local xDiff, yDiff = max[1]-min[1], max[2]-min[2]
        local _renderRotate = isRotated
        if renderInfo.Rotate then
            _renderRotate = not _renderRotate
        end
        -- Yandare dev ass code
        if not _renderRotate then
            if( xDiff > yDiff ) then
                model:SetPos( Vector( getOffset( 2 ), getOffset( 1 ), getOffset( 3 ) ) )
                model:SetAngles( Angle( 0, 90, 0 ) )
            else
                model:SetPos( Vector( getOffset( 1 ), getOffset( 2 ), getOffset( 3 ) ) )
                model:SetAngles( Angle( 0, 0, 0 ) )
            end
        else
            if( xDiff > yDiff ) then
                model:SetPos( Vector( getOffset( 2 ), getOffset( 3 ),  -getOffset( 1 )) )
                model:SetAngles( Angle( 90, 90, 0 ) )
            else
                model:SetPos( Vector(getOffset( 1 ), -getOffset( 3 ), getOffset( 2 )))
                model:SetAngles( Angle( 0, 0, 90 ) )
            end
        end



        
        render.SetScissorRect( _x, _y, _x+_w, _y+_h, true )

        local modelWidth = math.max( xDiff, yDiff )
        cam.Start({
            x=(_x - 1280/2) + _w/2,
            y=(_y - 720/2) + _h/2,
            w=1280,
            h=720,
            type="3D",
            angles = Angle(0, 0, 0),
            origin = Vector(-modelWidth*4/(_scale or 1), 0, 0 ),
            fov=70,
            aspect=ratio -- tee hee
        })
    


        model:DrawModel()
        model:Remove()
        cam.End3D()

        render.SetScissorRect( 0, 0, 0, 0, false )
    end
    
    -- Draw either item count or ammo loaded into the weapon
    local _count = 0
    local _countStatus = 0 -- 1 == Empty, 2 = Neither empty or full, 3 = Full, 4 = Don't draw count

    if itemInfo.ItemType == CASE_ITEM_WEAPON then
        local wpn = player:GetWeapon(itemInfo.Name)
        if not IsValid(wpn) then
            _count = 0
        else
            -- If the only ammo is stored in the secondary clip use that instead
            local _maxClip = wpn:GetMaxClip1()
            _count = wpn:Clip1()
            if wpn:GetMaxClip1() <= 0 and wpn:GetMaxClip2() > 0 then
                _maxClip = wpn:GetMaxClip2()
                _count = wpn:Clip2()
            end

            if _count <= 0 then -- Melee weapon or something gravgun like?
                _countStatus = 4
            elseif _count == _maxClip then
                _countStatus = 3
            elseif _count > 0 then
                _countStatus = 2
            else
                _countStatus = 1
            end
        end
    else
        if itemInfo.MaxCount == 1 then
            _countStatus = 4
        elseif count == itemInfo.MaxCount then
            _countStatus = 3
        elseif count > 0 then
            _countStatus = 2
        else
            _countStatus = 1
        end

        _count = count 
    end

    if _countStatus != 4 then
    draw.DrawText(tostring(_count), "Trebuchet24",
        baseX + (__CASE_UI_CELL_SIZE * (gridX-1) * scaleW) + _w - (7 * scaleW),
        baseY + (__CASE_UI_CELL_SIZE * (gridY-1) * scaleH) + _h - (20 * scaleH),
       itemColors[_countStatus],TEXT_ALIGN_RIGHT)
    end


end

function invpanel:Init()
end

function invpanel:OnRemove()
    
end

function invpanel:OnMousePressed(keyCode)


    if CaseGUI.HeldItem.InvID != -1 then
        if keyCode == MOUSE_LEFT then
            local msX, msY = self:GetMouseSlot()
            if CaseInventory:MoveItem(LocalPlayer(), CaseGUI.HeldItem.InvID, msX, msY, 1) then
                print(":)")
            end
        end

        if keyCode == MOUSE_RIGHT then -- Reset item location
            self.Player.CaseInv.Items[CaseGUI.HeldItem.InvID] = CaseGUI.HeldItem.OldInfo
            CaseGUI.HeldItem.InvID = -1
        end
    end

    
    if CaseGUI.HeldItem.InvID == -1 then
        if keyCode == MOUSE_LEFT then
            local itm = self:GetMouseItem()
            if itm != 0 then
                CaseGUI.HeldItem.InvID = itm
                CaseGUI.HeldItem.OldInfo = self.Player.CaseInv.Items[CaseGUI.HeldItem.InvID]
            end
        end

    end



end

function invpanel:Think()
    
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
        local held = (k == CaseGUI.HeldItem.InvID)

        if held then -- Draw at mouse position if held :)
            continue -- draw later so it can be over the top of everything
        else
            self:DrawItem(v.ItemID, k, v.X, v.Y, info.Size.W, info.Size.H, v.Rotation, v.Count)
        end
    end

    if CaseGUI.HeldItem.InvID != -1 then
        local v = player.CaseInv.Items[CaseGUI.HeldItem.InvID]
        local info = CaseInventory.ItemRegister[v.ItemID]
        local mx, my = self:GetMouseSlot()
        self:DrawItem(v.ItemID, CaseGUI.HeldItem.InvID, mx or v.X, my or v.Y, info.Size.W, info.Size.H, v.Rotation, v.Count)
    end
    render.SuppressEngineLighting( false )


end



vgui.Register("CaseInvPanel", invpanel, "DPanel")