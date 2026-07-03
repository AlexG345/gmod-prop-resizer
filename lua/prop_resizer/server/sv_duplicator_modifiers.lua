local identifier = "advr"

duplicator.RegisterEntityModifier( identifier, function( ply, ent, data )

	local scalePhys				= Vector( unpack( data, 1, 3 ) )
	local scaleVisu				= Vector( unpack( data, 4, 6 ) )
	local disableClientPhysics	= data[7]
	local keepMass				= data[8]

	local resetPhys 	= ( scalePhys == vector_ones )
	local resetVisu 	= ( scaleVisu == vector_ones )

	if resetPhys and resetVisu then
		CollisionResizer.ClearDuplicatorData( ent )
		return
	end

	if not resetPhys then
		CollisionResizer.SetPhysicalScale( ent, scalePhys, true, disableClientPhysics, keepMass )
	end

	if not resetVisu then
		CollisionResizer.SetVisualScale( ent, scaleVisu )
	end

	-- local handler = GetSizeHandler( ent )
	-- handler:SetVisualScale( tostring( scaleVisu ) )

	-- if scalePhys == vector_ones or not CollisionResizer.HasValidPhysics( ent ) then return end

	-- local phys = ent:GetPhysicsObject()
	-- if not CollisionResizer.IsValidPhysicsObject( phys ) then return end

	-- local physicalData = CollisionResizer.CreatePhysicalData( ent, phys )
	-- physicalData[1]:Set( scalePhys )

	-- local physObjData = getPhysObjData( phys )

	-- local success = CollisionResizer.ResizePhysics( ent, physicalData )

	-- local disableClientPhysics	= data[7]
	-- local keepMass				= data[8]

	-- handler:SetPhysicalScale( tostring( disableClientPhysics and vector_ones or scalePhys ) )

	-- ent:SetCollisionBounds( physObjData[2] * scalePhys, physObjData[3] * scalePhys )

	-- if not success then return end

	-- phys = ent:GetPhysicsObject()

	-- if not keepMass then
	-- 	phys:SetMass( math.Clamp( physicalData[4] * scalePhys.x * scalePhys.y * scalePhys.z, 0.1, 50000 ) )
	-- end
	-- phys:SetDamping( 0, 0 )

	-- applyPhysObjData( phys, physObjData, keepMass )

	-- phys:Wake()

	-- if ent.IsMotionControlled then
	-- 	CollisionResizer.o_StartMotionController( ent )
	-- end

end )


function CollisionResizer.GetDuplicatorData( ent )

	return ent.EntityMods and ent.EntityMods[identifier]

end


-- You can omit fields
function CollisionResizer.SaveDuplicatorData( ent, scalePhys, scaleVisu, disableClientPhysics, keepMass )

	local px, py, pz, vx, vy, vz
	if scalePhys then px, py, pz = scalePhys:Unpack() end
	if scaleVisu then vx, vy, vz = scaleVisu:Unpack() end

	duplicator.StoreEntityModifier( ent, identifier, {
		px,
		py,
		pz,
		vx,
		vy,
		vz,
		disableClientPhysics,
		keepMass
	} )
end


function CollisionResizer.ClearDuplicatorData( ent )
	duplicator.ClearEntityModifier( ent, identifier )
end