util.AddNetworkString( "collision_resizer_set_physical_size" )
util.AddNetworkString( "collision_resizer_fix_physical_size" )

local RESET = Vector( 1, 1, 1 )


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

function CollisionResizer.truetest() print("a") end

local function HasValidPhysics( ent ) return ent:GetSolid() == SOLID_VPHYSICS and ent:GetPhysicsObjectCount() == 1 end


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

	local Factory = duplicator.ConstraintType[Type]

	local ConstraintVals = {}

	for k, Arg in pairs( Factory.Args ) do

		ConstraintVals[k] = Constraint[Arg] or false

	end

	ConstraintData[Constraint] = { Factory.Func, ConstraintVals }

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

	local Factory = duplicator.ConstraintType[ Type ]

	local ConstraintVals = {}

	for k, Arg in pairs( Factory.Args ) do

		if table.HasValue( LPos, Arg ) then

			local Val = Constraint[Arg]

			ConstraintVals[k] = isvector( Val ) and ( Val * scale ) or Val or false

		else

			ConstraintVals[k] = Constraint[Arg] or false

		end

	end

	ConstraintData[ Constraint ] = { Factory.Func, ConstraintVals }

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

	for oldConstr, Factory in pairs( ConstraintData ) do

		local newConstr = Factory[1]( unpack( Factory[2] ) )

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

local PhysicsData = {}


local function StorePhysicsData( physobj )

	PhysicsData[1] = physobj:IsGravityEnabled()
	PhysicsData[2] = physobj:GetMaterial()
	PhysicsData[3] = physobj:IsCollisionEnabled()
	PhysicsData[4] = physobj:IsDragEnabled()
	PhysicsData[5] = physobj:GetVelocity()
	PhysicsData[6] = physobj:GetAngleVelocity()
	PhysicsData[7] = physobj:IsMotionEnabled()

end


local function ApplyPhysicsData( physobj )

	physobj:EnableGravity( PhysicsData[1] )
	physobj:SetMaterial( PhysicsData[2] )
	physobj:EnableCollisions( PhysicsData[3] )
	physobj:EnableDrag( PhysicsData[4] )
	physobj:SetVelocity( PhysicsData[5] )
	physobj:AddAngleVelocity( PhysicsData[6] - physobj:GetAngleVelocity() )
	physobj:EnableMotion( PhysicsData[7] )

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

			CollisionResizer.ResizedEntities[ k ] = nil

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

			local Factory = EntitiesToSave[ Key ]

			local ent = Factory[ 1 ]

			save:WriteEntity( ent )

			local savedata = { Factory[ 2 ] }

			if ( HasValidPhysics( ent ) ) then

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

			local scale = sizedata[ 1 ]

			StoreConstraintData( ent )
			PhysicsData_Restore[ ent ] = physdata

			local success = CollisionResizer.ResizePhysics( ent, scale )

			ent:SetCollisionBounds( sizedata[ 2 ] * scale, sizedata[ 3 ] * scale )

			if ( success ) then

				local physobj = ent:GetPhysicsObject()

				physobj:SetMass( math.Clamp( sizedata[ 4 ] * scale.x * scale.y * scale.z, 0.1, 50000 ) )
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

	local pscale = Vector( data[1], data[2], data[3] )
	local vscale = Vector( data[4], data[5], data[6] )

	if pscale ~= RESET and HasValidPhysics( ent ) then

		local physobj = ent:GetPhysicsObject()

		if CollisionResizer.IsValidPhysicsObject( physobj ) then

			local sizedata = CollisionResizer.CreateSizeData( ent, physobj )
			sizedata[ 1 ]:Set( pscale )

			StorePhysicsData( physobj )

			local success = CollisionResizer.ResizePhysics( ent, pscale )

			if ( data[ 7 ] ) then

				GetSizeHandler( ent ):SetActualPhysicsScale( tostring( RESET ) )

			else

				GetSizeHandler( ent ):SetActualPhysicsScale( tostring( pscale ) )

			end

			ent:SetCollisionBounds( sizedata[2] * pscale, sizedata[3] * pscale )

			if ( success ) then

				physobj = ent:GetPhysicsObject()

				physobj:SetMass( math.Clamp( sizedata[4] * pscale.x * pscale.y * pscale.z, 0.1, 50000 ) )
				physobj:SetDamping( 0, 0 )

				ApplyPhysicsData( physobj )

				physobj:Wake()

				if ( ent.IsMotionControlled ) then o_StartMotionController( ent ) end

			end

		end

	end

	local handler = GetSizeHandler( ent )
	handler:SetVisualScale( tostring( vscale ) )

end )


-- Use CollisionResizer.SetSize if you want it to be saved by duplicator!

function CollisionResizer.SetPhysicalSize( ent, scale, prco, dcp )

	if not HasValidPhysics( ent ) then return end
	local physobj = ent:GetPhysicsObject()
	if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

	local sizedata = CollisionResizer.ResizedEntities[ent] or CollisionResizer.CreateSizeData( ent, physobj )

	if prco then StoreConstraintData( ent ) else ResizeAndStoreConstraintData( ent, scale, sizedata[1] ) end
	StorePhysicsData( physobj )

	local success = CollisionResizer.ResizePhysics( ent, scale )
	local sizeHandler = ent.SizeHandler
	local wasResized = CollisionResizer.IsValidEntity( sizeHandler )

	if dcp then -- disable client physics

		net.Start( "collision_resizer_fix_physical_size" )
			net.WriteEntity( ent )
		net.Broadcast()

		if wasResized then

			sizeHandler:SetActualPhysicsScale( tostring( RESET ) )

		end

	else

		if wasResized then

			net.Start( "collision_resizer_set_physical_size" )
				net.WriteEntity( ent )
				net.WriteString( tostring( scale ) )
			net.Broadcast()

		else

			sizeHandler = CreateSizeHandler( ent )
			ent.SizeHandler = sizeHandler

		end

		sizeHandler:SetActualPhysicsScale( tostring( scale ) )

	end

	ent:SetCollisionBounds( sizedata[2] * scale, sizedata[3] * scale )

	if success then

		physobj = ent:GetPhysicsObject()

		physobj:SetMass( math.Clamp( sizedata[ 4 ] * scale.x * scale.y * scale.z, 0.1, 50000 ) )
		physobj:SetDamping( 0, 0 )

		ApplyConstraintData()
		ApplyPhysicsData( physobj )

		physobj:Wake()

		if ent.IsMotionControlled then o_StartMotionController( ent ) end

	else

		ApplyConstraintData()

	end

	sizedata[ 1 ]:Set( scale )

end


function CollisionResizer.FixPhysicalSize( ent, prco )

	if not HasValidPhysics( ent ) then return end

	local physobj = ent:GetPhysicsObject()

	if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

	local sizedata = CollisionResizer.ResizedEntities[ ent ]

	if not sizedata then return end

	if prco then StoreConstraintData( ent ) else ResizeAndStoreConstraintData( ent, RESET, sizedata[ 1 ] ) end
	StorePhysicsData( physobj )

	ent:EnableCustomCollisions( false )
	ent:PhysicsInit( SOLID_VPHYSICS )

	net.Start( "collision_resizer_fix_physical_size" )
		net.WriteEntity( ent )
	net.Broadcast()

	local sizeHandler = ent.SizeHandler

	if CollisionResizer.IsValidEntity( sizeHandler ) then

		sizeHandler:SetActualPhysicsScale( tostring( RESET ) )

	end

	ent:SetCollisionBounds( sizedata[ 2 ], sizedata[ 3 ] )

	physobj = ent:GetPhysicsObject()

	if CollisionResizer.IsValidPhysicsObject( physobj ) then

		physobj:SetMass( sizedata[ 4 ] )

		ApplyConstraintData()
		ApplyPhysicsData( physobj )

		physobj:Wake()

		if ent.IsMotionControlled then o_StartMotionController( ent ) end

	else

		ApplyConstraintData()

	end

	CollisionResizer.ResizedEntities[ ent ] = nil

end

util.AddNetworkString( "collision_resizer_set_visual_size" )
util.AddNetworkString( "collision_resizer_fix_visual_size" )


-- Use CollisionResizer.SetSize if you want it to be saved by duplicator!

function CollisionResizer.SetVisualSize( ent, scale )

	net.Start( "collision_resizer_set_visual_size" )
		net.WriteEntity( ent )
		net.WriteString( tostring( scale ) )
	net.Broadcast()

end


function CollisionResizer.FixVisualSize( ent )

	net.Start( "collision_resizer_fix_visual_size" )
		net.WriteEntity( ent )
	net.Broadcast()

	local sizeHandler = ent.SizeHandler

	if CollisionResizer.IsValidEntity( sizeHandler ) then
		sizeHandler:Remove()
	end

	duplicator.ClearEntityModifier( ent, "advr" )

end


function CollisionResizer.SetSize( ent, pscale, vscale, prco, dcp )

	if dcp == nil then dcp = true end
	sizeHandler = ent.SizeHandler
	wasResized = CollisionResizer.IsValidEntity( sizeHandler )

	local pr = ( pscale == RESET )
	local vr = ( vscale == RESET )

	if pr then CollisionResizer.FixPhysicalSize( ent ) else CollisionResizer.SetPhysicalSize( ent, pscale, prco, dcp ) end

	if vr then CollisionResizer.FixVisualSize( ent ) else CollisionResizer.SetVisualSize( ent, vscale ) end

	if pr and vr then -- no need for a sizehandler
		if wasResized then sizeHandler:Remove() end
		duplicator.ClearEntityModifier( ent, "advr" )
		return true
	end

	if not wasResized then sizeHandler = CreateSizeHandler( ent ) end
	sizeHandler:SetVisualScale( tostring( vscale ) )

	duplicator.StoreEntityModifier( ent, "advr", { pscale.x, pscale.y, pscale.z, vscale.x, vscale.y, vscale.z, dcp } )

	-- print("a") -- debug
	return true

end