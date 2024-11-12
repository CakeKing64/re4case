AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Case Upgrade (Base/Custom)"
ENT.Author = "CakeKing64"
ENT.Category = "Test entities"
ENT.Contact = "CakeKing64"
ENT.Purpose = "To test the creation of entities."
ENT.Spawnable = true

ENT.Model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
ENT.CaseSize = {
    1, 1
}


function ENT:Initialize()
    if SERVER then
        self:SetModel( self.Model )
	    self:PhysicsInit( SOLID_VPHYSICS )
	    self:SetMoveType( MOVETYPE_VPHYSICS )
	    self:SetSolid( SOLID_VPHYSICS )
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

	    local phys = self:GetPhysicsObject() 
	    if phys:IsValid() then
	        phys:Wake()
	    end
    end
end

function ENT:Use(activator)
    if activator:IsPlayer() then
        if self.CaseSize[1] > activator.CaseInv.Size[1] or self.CaseSize[2] > activator.CaseInv.Size[2] then
            activator.CaseInv.Size[1] = math.max(self.CaseSize[1], activator.CaseInv.Size[1])
            activator.CaseInv.Size[2] = math.max(self.CaseSize[2], activator.CaseInv.Size[2])
            CaseInventory:Sync(activator)
            self:Remove()
        end
    end
end

hook.Add("PopulateToolMenu", "AddMyEntityVariants", function()
    spawnmenu.AddToolMenuOption("Entities", "Custom Entities", "MyEntityExplosive", "Explosive Variant", "", "", function(panel)
        panel:Button("Spawn Explosive Variant", "gmod_tool", "my_entity", { variant = "explosive" })
    end)

    spawnmenu.AddToolMenuOption("Entities", "Custom Entities", "MyEntityRadioactive", "Radioactive Variant", "", "", function(panel)
        panel:Button("Spawn Radioactive Variant", "gmod_tool", "my_entity", { variant = "radioactive" })
    end)
end)