local PANEL = {}
PANEL.Text = "bringus"
PANEL.Disabled = false
PANEL.Hover = false
PANEL.Sound = "ui/re4case/context_open.wav"
PANEL.OnClick = nil

function PANEL:Init()
	self:SetText("")
end

function PANEL:Think()
	if self:IsHovered() and not self.Hover then
		CaseGUI.PlaySound("ui/re4case/case_selection.wav")
	end

	self.Hover = self:IsHovered()
end

function PANEL:DoClick()
	CaseGUI.PlaySound(self.Sound)
	local info = CaseGUI:GenerateInfo()
	if info == nil then
		return
	end

	self.OnClick(info)
end

function PANEL:Paint(w, h)
	if self:IsEnabled() then
		if not self:IsHovered() then
			CaseGUITheme:Draw("Inventory.ContextButton", 0, 0, w, h)
		else
			CaseGUITheme:Draw("Inventory.ContextButtonHovered", 0, 0, w, h)
		end
	else
		CaseGUITheme:Draw("Inventory.ContextButtonDisabled", 0, 0, w, h)
	end


	local color = Color(255, 255, 255)
	if self:IsEnabled() then
		if not self:IsHovered() then
			surface.SetDrawColor(CaseGUITheme:GetDetailColor("Inventory.ContextButton"))
		else
			surface.SetDrawColor(CaseGUITheme:GetDetailColor("Inventory.ContextButtonHovered"))
		end
	else
		surface.SetDrawColor(CaseGUITheme:GetDetailColor("Inventory.ContextButtonDisabled"))
	end

	CaseInvBitmapTextDraw(self.Text, 0, 0, 35)
end

vgui.Register("CaseInvContextButton", PANEL, "DButton")