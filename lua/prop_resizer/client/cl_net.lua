-----------------
-- Visual Data --
-----------------

net.Receive( "collision_resizer_set_visual_scale", function()

	local ent		= net.ReadEntity()
	local scaleVisu	= net.ReadString()

	if not CollisionResizer.SupportsVisualData( ent ) then return end

	local visualData = CollisionResizer.entsVisualData[ent] or CollisionResizer.CreateVisualData( ent )

	visualData[1]:Set( Vector( scaleVisu ) )

	CollisionResizer.ApplyVisualData( ent, visualData )

end )


net.Receive( "collision_resizer_reset_visual_scale", function()

	local ent = net.ReadEntity()

	if CollisionResizer.SupportsVisualData( ent ) then
		CollisionResizer.ResetVisualData( ent )
	end

end )



-------------------
-- Physical Data --
-------------------

net.Receive( "collision_resizer_set_physical_scale", function()

	local ent		= net.ReadEntity()
	local scalePhys	= net.ReadString()

	if not CollisionResizer.SupportsPhysicalData( ent ) then return end

	scalePhys = Vector( scalePhys )

	local physicalData = CollisionResizer.entsPhysicalData[ent] or CollisionResizer.CreatePhysicalData( ent )

	if physicalData[1] == scalePhys then print("\n\n early stop \n\n") return end

	physicalData[1]:Set( scalePhys )

	CollisionResizer.ApplyPhysicalData( ent, physicalData )

end )


net.Receive( "collision_resizer_reset_physical_scale", function()

	local ent = net.ReadEntity()

	if CollisionResizer.SupportsPhysicalData( ent ) then
		CollisionResizer.ResetPhysicalData( ent )
	end

end )