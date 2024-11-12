local invpanel = {}
invpanel.InvTarget = nil

AccessorFunc(invpanel, "bHasItems", "HasItems")

local itemColors = {
    Color(250, 61, 61, 255), -- Empty **SHOULD** only be visible on guns >:(
    Color(247, 237, 227, 255), -- Somewhere inbetween
    Color(99, 199, 99, 255) -- Full/Max count
}

local ratio = 16/9

function invpanel:InvW()
    return self:Inv().Size[1]
end

function invpanel:InvH()
    return self:Inv().Size[2]
end

function invpanel:Inv()
    if self.InvTarget.Player ~= nil then
        return self.InvTarget.Player.CaseInv
    end
    return self.InvTarget
end

---@param clamp? boolean Instead of returning nil, clamp to the last grid index
---@return integer?
---@return integer?
function invpanel:GetMouseSlot(clamp)
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local posX, posY = self:LocalToScreen(self:GetPos())
    local relX, relY = gui.MouseX() - posX, gui.MouseY() - posY
    local gridX, gridY = math.floor((relX - __CASE_UI_BORDER*scaleW) / (__CASE_UI_CELL_SIZE * scaleW)) + 1,
        math.floor((relY - __CASE_UI_BORDER*scaleH) / (__CASE_UI_CELL_SIZE * scaleH)) + 1


    if not clamp and 
        (gridX < 1 or gridX > self:InvW() or gridY < 0 or gridY > self:InvH()) then
        return nil, nil
    end
    
    -- Return clamped
    return math.Clamp(gridX, 1, self:InvW()),
            math.Clamp(gridY, 1, self:InvH())
end

function invpanel:GetMouseItem()
    local slotX, slotY = self:GetMouseSlot()

    if slotX == nil or slotY == nil then
        return 0
    end

    if slotX < 1 or slotX > self:InvW() or 
        slotY < 1 or slotY > self:InvH() then
            return 0
    end

    return self:Inv().Loadout[slotX][slotY]
end

function invpanel:DrawGrid(w, h)
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    local baseX, baseY = __CASE_UI_BORDER * scaleW, __CASE_UI_BORDER * scaleH

    surface.SetDrawColor(Color(255, 255, 255, 20))
    local _x, _y = 0, 0

    -- Vert Lines
    for x = 0, self:InvW() do
        surface.DrawLine(
            -- From
            baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
            baseY,
            -- To
            baseX + __CASE_UI_CELL_SIZE * _x * scaleW,
            baseY + self:InvH() * __CASE_UI_CELL_SIZE * scaleH
        )
        _x = _x + 1
    end

    -- Horiz Lines
    for y = 0, self:InvH() do
        surface.DrawLine(
            -- From
            baseX,
            baseY + __CASE_UI_CELL_SIZE * _y * scaleH,
            -- To
            baseX + self:InvW() * __CASE_UI_CELL_SIZE * scaleW,
            baseY + __CASE_UI_CELL_SIZE * _y * scaleH
        )
        _y = _y + 1
    end
end

--- Some of this shamelessly stolen from<br>
--- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dmodelpanel.lua
--- https://github.com/louiefox/tetris-inventory/blob/master/lua/vgui/tetris_inv_main.lua
---@param itemID integer
---@param invId integer
---@param gridX integer
---@param gridY integer griddy heh
---@param gridW integer
---@param gridH integer
---@param isRotated boolean
---@param count integer
function invpanel:DrawItem(itemID, invId, gridX, gridY, gridW, gridH, isRotated, count )
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
    --local player = LocalPlayer()
    local posX, posY = self:LocalToScreen(self:GetPos())
    local itemInfo = CaseInventory.ItemRegister[itemID]
    local renderInfo = itemInfo.RenderInfo
    local model = ClientsideModel(renderInfo.Model)
    local baseX, baseY = __CASE_UI_BORDER*scaleW, (__CASE_UI_BORDER*scaleH)


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



    if invId == CaseGUI.HeldItem.InvID and CaseGUI.HeldItem.SourceWindow == self then
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
            if( xDiff > yDiff or renderInfo.ForceRot == 2) then
                model:SetPos( Vector( getOffset( 2 ), getOffset( 1 ), getOffset( 3 ) ) )
                model:SetAngles( Angle( 0, 90, 0 ) )
            else
                model:SetPos( Vector( getOffset( 1 ), getOffset( 2 ), getOffset( 3 ) ) )
                model:SetAngles( Angle( 0, 0, 0 ) )
            end
        else
            if( xDiff > yDiff or renderInfo.ForceRot == 2) then
                model:SetPos( Vector( getOffset( 2 ), getOffset( 3 ),  -getOffset( 1 )) )
                model:SetAngles( Angle( 90, 90, 0 ) )
            else
                model:SetPos( Vector(getOffset( 1 ), -getOffset( 3 ), getOffset( 2 )))
                model:SetAngles( Angle( 0, 0, 90 ) )
            end
        end



        
        render.SetScissorRect( _x, _y, _x+_w, _y+_h, true )
        local modelWidth = 0
        if renderInfo.ForceRot == 0 then
            modelWidth = math.max( xDiff, yDiff )
        elseif renderInfo.ForceRot == 0 then
            modelWidth = yDiff
        else
            modelWidth = xDiff
        end
        
        cam.Start({
            x=(_x - ScrW()/2) + _w/2,
            y=(_y - ScrH()/2) + _h/2,
            w=ScrW(),
            h=ScrH(),
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

    if IsValid(self:Inv().Player) and itemInfo.ItemType == CASE_ITEM_WEAPON then
        local player = self:Inv().Player
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

            if _maxClip <= 0 then -- Melee weapon or something gravgun like?
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

    if _countStatus ~= 4 then
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

    -- An item is held
    if CaseGUI.HeldItem.InvID ~= -1 then
        if keyCode == MOUSE_LEFT then
            local mx, my = self:GetMouseSlot()
            if mx then
                if CaseInventory:MoveItem(
                    CaseGUI.HeldItem.SourceWindow:Inv(),
                    CaseGUI.HeldItem.InvID,
                    self:Inv(),
                    CaseGUI.HeldItem.X,
                    CaseGUI.HeldItem.Y,
                    CaseGUI.HeldItem.Rotated
                ) then
                    CaseGUI.HeldItem.InvID = -1
                    return
                end
            end
        end
    end

    -- No item is held
    if CaseGUI.HeldItem.InvID == -1 then
        if keyCode == MOUSE_LEFT then
            local itm = self:GetMouseItem()
            if itm ~= 0 then
                CaseGUI.HeldItem.SourceWindow = self
                CaseGUI.HeldItem.InvID = itm
                CaseGUI.HeldItem.OldInfo = self:Inv().Items[CaseGUI.HeldItem.InvID]
                CaseGUI.HeldItem.Rotated = self:Inv().Items[CaseGUI.HeldItem.InvID].Rotated
            end
        end

    end



end

function invpanel:Think()
    if self:GetMouseSlot() ~= nil then
        CaseGUI.HoveredWindow = self
    end
    
    self.bHasItems = false
    for k, v in pairs(self:Inv().Items) do
        if v ~= nil then
            self.bHasItems = true
            break
        end
    end
end

function invpanel:Paint(w, h)
    local screenW, screenH = _CaseUIGetScaledSize()
    local scaleW, scaleH = _CaseUIGetScaledDiff()
   

    surface.SetDrawColor(Color(42, 41, 37))
    surface.DrawRect(0, 0, w, h)
    self:DrawGrid(w, h)

    render.SuppressEngineLighting( true )
    for k, v in pairs(self:Inv().Items) do
        local info = CaseInventory.ItemRegister[v.ItemID]
        local held = (k == CaseGUI.HeldItem.InvID and self == CaseGUI.HeldItem.SourceWindow)

        if held then -- Draw at mouse position if held :)
            continue -- draw later so it can be over the top of everything
        else
            self:DrawItem(v.ItemID, k, v.X, v.Y, info.Size.W, info.Size.H, v.Rotated, v.Count)
        end
    end


    if CaseGUI.HeldItem.InvID ~= -1 and CaseGUI.HoveredWindow == self then
        local v = CaseGUI.HeldItem.SourceWindow:Inv().Items[CaseGUI.HeldItem.InvID]
        local info = CaseInventory.ItemRegister[v.ItemID]
        local mx, my = self:GetMouseSlot(true)
        local itemW, itemH = info.Size.W, info.Size.H

        if itemW > self:Inv().Size[1] then -- If the item doesn't fit horiz force rotate it
            CaseGUI.HeldItem.Rotated = true
        end

        if CaseGUI.HeldItem.Rotated then
            local _w = itemW
            itemW = itemH
            itemH = _w
        end
        
        local offsetX, offsetY = 
                math.Clamp(math.floor(itemW / 2), 0,  math.max(0, itemW-1)),
                math.Clamp(math.floor(itemH / 2), 0, math.max(0, itemH-1))

        if offsetX > 1 then
            mx = mx - offsetX
        end

        if offsetY > 1 then
            my = my - offsetY
        end
        
        mx = math.Clamp(mx, 1, self:InvW()+1 - itemW)
        my = math.Clamp(my, 1, self:InvH()+1 - itemH)

        CaseGUI.HeldItem.X = mx or v.X
        CaseGUI.HeldItem.Y = my or v.Y

        if mx and my then -- Don't draw if model would be out of the grid
            self:DrawItem(v.ItemID, CaseGUI.HeldItem.InvID, mx or v.X, my or v.Y, info.Size.W, info.Size.H, CaseGUI.HeldItem.Rotated, v.Count)
        end
    end


    render.SuppressEngineLighting( false )


end



vgui.Register("CaseInvPanel", invpanel, "DPanel")