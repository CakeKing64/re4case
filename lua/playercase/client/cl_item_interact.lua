hook.Add("PreDrawHalos", "CASE_PreDrawHalos", function()
    if IsValid(LocalPlayer():GetEyeTrace().Entity) then
        local ent = LocalPlayer():GetEyeTrace().Entity
        if ent:IsWeapon() then
            halo.Add({ent}, Color(0,255,0), 2, 2, 2)
        end
    end
end)