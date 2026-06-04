
local function IsValidModel( mdl ) return isstring( mdl ) and util.IsValidModel( mdl ) end


function CollisionResizer.CreateSizeData( ent )

	for entity, _ in pairs( CollisionResizer.ResizedEntities ) do if not CollisionResizer.IsValidEntity( entity ) then CollisionResizer.ResizedEntities[ entity ] = nil end end

	local sizedata = {}

	sizedata[ 1 ] = Vector( 1, 1, 1 )

	sizedata[ 2 ], sizedata[ 3 ] = ent:GetRenderBounds()

	CollisionResizer.ResizedEntities[ ent ] = sizedata

	return sizedata

end
--[[
hook.Add( "EntityRemoved", "collision_resizer", function( ent )

	if ( CollisionResizer.ResizedEntities[ ent ] ~= nil ) then CollisionResizer.ResizedEntities[ ent ] = nil end

end )]]


function CollisionResizer.IsBig( scale )
	return (scale.x >= 4 and (scale.y >= 4 or scale.z >= 4)) or (scale.y >= 4 and scale.z >= 4)
end


function CollisionResizer.CanResize( ent )
	return isentity( ent ) and ent:IsValid() and not ent:IsRagdoll()
end


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

			save:WriteEntity( Factory[ 1 ] )

			saverestore.WriteTable( Factory[ 2 ], save )

		end

	save:EndBlock()

end )

saverestore.AddRestoreHook( "collision_resizer", function( restore )

	local name = restore:StartBlock()
	if ( name == "collision_resizer_SaveData" ) then

		local l = restore:ReadInt()

		for Key = 1, l do

			local ent = restore:ReadEntity()

			local sizedata = saverestore.ReadTable( restore )

			if ( CollisionResizer.IsValidEntity( ent ) ) then

				CollisionResizer.ResizedEntities[ ent ] = sizedata

			end

		end

	end
	restore:EndBlock()

end )

net.Receive( "collision_resizer_set_visual_scale", function( l )

	local ent = net.ReadEntity()
	local scale = net.ReadString()

	if CollisionResizer.IsValidEntity( ent ) and IsValidModel( ent:GetModel() ) then

		scale = Vector( scale )

		local sizedata = CollisionResizer.ResizedEntities[ ent ] or CollisionResizer.CreateSizeData( ent )

		local m = Matrix()

		m:Scale( scale )

		ent:EnableMatrix( "RenderMultiply", m )

		ent:SetRenderBounds( sizedata[2] * scale, sizedata[3] * scale )

		ent:DestroyShadow()

		ent:SetLOD( CollisionResizer.IsBig( scale ) and 0 or -1 )

		sizedata[1]:Set( scale )

	end

end )

net.Receive( "collision_resizer_fix_visual_scale", function( l )

	local ent = net.ReadEntity()

	if CollisionResizer.IsValidEntity( ent ) and IsValidModel( ent:GetModel() ) then

		local sizedata = CollisionResizer.ResizedEntities[ ent ]

		if not sizedata then return end

		ent:DisableMatrix( "RenderMultiply" )

		ent:SetRenderBounds( sizedata[2], sizedata[3] )

		ent:DestroyShadow()

		ent:SetLOD( -1 )

		CollisionResizer.ResizedEntities[ent] = nil

	end

end )

CollisionResizer.ClientPhysics = {}

function CollisionResizer.CreateClientPhysicsData( ent )

	for entity, _ in pairs( CollisionResizer.ClientPhysics ) do if not CollisionResizer.IsValidEntity( entity ) then CollisionResizer.ClientPhysics[entity] = nil end end

	local physdata = { Vector( 1, 1, 1 ) }

	CollisionResizer.ClientPhysics[ent] = physdata

	return physdata

end
--[[
hook.Add( "EntityRemoved", "collision_resizer_clientphysics", function( ent )

	if ( CollisionResizer.ClientPhysics[ ent ] ~= nil ) then CollisionResizer.ClientPhysics[ ent ] = nil end

end )]]

saverestore.AddSaveHook( "clientphysics", function( save )

	save:StartBlock( "PhysData" )

		local EntitiesToSave = {}

		for ent, physdata in pairs( CollisionResizer.ClientPhysics ) do

			if CollisionResizer.IsValidEntity( ent ) then

				table.insert( EntitiesToSave, { ent, physdata } )

			else

				CollisionResizer.ClientPhysics[ ent ] = nil

			end

		end

		local l = #EntitiesToSave

		save:WriteInt( l )

		for Key = 1, l do

			local Factory = EntitiesToSave[ Key ]

			save:WriteEntity( Factory[1] )

			saverestore.WriteTable( Factory[2], save )

		end

	save:EndBlock()

end )

saverestore.AddRestoreHook( "clientphysics", function( restore )

	local name = restore:StartBlock()
	if name == "PhysData" then

		local l = restore:ReadInt()

		for Key = 1, l do

			local ent = restore:ReadEntity()

			local physdata = saverestore.ReadTable( restore )

			if CollisionResizer.IsValidEntity( ent ) then

				CollisionResizer.ClientPhysics[ ent ] = physdata

			end

		end

	end
	restore:EndBlock()

end )

net.Receive( "collision_resizer_set_physical_scale", function( l )

	local ent = net.ReadEntity()
	local scale = net.ReadString()

	if CollisionResizer.IsValidEntity( ent ) then

		scale = Vector( scale )

		local physdata = CollisionResizer.ClientPhysics[ent] or CollisionResizer.CreateClientPhysicsData( ent )

		local success = CollisionResizer.ResizePhysics( ent, scale )

		if success then

			local physobj = ent:GetPhysicsObject()

-- if ( CollisionResizer.IsValidPhysicsObject( physobj ) ) then

				physobj:SetPos( ent:GetPos() )
				physobj:SetAngles( ent:GetAngles() )
				physobj:EnableMotion( false )
				physobj:Sleep()

-- end

		end

		physdata[1]:Set( scale )

	end

end )

net.Receive( "collision_resizer_fix_physical_scale", function( l )

	local ent = net.ReadEntity()

	if CollisionResizer.IsValidEntity( ent ) then

		local physdata = CollisionResizer.ClientPhysics[ent]

		if not physdata then return end

		ent:PhysicsDestroy()

		CollisionResizer.ClientPhysics[ent] = nil

	end

end )


hook.Add( "NetworkEntityCreated", "collision_resizer", function( ent )

	if ent:GetClass() == "sizehandler" and isfunction( ent.OnNetworkEntityCreated ) then

		ent:OnNetworkEntityCreated()

	end

end )