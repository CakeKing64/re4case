local casebutton = {
	FontSize = 30,
	Text = "",
	--[[
	TextColor = Color(255, 255, 255),
	ButtonColor = {
		Enabled = Color(80, 80, 75, 255),
		Hovered = Color(60, 60, 55, 255),
		Disabled = Color(30, 30, 27, 255)
	},
	]]
	Hover = false,
	OnClick = function ()
		
	end,
	Sound = "ui/re4case/context_open.wav",
	Name = "Button" -- For theming
}

function casebutton:Init()
	self:SetText("")
end

function casebutton:Think()
	if self:IsHovered() and not self.Hover then
		CaseGUI.PlaySound("ui/re4case/case_selection.wav")
	end

	self.Hover = self:IsHovered()
end

function casebutton:DoClick()
	if self.Sound ~= nil then
		CaseGUI.PlaySound(self.Sound)
	end

	self:OnClick()
end

function casebutton:Paint(w, h)
	if self:IsEnabled() then
		if not self:IsHovered() then
			CaseGUITheme:DrawFallback(self.Name .. ".Enabled", "Button.Enabled", 0, 0, w, h)
		else
			CaseGUITheme:DrawFallback(self.Name .. ".Hovered", "Button.Hovered", 0, 0, w, h)
		end
	else
		CaseGUITheme:DrawFallback(self.Name .. ".Disabled", "Button.Disabled", 0, 0, w, h)
	end

	local state = "Enabled"
	if self:IsEnabled() and not self:IsHovered() then
		state = "Enabled"
	elseif self:IsEnabled() and self:IsHovered() then
		state = "Hovered"
	else
		state = "Disabled"
	end

	local details = CaseGUITheme:GetDetailsFallback(self.Name .. "." .. state, "Button." .. state)
	if details and details.Draw then
		surface.SetDrawColor(CaseGUITheme:GetDetailColorFallback(self.Name .. "." .. state, "Button." .. state))
		local textW, textH = CaseInvBitmapTextSize(self.Text, self.FontSize)
		CaseInvBitmapTextDraw(self.Text, (w/2) - (textW / 2), (h/2) - (textH / 2), self.FontSize)
	end
end

function casebutton:SetString(text)
	self.Text = text
end

function casebutton:SetFontSize(size)
	self.FontSize = size
end

vgui.Register("CaseButton", casebutton, "DButton")