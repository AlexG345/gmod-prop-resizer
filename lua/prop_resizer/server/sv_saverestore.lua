------------------------------------------------
--                   Saves                    --
------------------------------------------------

saverestore.AddSaveHook( "collision_resizer", function( save )

	save:StartBlock( "collision_resizer_SaveData" )

		save:WriteInt( CollisionResizer.RemoveInvalidEntities( CollisionResizer.entsPhysicalData ) )

		for ent, physicalData in CollisionResizer.entsPhysicalData do

			save:WriteEntity( ent )

			local phys = CollisionResizer.HasValidPhysics( ent ) and ent:GetPhysicsObject()

			local savedata = {
				physicalData,
				CollisionResizer.IsValidPhysicsObject( phys ) and {
					phys:IsGravityEnabled(),
					phys:GetMaterial(),
					phys:IsCollisionEnabled(),
					phys:IsDragEnabled(),
					phys:GetVelocity(),
					phys:GetAngleVelocity(),
					phys:IsMotionEnabled(),

					phys:IsAsleep(),
				}
			}

			saverestore.WriteTable( savedata, save )

		end

	save:EndBlock()

end )

local EntitiesToRestore = {}

saverestore.AddRestoreHook( "collision_resizer", function( restore )

	local name = restore:StartBlock()

		if name ~= "collision_resizer_SaveData" then
			restore:EndBlock()
			return
		end

		for i = 1, restore:ReadInt() do

			local ent		= restore:ReadEntity()
			local savedata	= saverestore.ReadTable( restore )

			if CollisionResizer.IsValidEntity( ent ) then

				EntitiesToRestore[ent] = savedata

			end

		end

	restore:EndBlock()

end )

hook.Add( "Restored", "collision_resizer", function()

	local physObjsData	= {}
	local constrsVals	= {}

	for ent, savedata in pairs( EntitiesToRestore ) do

		EntitiesToRestore[ent] = nil

		local physicalData	= savedata[1]
		local physObjData	= savedata[2]

		CollisionResizer.entsPhysicalData[ent] = physicalData

		if not physObjData then continue end
		physObjsData[ent] = physObjData

		getAndResizeConstraintsVals( ent, nil, constrsVals )

		local phys		= CollisionResizer.ResizePhysics( ent, physicalData )
		local scalePhys = physicalData[1]

		if phys then
			phys:SetMass( math.Clamp( physicalData[4] * scalePhys.x * scalePhys.y * scalePhys.z, 0.1, 50000 ) )
			phys:SetDamping( 0, 0 )
		else
			physObjsData[ent] = nil
		end

	end

	applyConstraintsVals( constrsVals )

	for ent, physObjData in pairs( physObjsData ) do

		local phys = ent:GetPhysicsObject()

		phys:EnableGravity( physObjData[1] )
		phys:SetMaterial( physObjData[2] )
		phys:EnableCollisions( physObjData[3] )
		phys:EnableDrag( physObjData[4] )
		phys:SetVelocity( physObjData[5] )
		phys:AddAngleVelocity( physObjData[6] - phys:GetAngleVelocity() )
		phys:EnableMotion( physObjData[7] )

		if physObjData[8] then phys:Sleep() else phys:Wake() end

		if ent.IsMotionControlled then CollisionResizer.o_StartMotionController( ent ) end

	end

end )