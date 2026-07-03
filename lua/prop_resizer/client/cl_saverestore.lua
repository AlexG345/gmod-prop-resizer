----------------------------------------
-- Generalized save/restore functions --
----------------------------------------

local function saveData( save, name, entsData )

	save:StartBlock( name )

		save:WriteInt( CollisionResizer.RemoveInvalidEntities( entsData ) )

		for ent, entData in pairs( entsData ) do

			save:WriteEntity( ent )

			saverestore.WriteTable( data, save )

		end

	save:EndBlock()

end


local function restoreData( restore, neededName, entsData )

	local name = restore:StartBlock()

		if name ~= neededName then
			restore:EndBlock()
			return
		end

		for _ = 1, restore:ReadInt() do

			local ent		= restore:ReadEntity()
			local entData	= saverestore.ReadTable( restore )

			if CollisionResizer.IsValidEntity( ent ) then
				entsData[ent] = entData
			end

		end

	restore:EndBlock()

end



-----------------
-- Visual Data --
-----------------

saverestore.AddSaveHook( "collision_resizer", function( save )

	saveData( save, "collision_resizer_SaveData", CollisionResizer.entsVisualData )

end )

saverestore.AddRestoreHook( "collision_resizer", function( restore )

	restoreData( restore, "collision_resizer_SaveData", CollisionResizer.entsVisualData )

end )



-------------------
-- Physical Data --
-------------------

saverestore.AddSaveHook( "clientphysics", function( save )

	saveData( save, "PhysData", CollisionResizer.entsPhysicalData )

end )

saverestore.AddRestoreHook( "clientphysics", function( restore )

	restoreData( restore, "PhysData", CollisionResizer.entsPhysicalData )

end )