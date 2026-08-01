util.AddNetworkString( "collision_resizer_set_physical_scale" )
util.AddNetworkString( "collision_resizer_reset_physical_scale" )

util.AddNetworkString( "collision_resizer_set_visual_scale" )
util.AddNetworkString( "collision_resizer_reset_visual_scale" )


local vector_ones = Vector( 1, 1, 1 )



------------------------------------------------
--            Constraint Functions            --
------------------------------------------------


-- TODO: this is BROKEN, it stretches axises, doesn't delete constraints etc
-- TODO: FIX RIGHT NOW, most URGENT thing to DO!!
local function getAndResizeConstraintVals( ent, constr, constrType, relativeScalePhys )

	local doResize	= isvector( relativeScalePhys ) and relativeScalePhys ~= vector_ones
	local LPos		= doResize and {} or nil

	-- TODO: this doesn't always work
	if doResize and ent == constr.Ent1 then

		if isvector( constr.LocalAxis ) then
			LPos["LocalAxis"] = true
		end

		-- BuildDupeInfo is from Advanced Duplicator 2
		if istable( constr.BuildDupeInfo ) and isvector( constr.BuildDupeInfo.EntityPos ) then
			constr.BuildDupeInfo.EntityPos:Mul( relativeScalePhys )
		end

	end


	for arg, val in pairs( constr:GetTable() ) do

		if not ( CollisionResizer.IsValidEntity( val ) and val.Constraints and string.sub( arg, 1, 3 ) == "Ent" ) then continue end

		if val ~= ent then

			print("Making", val, "forget about", constr, "(" .. constr:GetCreationID() .. ")")

			for i, otherConstr in pairs( val.Constraints ) do
				if constr == otherConstr then
					table.remove( val.Constraints, i )
				end
			end

		elseif LPos then

			LPos["LPos" .. string.sub( arg, 4 )] = true

		end

	end

	local constrData	= {}
	local constrDesc	= duplicator.ConstraintType[constrType]

	for i, arg in pairs( constrDesc.Args ) do

		local val = constr[arg]

		if doResize and LPos[arg] and isvector( val ) then
			val:Mul( relativeScalePhys )
		end

		constrData[i] = val or false

	end

	constr:Remove()

	return {
		constrDesc.Func,
		constrData,
		constr.BuildDupeInfo -- BuildDupeInfo is from Advanced Duplicator 2
	}

end


local function getAndResizeConstraintsVals( ent, relativeScalePhys, constrsVals )

	local constrs = ent.Constraints

	constrsVals = constrsVals or {}

	if not constrs then return constrsVals end

	for i, constr in pairs( constrs ) do

		print( ent, constr, constr:GetCreationID() )

		constrs[i] = nil

		if not ( CollisionResizer.IsValidEntity( constr ) and constrsVals[constr] == nil and constr.Type ) then continue end

		constrsVals[constr] = getAndResizeConstraintVals( ent, constr, constr.Type, relativeScalePhys )

	end

	return constrsVals

end


local function applyConstraintsVals( constrsVals )

	for constr, desc in pairs( constrsVals ) do

		local newConstr = desc[1]( unpack( desc[2] ) )
		print( constr, "(" .. constr:GetCreationID() .. ")", "->", newConstr, "(" .. newConstr:GetCreationID() .. ")" )

		if CollisionResizer.IsValidEntity( newConstr ) then

			undo.ReplaceEntity( constr, newConstr )
			cleanup.ReplaceEntity( constr, newConstr )

			-- BuildDupeInfo is from Advanced Duplicator 2
			newConstr.BuildDupeInfo = desc[3]

		end

		constrsVals[constr] = nil
		constr:Remove()

	end

end


------------------------------------------------
--             Physics Functions              --
------------------------------------------------


local function getPhysObjData( phys )

	return {
		phys:IsGravityEnabled(),
		phys:GetMaterial(),
		phys:IsCollisionEnabled(),
		phys:IsDragEnabled(),
		phys:GetVelocity(),
		phys:GetAngleVelocity(),
		phys:IsMotionEnabled(),
		phys:GetMass()
	}

end


local function applyPhysObjData( phys, physObjData )

	phys:EnableGravity( physObjData[1] )
	phys:SetMaterial( physObjData[2] )
	phys:EnableCollisions( physObjData[3] )
	phys:EnableDrag( physObjData[4] )
	phys:SetVelocity( physObjData[5] )
	phys:AddAngleVelocity( physObjData[6] - phys:GetAngleVelocity() )
	phys:EnableMotion( physObjData[7] )
	phys:SetMass( physObjData[8] )

end


------------------------------------------------
--           Size Handler Functions           --
------------------------------------------------


local function CreateSizeHandler( ent )

	local sizeHandler = ents.Create( "sizehandler" )
	sizeHandler:SetPos( ent:GetPos() )
	sizeHandler:SetAngles( ent:GetAngles() )
	sizeHandler:SetParent( ent )
	sizeHandler:Spawn()
	return sizeHandler

end


function CollisionResizer.FindSizeHandler( ent )

	if CollisionResizer.IsValidEntity( ent.sizeHandler ) then return ent.sizeHandler end

	for _, sizeHandler in pairs( ents.FindByClass( "sizehandler" ) ) do

		if sizeHandler:GetParent() == ent then return sizeHandler end

	end

end



--[[
hook.Add( "EntityRemoved", "collision_resizer", function( ent )

	if ( CollisionResizer.entsPhysicalData[ ent ] ~= nil ) then CollisionResizer.entsPhysicalData[ ent ] = nil end

end )]]




local function physicalRestoreStuff( ent, constrsVals, physObjData )

	local phys = ent:GetPhysicsObject()

	applyConstraintsVals( constrsVals )

	if not CollisionResizer.IsValidPhysicsObject( phys ) then return end

	applyPhysObjData( phys, physObjData )

	phys:Wake()

	if ent.IsMotionControlled then
		CollisionResizer.o_StartMotionController( ent )
	end

end


-- If you want the data to be saved to the duplicator, use CollisionResizer.SetScale instead.
function CollisionResizer.SetPhysicalScale( ent, scalePhys, keepConstrsLocalPositions, disableClientPhysics, keepMass )

	if not CollisionResizer.SupportsPhysicalData( ent ) then return end

	local phys				= ent:GetPhysicsObject()

	if not CollisionResizer.IsValidPhysicsObject( phys ) then return end

	local isReset			= scalePhys == vector_ones

	local physicalData		= CollisionResizer.entsPhysicalData[ent] or ( not isReset and CollisionResizer.CreatePhysicalData( ent, phys ) )

	if not physicalData then return end

	local relativeScalePhys	= ( not keepConstrsLocalPositions ) and CollisionResizer.VecDivEW( scalePhys, physicalData[1] )
	local constrsVals		= getAndResizeConstraintsVals( ent, relativeScalePhys )

	local physObjData		= getPhysObjData( phys )

	physicalData[1]:Set( scalePhys )

	phys = CollisionResizer.ResizePhysics( ent, physicalData )
	if phys and not isReset then phys:SetDamping( 0, 0 ) end

	local sizeHandler	= CollisionResizer.FindSizeHandler( ent )

	if disableClientPhysics or isReset then -- disable client physics

		if sizeHandler and Vector( sizeHandler:GetPhysicalScale() ) ~= vector_ones then

			sizeHandler:SetPhysicalScale( tostring( vector_ones ) )

			net.Start( "collision_resizer_reset_physical_scale" )
				net.WriteEntity( ent )
			net.Broadcast()

		end

	else

		if not sizeHandler then
			print("no sizehandler found")
			sizeHandler = CreateSizeHandler( ent )
		end

		if sizeHandler then
			sizeHandler:SetPhysicalScale( tostring( scalePhys ) )
		end

		-- TODO: unfinished business here
		-- Adding a small timer ensures consistency when resizing.
		-- Unsure, but:
		--	If a timer is used, you'll get different (smaller?) collision bounds on client, smart snap will work better with that
		--	If no timer is used but scale change is checked for clientside, you'll get same collision bounds on client
		-- For now no timer is used as it's cleaner, especially since the other option means the collision bounds are preserved

		net.Start( "collision_resizer_set_physical_scale" )
			net.WriteEntity( ent )
			net.WriteString( tostring( scalePhys ) )
			net.WriteString( tostring( physicalData[2] ) )
			net.WriteString( tostring( physicalData[3] ) )
		net.Broadcast()


	end

	ent.sizeHandler = sizeHandler

	if not keepMass then
		physObjData[8] = math.Clamp( physicalData[4] * scalePhys.x * scalePhys.y * scalePhys.z, 0.1, 50000 )
	end

	physicalRestoreStuff( ent, constrsVals, physObjData )

end



function CollisionResizer.SetVisualScale( ent, scaleVisu )

	local sizeHandler = CollisionResizer.FindSizeHandler( ent )

	if not sizeHandler and scaleVisu ~= vector_ones and scaleVisu ~= vector_origin then
		sizeHandler = CreateSizeHandler( ent )
	end

	local str = tostring( scaleVisu )

	if sizeHandler then
		sizeHandler:SetVisualScale( str )
	end

	net.Start( "collision_resizer_set_visual_scale" )
		net.WriteEntity( ent )
		net.WriteString( str )
	net.Broadcast()

end


function CollisionResizer.ResetVisualScale( ent )

	local sizeHandler = CollisionResizer.FindSizeHandler( ent )
	if sizeHandler then sizeHandler:SetVisualScale( tostring( vector_ones ) ) end

	net.Start( "collision_resizer_reset_visual_scale" )
		net.WriteEntity( ent )
	net.Broadcast()

end


function CollisionResizer.SetScale( ent, scalePhys, scaleVisu, keepConstrsLocalPositions, disableClientPhysics, keepMass )

	local resetPhys 	= ( scalePhys == vector_ones )
	local resetVisu 	= ( scaleVisu == vector_ones )

	if scalePhys then
		CollisionResizer.SetPhysicalScale( ent, scalePhys, keepConstrsLocalPositions, disableClientPhysics, keepMass )
	end

	if scaleVisu then
		if resetVisu then
			CollisionResizer.ResetVisualScale( ent )
		else
			CollisionResizer.SetVisualScale( ent, scaleVisu )
		end
	end

	if resetPhys and resetVisu then

		local sizeHandler = CollisionResizer.FindSizeHandler( ent )
		if sizeHandler then
			sizeHandler:Remove()
		end

		CollisionResizer.ClearDuplicatorData( ent )
		return true

	end

	CollisionResizer.SaveDuplicatorData( ent, scalePhys, scaleVisu, disableClientPhysics, keepMass )

	return true

end



function CollisionResizer.GetScale( ent )

	local physicalData		= CollisionResizer.entsPhysicalData[ent]
	-- if it exists, ent.EntityMods["advr"] first 6 values are numbers representing the collision scale then the visual scale
	local duplicatorData	= CollisionResizer.GetDuplicatorData( ent )

	local scalePhys	= (
		( physicalData and physicalData[1] ) or
		( duplicatorData and Vector( duplicatorData[1], duplicatorData[2], duplicatorData[3] ) ) or
		( Vector( 1, 1, 1 ) )
	)

	local scaleVisu	= (
		( duplicatorData and Vector( duplicatorData[4], duplicatorData[5], duplicatorData[6] ) ) or
		( Vector( 1, 1, 1 ) )
	)

	return scalePhys, scaleVisu

end