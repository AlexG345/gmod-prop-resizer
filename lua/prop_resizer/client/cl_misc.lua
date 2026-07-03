-------------
-- Helpers --
-------------

local function isValidModel( model )
	return isstring( model ) and util.IsValidModel( model )
end


function CollisionResizer.SupportsVisualData( ent )
	return CollisionResizer.IsValidEntity( ent ) and isValidModel( ent:GetModel() )
end


function CollisionResizer.SupportsPhysicalData( ent )
	return CollisionResizer.IsValidEntity( ent ) and not ent:IsRagdoll()
end


function CollisionResizer.IsBigScale( scale )
	return (scale.x >= 4 and (scale.y >= 4 or scale.z >= 4)) or (scale.y >= 4 and scale.z >= 4)
end


function CollisionResizer.RefreshPhysObj( ent )

	local phys = ent:GetPhysicsObject()

	if not CollisionResizer.IsValidPhysicsObject( phys ) then return end

	phys:SetPos( ent:GetPos() )
	phys:SetAngles( ent:GetAngles() )
	phys:EnableMotion( false )
	phys:Sleep()

end