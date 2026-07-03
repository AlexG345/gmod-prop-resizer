function CollisionResizer.CreatePhysicalData( ent, phys )

	CollisionResizer.RemoveInvalidEntities( CollisionResizer.entsPhysicalData )

	local physicalData = {}

	physicalData = {
		Vector( 1, 1, 1 ),
		ent:GetCollisionBounds()
	}
	physicalData[4] = phys:GetMass()

	CollisionResizer.entsPhysicalData[ent] = physicalData

	return physicalData

end