local PANEL = {}

function PANEL:Paint(w, h)
	local scaleW, scaleH = _CaseUIGetScaledDiff()

   
	CaseGUITheme:Draw("Inventory.ExitButton", 0, 0, w, h)

	local details = CaseGUITheme:GetDetails("Inventory.ExitButton")
	if details ~= nil and details.Draw then
		surface.SetDrawColor(CaseGUITheme:GetDetailColor("Inventory.ExitButton"))
		--surface.SetDrawColor(255, 0, 0)
		surface.DrawLine(3 * scaleW, 3 * scaleH, w - (3*scaleW), h - (3*scaleH))
		surface.DrawLine(3 * scaleW, h - (3*scaleH), w - (3*scaleW), 3 * scaleH)
	end
end


vgui.Register("CaseInvExitButton", PANEL, "DButton")