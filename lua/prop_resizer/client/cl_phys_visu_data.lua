
CollisionResizer.entsPhysicalData = {}



-----------------
-- Visual Data --
-----------------

function CollisionResizer.CreateVisualData( ent )

	CollisionResizer.RemoveInvalidEntities( CollisionResizer.entsVisualData )

	local visualData = {
		Vector( 1, 1, 1 ),
		ent:GetRenderBounds()
	}

	CollisionResizer.entsVisualData[ent] = visualData

	return visualData

end


function CollisionResizer.ApplyVisualData( ent, visualData )

	local scaleVisu	= visualData[1]

	local matrix	= Matrix()
	matrix:Scale( scaleVisu )

	ent:EnableMatrix( "RenderMultiply", matrix )
	ent:SetRenderBounds( visualData[2] * scaleVisu, visualData[3] * scaleVisu )
	ent:DestroyShadow()
	ent:SetLOD( CollisionResizer.IsBigScale( scaleVisu ) and 0 or -1 )

end


function CollisionResizer.ResetVisualData( ent )

	local visualData = CollisionResizer.entsVisualData[ ent ]

	if not visualData then return end

	ent:DisableMatrix( "RenderMultiply" )
	ent:SetRenderBounds( visualData[2], visualData[3] )
	ent:DestroyShadow()
	ent:SetLOD( -1 )

	CollisionResizer.entsVisualData[ent] = nil

end


--[[
hook.Add( "EntityRemoved", "collision_resizer", function( ent )

	if ( CollisionResizer.entsVisualData[ ent ] ~= nil ) then CollisionResizer.entsVisualData[ ent ] = nil end

end )]]



-------------------
-- Physical Data --
-------------------

function CollisionResizer.CreatePhysicalData( ent, oBBMins, oBBMaxs )

	CollisionResizer.RemoveInvalidEntities( CollisionResizer.entsPhysicalData )

	local physicalData = {
		Vector( 1, 1, 1 ),
	}

	CollisionResizer.entsPhysicalData[ent] = physicalData

	return physicalData

end


function CollisionResizer.ApplyPhysicalData( ent, physicalData )

	if not CollisionResizer.ResizePhysics( ent, physicalData ) then return end

	CollisionResizer.RefreshPhysObj( ent )

end


function CollisionResizer.ResetPhysicalData( ent )

	if not CollisionResizer.entsPhysicalData[ent] then return end

	ent:PhysicsDestroy()

	CollisionResizer.entsPhysicalData[ent] = nil

end


--[[
hook.Add( "EntityRemoved", "collision_resizer_clientphysics", function( ent )

	CollisionResizer.entsPhysicalData[ ent ] = nil

end )]]