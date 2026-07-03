function CollisionResizer.HasValidPhysics( ent )
	return ent:GetSolid() == SOLID_VPHYSICS -- and ent:GetPhysicsObjectCount() == 1
end


function CollisionResizer.SupportsPhysicalData( ent )
	return CollisionResizer.IsValidEntity( ent ) and CollisionResizer.HasValidPhysics( ent ) and not ent:IsRagdoll()
end


function CollisionResizer.VecDivEW( dividend, divisor )
	return Vector(
		dividend.x / divisor.x,
		dividend.y / divisor.y,
		dividend.z / divisor.z
	)
end
