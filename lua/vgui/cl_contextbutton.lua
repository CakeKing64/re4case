local PANEL = {}
PANEL.Text = "bringus"
PANEL.Disabled = false

function PANEL:Init()
    self:SetText("")
end

function PANEL:Paint(w, h)
    if self:IsEnabled() then
        surface.SetDrawColor(60, 60, 55, 255)
    else
        surface.SetDrawColor(30, 30, 27, 255)
    end
    surface.DrawRect( 0, 0, w, h)

    if self:IsEnabled() then
        surface.SetDrawColor(255,255,255, 255)
    else
        surface.SetDrawColor(110, 110, 105, 255)
    end
    CaseInvBitmapTextDraw(self.Text, 0, 0, 35)
end

vgui.Register("CaseInvContextButton", PANEL, "DButton")