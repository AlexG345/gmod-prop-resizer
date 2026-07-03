CollisionResizer = istable( CollisionResizer ) and CollisionResizer or {}

CollisionResizer.entsPhysicalData = {}
-- per ent:
-- 	physical scale (server, client)
-- 	collision bounds mins (server)
-- 	collision bounds maxs (server)
-- 	original mass (server)


local vector_ones = Vector( 1, 1, 1 )


local function resizePhysMesh( ent, phys, scalePhys )

	local physMesh		= phys:GetMeshConvexes()

	if ( not istable( physMesh ) or #physMesh < 1 ) then return false end

	for _, convex in pairs( physMesh ) do

		for posKey, posTab in pairs( convex ) do

			convex[posKey] = posTab.pos * scalePhys

		end

	end

	ent:PhysicsInitMultiConvex( physMesh )

end

-- NOTE: doing this twice or more on client with the same scale will change collision bounds permanently?
-- TODO: check if the above is true only if it's done at different frames
function CollisionResizer.ResizePhysics( ent, physicalData )

	local phys		= ent:GetPhysicsObject()
	local scalePhys = physicalData[1]

	local isSphere	= CollisionResizer.IsValidPhysicsObject( phys ) and phys:GetMeshConvexes() == nil
	local isReset	= scalePhys == vector_ones

	-- print("-- debug CollisionResizer.ResizePhysics --" )
	-- print( scalePhys, "|", physicalData[2], "|", physicalData[3] )
	-- print( "OBBSize before doing anything: ", ent:OBBMaxs() - ent:OBBMins() )

	-- TODO: this is all a bit messy, do we really need to init on server too or not?
	ent:PhysicsInit( SOLID_VPHYSICS )

	-- print( "OBBSize after physics init: ", ent:OBBMaxs() - ent:OBBMins() )

	phys = ent:GetPhysicsObject()
	if not CollisionResizer.IsValidPhysicsObject( phys ) then return false end

	-- print( "still going" )

	-- https://wiki.facepunch.com/gmod/PhysObj:GetMeshConvexes

	if not isSphere then

		if not isReset then
			resizePhysMesh( ent, phys, scalePhys )
		end

		-- print( "OBBSize after PhysicsInitMultiConvex: ", ent:OBBMaxs() - ent:OBBMins() )

		if SERVER then
			mins, maxs = physicalData[2], physicalData[3]
			if not isReset then
				mins = mins * scalePhys
				maxs = maxs * scalePhys
			end

			-- TODO: if used on a sphere it doesn't work properly?? this was back when it was used outside of this function,
			-- it caused large smartsnap grids with makeSpherical, idk at this point
			--
			-- If you don't use this clientside too, the ent's original collision bounds get different from server ones,
			-- though it's a 5% difference or so, idk what's the cause
			-- It was the case with models/props_c17/shelfunit01a.mdl at least.

			ent:SetCollisionBounds( mins, maxs )
		end

		ent:EnableCustomCollisions( not isReset )

		-- print( "OBBSize after set collision bounds: ", ent:OBBMaxs() - ent:OBBMins() )


	else

		--TODO: this kind of works BUT it also produces odd results clientside especially after duping

		local data = ent.EntityMods.MakeSphericalCollisions
		local originalRadius = data.noradius
		data.radius = originalRadius * ( ( scalePhys.x + scalePhys.y + scalePhys.z ) / 3 )

		-- print("TEST")
		-- local collisionBounds = ent:GetCollisionBounds() * scalePhys
		-- print( collisionBounds )
		-- local radius = collisionBounds.x
		-- ent:PhysicsInitSphere( radius )
		-- ent:SetCollisionBounds(
		-- 	Vector( -radius, -radius, -radius ),
		-- 	Vector( radius, radius, radius )
		-- )
		ent:PhysicsInit( SOLID_VPHYSICS )
		MakeSpherical.ApplySphericalCollisions( nil, ent, data )

	end

	phys = ent:GetPhysicsObject()
	return CollisionResizer.IsValidPhysicsObject( phys ) and phys

end



-----------------
-- File system --
-----------------

local function AddFile( dirPath, fileName )

	local fileSide	= string.lower( string.Left( fileName, 3 ) )
	local filePath	= dirPath .. fileName

	local isForBoth		= fileSide == "sh_"
	local isForServer	= isForBoth or fileSide == "sv_"
	local isForClient	= isForBoth or fileSide == "cl_"

	if ( SERVER and isForServer ) or ( CLIENT and isForClient ) then
		include( filePath )
	end

	if SERVER and isForClient then
		AddCSLuaFile( filePath )
	end

end


local function AddDir( dirPath )

	dirPath = dirPath .. "/"
	local files, dirs = file.Find( dirPath .. "*", "LUA")

	for _, fileName in ipairs( files ) do
		if string.EndsWith( fileName, ".lua" ) then
			AddFile( dirPath, fileName )
		end
	end

	for _, dirName in ipairs( dirs ) do
		AddDir( dirPath .. dirName )
	end

end


AddDir( "prop_resizer" )