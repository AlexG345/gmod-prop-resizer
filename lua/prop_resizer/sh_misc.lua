function CollisionResizer.IsValidEntity( ent )

	return isentity( ent ) and ent:IsValid()

end


function CollisionResizer.IsValidPhysicsObject( phys )

	return TypeID( phys ) == TYPE_PHYSOBJ and phys:IsValid()

end


function CollisionResizer.WasResized( ent )

	return CollisionResizer.IsValidEntity( ent.sizeHandler )

end


function CollisionResizer.RemoveInvalidEntities( tab )

	local validEntCount = 0

	for ent, _ in pairs( tab ) do
		if CollisionResizer.IsValidEntity( ent ) then
			validEntCount = validEntCount + 1
		else
			tab[ent] = nil
		end
	end

	return validEntCount

end