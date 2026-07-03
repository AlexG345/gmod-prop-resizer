local meta = FindMetaTable( "Entity" )

CollisionResizer.o_StartMotionController = meta.StartMotionController

function meta.StartMotionController(ent)

	-- TODO: this shit is broken and causes stack overflow without the line below
	if ent.IsMotionControlled then return end
	ent.IsMotionControlled = true
	CollisionResizer.o_StartMotionController( ent )

end

local o_StopMotionController = meta.StopMotionController

function meta.StopMotionController(ent)
	o_StopMotionController( ent )
	ent.IsMotionControlled = nil
end