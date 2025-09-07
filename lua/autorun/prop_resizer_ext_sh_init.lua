CollisionResizer = CollisionResizer or {}

CollisionResizer.ResizedEntities = {}


function CollisionResizer.IsValidEntity( ent )

	return isentity( ent ) and ent:IsValid()

end


function CollisionResizer.IsValidPhysicsObject( physobj )

	return TypeID( physobj ) == TYPE_PHYSOBJ and physobj:IsValid()

end


function CollisionResizer.WasResized( ent )

	return CollisionResizer.IsValidEntity( ent.SizeHandler )

end


function CollisionResizer.ResizePhysics( ent, scale )

	ent:PhysicsInit( SOLID_VPHYSICS )

	local physobj = ent:GetPhysicsObject()
	if not CollisionResizer.IsValidPhysicsObject( physobj ) then return false end

	local physmesh = physobj:GetMeshConvexes()
	if not istable( physmesh ) or #physmesh < 1 then return false end

	for _, convex in pairs( physmesh ) do

		for poskey, postab in pairs( convex ) do

			convex[poskey] = postab.pos * scale

		end

	end

	ent:PhysicsInitMultiConvex( physmesh )

	ent:EnableCustomCollisions( true )

	return CollisionResizer.IsValidPhysicsObject( ent:GetPhysicsObject() )

end