util.AddNetworkString( "collision_resizer_set_physical_scale" )
util.AddNetworkString( "collision_resizer_fix_physical_scale" )

local vector_ones = Vector( 1, 1, 1 )


local meta = FindMetaTable( "Entity" )

local o_StartMotionController = meta.StartMotionController

function meta.StartMotionController(ent)

	o_StartMotionController( ent )
	ent.IsMotionControlled = true

end

local o_StopMotionController = meta.StopMotionController

function meta.StopMotionController(ent)
	o_StopMotionController( ent )
	ent.IsMotionControlled = nil
end


local function hasValidPhysics( ent )
	return ent:GetSolid() == SOLID_VPHYSICS and ent:GetPhysicsObjectCount() == 1
end


function CollisionResizer.CanResize( ent )
	return isentity( ent ) and ent:IsValid() and hasValidPhysics( ent ) and not ent:IsRagdoll()
end


------------------------------------------------
--            Constraint Functions            --
------------------------------------------------

local ConstraintData = {}


local function ForgetConstraint( ent, RConstraint )

	local Constraints = ent.Constraints

	if Constraints then

		local NewTab = {}

		for k, Constraint in pairs( Constraints ) do

			if Constraint ~= RConstraint then

				table.insert( NewTab, Constraint )

			end

		end

		ent.Constraints = NewTab

	end

end


local function GetConstraintVals( ent, Constraint, Type )

	for Arg, Val in pairs( Constraint:GetTable() ) do

		if string.sub( Arg, 1, 3 ) == "Ent" and CollisionResizer.IsValidEntity( Val ) and Val ~= ent then

			ForgetConstraint( Val, Constraint )

		end

	end

	local desc = duplicator.ConstraintType[Type]

	local constrData = {}

	for k, Arg in pairs( desc.Args ) do

		constrData[k] = constrData[Arg] or false

	end

	ConstraintData[Constraint] = { desc.Func, constrData, Constraint.BuildDupeInfo }

	Constraint:Remove()

end


local function GetAndResizeConstraintVals( ent, Constraint, Type, scale )

	local LPos = {}

	for Arg, Val in pairs( Constraint:GetTable() ) do

		if string.sub( Arg, 1, 3 ) == "Ent" then

			if ( Val == ent ) then

				table.insert( LPos, "LPos" .. string.sub( Arg, 4 ) )

			elseif CollisionResizer.IsValidEntity( Val ) then

				ForgetConstraint( Val, Constraint )

			end

		end

	end

	local desc = duplicator.ConstraintType[ Type ]

	local constrData = {}

	for k, Arg in pairs( desc.Args ) do

		if table.HasValue( LPos, Arg ) then

			local Val = Constraint[Arg]

			constrData[k] = isvector( Val ) and ( Val * scale ) or Val or false

		else

			constrData[k] = Constraint[Arg] or false

		end

	end

	ConstraintData[ Constraint ] = { desc.Func, constrData, Constraint.BuildDupeInfo }

	Constraint:Remove()

end


local function StoreConstraintData( ent )

	local Constraints = ent.Constraints

	if not Constraints then return end

	for k, Constraint in pairs( Constraints ) do

		if CollisionResizer.IsValidEntity( Constraint ) and ConstraintData[Constraint] == nil then

			local Type = Constraint.Type

			if Type then

				GetConstraintVals( ent, Constraint, Type )

			end

		end

		Constraints[k] = nil

	end

end


local function ResizeAndStoreConstraintData( ent, scale, oldscale )

	local Constraints = ent.Constraints

	if not Constraints then return end

	for k, constr in pairs( Constraints ) do

		if CollisionResizer.IsValidEntity( constr ) and ( ConstraintData[ constr ] == nil ) then

			local Type = constr.Type

			if ( Type ) then

				if ( Type == "Axis" ) then

					GetConstraintVals( ent, constr, Type )

				else

					GetAndResizeConstraintVals( ent, constr, Type, Vector( scale.x / oldscale.x, scale.y / oldscale.y, scale.z / oldscale.z ) )

				end

			end

		end

		Constraints[k] = nil

	end

end


local function ApplyConstraintData()

	for oldConstr, desc in pairs( ConstraintData ) do

		local newConstr = desc[1]( unpack( desc[2] ) )

		if CollisionResizer.IsValidEntity( newConstr ) then

			undo.ReplaceEntity( oldConstr, newConstr )
			cleanup.ReplaceEntity( oldConstr, newConstr )

		end

		ConstraintData[oldConstr] = nil

	end

end


------------------------------------------------
--             Physics Functions              --
------------------------------------------------


local function getPhysicsData( physobj )

	return {
		physobj:IsGravityEnabled(),
		physobj:GetMaterial(),
		physobj:IsCollisionEnabled(),
		physobj:IsDragEnabled(),
		physobj:GetVelocity(),
		physobj:GetAngleVelocity(),
		physobj:IsMotionEnabled(),
	}

end


local function applyPhysicsData( physobj, physicsData )

	physobj:EnableGravity( physicsData[1] )
	physobj:SetMaterial( physicsData[2] )
	physobj:EnableCollisions( physicsData[3] )
	physobj:EnableDrag( physicsData[4] )
	physobj:SetVelocity( physicsData[5] )
	physobj:AddAngleVelocity( physicsData[6] - physobj:GetAngleVelocity() )
	physobj:EnableMotion( physicsData[7] )

end


------------------------------------------------
--           Size Handler Functions           --
------------------------------------------------


local function CreateSizeHandler( ent )

	local handler = ents.Create( "sizehandler" )
	handler:SetPos( ent:GetPos() )
	handler:SetAngles( ent:GetAngles() )
	handler:SetParent( ent )
	handler:Spawn()
	return handler

end


local function GetSizeHandler( ent )

	local handler = CollisionResizer.FindSizeHandler( ent )

	if CollisionResizer.IsValidEntity( handler ) then return handler end

	return CreateSizeHandler( ent )

end


function CollisionResizer.FindSizeHandler( ent )

	if ent.SizeHandler then return ent.SizeHandler end

	for _, handler in pairs( ents.FindByClass( "sizehandler" ) ) do

		if handler:GetParent() == ent then return handler end

	end

end


function CollisionResizer.CreateSizeData( ent, physobj )

	for k, v in pairs( CollisionResizer.ResizedEntities ) do

		if not CollisionResizer.IsValidEntity( k ) then

			CollisionResizer.ResizedEntities[k] = nil

		end
	end

	local sizedata = {}

	sizedata[1] = Vector( 1, 1, 1 )
	sizedata[2], sizedata[3] = ent:GetCollisionBounds()
	sizedata[4] = physobj:GetMass()

	CollisionResizer.ResizedEntities[ent] = sizedata

	return sizedata

end
--[[
hook.Add( "EntityRemoved", "collision_resizer", function( ent )

	if ( CollisionResizer.ResizedEntities[ ent ] ~= nil ) then CollisionResizer.ResizedEntities[ ent ] = nil end

end )]]

------------------------------------------------
--                   Saves                    --
------------------------------------------------

saverestore.AddSaveHook( "collision_resizer", function( save )

	save:StartBlock( "collision_resizer_SaveData" )

		local EntitiesToSave = {}

		for ent, sizedata in pairs( CollisionResizer.ResizedEntities ) do

			if CollisionResizer.IsValidEntity( ent ) then

				table.insert( EntitiesToSave, { ent, sizedata } )

			else

				CollisionResizer.ResizedEntities[ ent ] = nil

			end

		end

		local l = #EntitiesToSave

		save:WriteInt( l )

		for Key = 1, l do

			local desc = EntitiesToSave[ Key ]

			local ent = desc[ 1 ]

			save:WriteEntity( ent )

			local savedata = { desc[ 2 ] }

			if ( hasValidPhysics( ent ) ) then

				local physobj = ent:GetPhysicsObject()

				if ( CollisionResizer.IsValidPhysicsObject( physobj ) ) then

					savedata[ 2 ] =	{
								physobj:IsGravityEnabled(),
								physobj:GetMaterial(),
								physobj:IsCollisionEnabled(),
								physobj:IsDragEnabled(),
								physobj:GetVelocity(),
								physobj:GetAngleVelocity(),
								physobj:IsMotionEnabled(),

								physobj:IsAsleep()
							}

				end

			end

			saverestore.WriteTable( savedata, save )

		end

	save:EndBlock()

end )

local EntitiesToRestore = {}

saverestore.AddRestoreHook( "collision_resizer", function( restore )

	local name = restore:StartBlock()
	if ( name == "collision_resizer_SaveData" ) then

		local l = restore:ReadInt()

		for i = 1, l do

			local ent = restore:ReadEntity()

			local savedata = saverestore.ReadTable( restore )

			if ( CollisionResizer.IsValidEntity( ent ) ) then

				EntitiesToRestore[ ent ] = savedata

			end

		end

	end
	restore:EndBlock()

end )

hook.Add( "Restored", "collision_resizer", function()

	local PhysicsData_Restore = {}

	for ent, savedata in pairs( EntitiesToRestore ) do

		local sizedata = savedata[ 1 ]

		CollisionResizer.ResizedEntities[ ent ] = sizedata

		local physdata = savedata[ 2 ]

		if ( physdata ) then

			local scale = sizedata[1]

			StoreConstraintData( ent )
			PhysicsData_Restore[ ent ] = physdata

			local success = CollisionResizer.ResizePhysics( ent, scale )

			ent:SetCollisionBounds( sizedata[2] * scale, sizedata[3] * scale )

			if ( success ) then

				local physobj = ent:GetPhysicsObject()

				physobj:SetMass( math.Clamp( sizedata[4] * scale.x * scale.y * scale.z, 0.1, 50000 ) )
				physobj:SetDamping( 0, 0 )

			else

				PhysicsData_Restore[ ent ] = nil

			end

		end

		EntitiesToRestore[ ent ] = nil

	end

	ApplyConstraintData()

	for ent, physdata in pairs( PhysicsData_Restore ) do

		local physobj = ent:GetPhysicsObject()

		physobj:EnableGravity( physdata[1] )
		physobj:SetMaterial( physdata[2] )
		physobj:EnableCollisions( physdata[3] )
		physobj:EnableDrag( physdata[4] )
		physobj:SetVelocity( physdata[5] )
		physobj:AddAngleVelocity( physdata[6] - physobj:GetAngleVelocity() )
		physobj:EnableMotion( physdata[7] )

		if physdata[8] then physobj:Sleep() else physobj:Wake() end

		if ent.IsMotionControlled then o_StartMotionController( ent ) end

	end

end )


duplicator.RegisterEntityModifier( "advr", function( ply, ent, data )

	local scalePhys = Vector( unpack( data, 1, 3 ) )
	local scaleVisu = Vector( unpack( data, 5, 6 ) )

	if scalePhys ~= vector_ones and hasValidPhysics( ent ) then

		local physobj = ent:GetPhysicsObject()

		if CollisionResizer.IsValidPhysicsObject( physobj ) then

			local sizedata = CollisionResizer.CreateSizeData( ent, physobj )
			sizedata[1]:Set( scalePhys )

			local physicsData = getPhysicsData( physobj )

			local success = CollisionResizer.ResizePhysics( ent, scalePhys )

			local disableClientPhysics = data[7]

			GetSizeHandler( ent ):SetPhysicalScale( disableClientPhysics and vector_ones or scalePhys )

			ent:SetCollisionBounds( sizedata[2] * scalePhys, sizedata[3] * scalePhys )

			if success then

				physobj = ent:GetPhysicsObject()

				physobj:SetMass( math.Clamp( sizedata[4] * scalePhys.x * scalePhys.y * scalePhys.z, 0.1, 50000 ) )
				physobj:SetDamping( 0, 0 )

				applyPhysicsData( physobj, physicsData )

				physobj:Wake()

				if ( ent.IsMotionControlled ) then o_StartMotionController( ent ) end

			end

		end

	end

	local handler = GetSizeHandler( ent )
	handler:SetVisualScale( tostring( scaleVisu ) )

end )


-- Use CollisionResizer.SetSize if you want it to be saved by duplicator!

function CollisionResizer.SetPhysicalScale( ent, scale, keepConstrsLocalPositions, disableClientPhysics )

	if not CollisionResizer.CanResize( ent ) then return end
	local physobj = ent:GetPhysicsObject()
	if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

	local sizedata = CollisionResizer.ResizedEntities[ent] or CollisionResizer.CreateSizeData( ent, physobj )

	if keepConstrsLocalPositions then
		StoreConstraintData( ent )
	else
		ResizeAndStoreConstraintData( ent, scale, sizedata[1] )
	end

	local physicsData = getPhysicsData( physobj )

	local success = CollisionResizer.ResizePhysics( ent, scale )
	local sizeHandler = ent.SizeHandler
	local wasResized = CollisionResizer.IsValidEntity( sizeHandler )

	if disableClientPhysics then -- disable client physics

		net.Start( "collision_resizer_fix_physical_scale" )
			net.WriteEntity( ent )
		net.Broadcast()

		if wasResized then

			sizeHandler:SetPhysicalScale( tostring( vector_ones ) )

		end

	else

		if wasResized then

			net.Start( "collision_resizer_set_physical_scale" )
				net.WriteEntity( ent )
				net.WriteString( tostring( scale ) )
			net.Broadcast()

		else

			sizeHandler = CreateSizeHandler( ent )
			ent.SizeHandler = sizeHandler

		end

		sizeHandler:SetPhysicalScale( tostring( scale ) )

	end

	ent:SetCollisionBounds( sizedata[2] * scale, sizedata[3] * scale )

	if success then

		physobj = ent:GetPhysicsObject()

		physobj:SetMass( math.Clamp( sizedata[4] * scale.x * scale.y * scale.z, 0.1, 50000 ) )
		physobj:SetDamping( 0, 0 )

		ApplyConstraintData()
		applyPhysicsData( physobj, physicsData )

		physobj:Wake()

		if ent.IsMotionControlled then o_StartMotionController( ent ) end

	else

		ApplyConstraintData()

	end

	sizedata[1]:Set( scale )

end


function CollisionResizer.FixPhysicalScale( ent, keepConstrsLocalPositions )

	if not CollisionResizer.CanResize( ent ) then return end

	local physobj = ent:GetPhysicsObject()

	if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

	local sizedata = CollisionResizer.ResizedEntities[ ent ]

	if not sizedata then return end

	if keepConstrsLocalPositions then StoreConstraintData( ent ) else ResizeAndStoreConstraintData( ent, vector_ones, sizedata[1] ) end
	local physicsData = getPhysicsData( physobj )

	ent:EnableCustomCollisions( false )
	ent:PhysicsInit( SOLID_VPHYSICS )

	net.Start( "collision_resizer_fix_physical_scale" )
		net.WriteEntity( ent )
	net.Broadcast()

	local sizeHandler = ent.SizeHandler

	if CollisionResizer.IsValidEntity( sizeHandler ) then

		sizeHandler:SetPhysicalScale( tostring( vector_ones ) )

	end

	ent:SetCollisionBounds( sizedata[2], sizedata[3] )

	physobj = ent:GetPhysicsObject()

	if CollisionResizer.IsValidPhysicsObject( physobj ) then

		physobj:SetMass( sizedata[4] )

		ApplyConstraintData()
		applyPhysicsData( physobj, physicsData )

		physobj:Wake()

		if ent.IsMotionControlled then o_StartMotionController( ent ) end

	else

		ApplyConstraintData()

	end

	CollisionResizer.ResizedEntities[ ent ] = nil

end

util.AddNetworkString( "collision_resizer_set_visual_scale" )
util.AddNetworkString( "collision_resizer_fix_visual_scale" )


-- Use CollisionResizer.SetSize if you want it to be saved by duplicator!

function CollisionResizer.SetVisualScale( ent, scale )

	net.Start( "collision_resizer_set_visual_scale" )
		net.WriteEntity( ent )
		net.WriteString( tostring( scale ) )
	net.Broadcast()

end


function CollisionResizer.FixVisualScale( ent )

	net.Start( "collision_resizer_fix_visual_scale" )
		net.WriteEntity( ent )
	net.Broadcast()

	local sizeHandler = ent.SizeHandler

	if CollisionResizer.IsValidEntity( sizeHandler ) then
		sizeHandler:Remove()
	end

	CollisionResizer.ClearDuplicatorData()

end


function CollisionResizer.SetSize( ent, scalePhys, scaleVisu, keepConstrsLocalPositions, disableClientPhysics )

	sizeHandler = ent.SizeHandler
	wasResized = CollisionResizer.IsValidEntity( sizeHandler )

	local fixPhys = ( scalePhys == vector_ones )
	local fixVisu = ( scaleVisu == vector_ones )

	if fixPhys then
		CollisionResizer.FixPhysicalScale( ent )
	else
		CollisionResizer.SetPhysicalScale( ent, scalePhys, keepConstrsLocalPositions, disableClientPhysics )
	end

	if fixVisu then
		CollisionResizer.FixVisualScale( ent )
	else
		CollisionResizer.SetVisualScale( ent, scaleVisu )
	end

	if fixPhys and fixVisu then -- no need for a sizehandler
		if wasResized then sizeHandler:Remove() end
		CollisionResizer.ClearDuplicatorData( ent )
		return true
	end

	if not wasResized then sizeHandler = CreateSizeHandler( ent ) end
	sizeHandler:SetVisualScale( tostring( scaleVisu ) )

	CollisionResizer.SaveDuplicatorData( ent, scalePhys, scaleVisu, disableClientPhysics )

	-- print("a") -- debug
	return true

end


function CollisionResizer.SaveDuplicatorData( ent, scalePhys, scaleVisu, disableClientPhysics )
	duplicator.StoreEntityModifier( ent, "advr", {
		scalePhys.x,
		scalePhys.y,
		scalePhys.z,
		scaleVisu.x,
		scaleVisu.y,
		scaleVisu.z,
		disableClientPhysics
	} )
end


function CollisionResizer.ClearDuplicatorData( ent )
	duplicator.ClearEntityModifier( ent, "advr" )
end



function CollisionResizer.GetScale( ent )

		if not CollisionResizer.CanResize( ent ) then return false end

		local scalesData		= CollisionResizer.ResizedEntities[ent]
		-- if it exists, ent.EntityMods["advr"] contains 6 numbers: the collision scale then the visual scale
		local scalesDataDupe	= ent.EntityMods and ent.EntityMods["advr"]

		local scalePhys	= (
			( scalesData and scalesData[1] ) or
			( scalesDataDupe and Vector( scalesDataDupe[1], scalesDataDupe[2], scalesDataDupe[3] ) ) or
			( Vector( 1, 1, 1 ) )
		)

		local scaleVisu	= (
			( scalesDataDupe and Vector( scalesDataDupe[4], scalesDataDupe[5], scalesDataDupe[6] ) ) or
			( Vector( 1, 1, 1 ) )
		)

		return scalePhys, scaleVisu

end