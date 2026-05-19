CaseCraftGUI = {
    Window = nil,
    Panel = nil,
    Icons = {}

}


local cvar_prefer_sprites = CreateClientConVar("case_cl_prefer_sprites", "0", true, false, "Try to use sprites always", 0, 2)

function CaseCraftGUI:OpenCrafting(itemID)
    if itemID == nil then
        itemID = -1
    end

    if self:IsOpen() then
        self:Close()
        return
    end
    self.Window = vgui.Create("CaseCraftPanel")
    self.Window:Filter(itemID)
end

function CaseCraftGUI:Close()
    self.Window:Remove()
end

function CaseCraftGUI:IsOpen()
    return IsValid(self.Window)
end

function CaseCraftGUI:GenerateIcon(itemID)
    local info = CaseInventory:GetItemInfo(itemID)
    if info == nil then
        return nil
    end

    local iconSizeW = 256
    local iconSizeH = 256

    local icon = {
        Texture = GetRenderTarget(string.format("caseicon_%s", info.Name), iconSizeW, iconSizeH),
        Material = nil
    }

    render.PushRenderTarget(icon.Texture)
        render.Clear(80, 80, 75, 255, true, true)
        if info.RenderInfo.UseSprite or cvar_prefer_sprites:GetInt() >= 1 then
            cam.Start2D()
                CaseGUI:DrawSprite(itemID, 0, 0, iconSizeW, iconSizeH, false)
            cam.End2D()
        else
            CaseGUI:DrawModel(itemID, 0, 0, iconSizeW, iconSizeH, false)
        end
    render.PopRenderTarget()

    icon.Material = CreateMaterial(string.format("caseicon_%s_material", info.Name), "UnlitGeneric", {
        ["$basetexture"] = icon.Texture:GetName()
    })
    

    return icon
end

function CaseCraftGUI:GetIcon(itemID)
    if self.Icons[itemID] == nil then
        local icon = CaseCraftGUI:GenerateIcon(itemID)
        if icon == nil then
            return nil
        end

        self.Icons[itemID] = icon
        return icon
    end

    return self.Icons[itemID]
end

concommand.Add("case_crafting_open", function ()
    CaseCraftGUI:OpenCrafting()
end)