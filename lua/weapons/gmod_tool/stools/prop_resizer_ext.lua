local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category = "Construction"
TOOL.Name = "#tool." .. mode .. ".name"

TOOL.ClientConVar["phys_x"]							= "1.0"
TOOL.ClientConVar["phys_y"]							= "1.0"
TOOL.ClientConVar["phys_z"]							= "1.0"
TOOL.ClientConVar["phys_xyz"]						= "1.0"
TOOL.ClientConVar["use_phys_for_visu"]				= "1"
TOOL.ClientConVar["visu_x"]							= "1.0"
TOOL.ClientConVar["visu_y"]							= "1.0"
TOOL.ClientConVar["visu_z"]							= "1.0"
TOOL.ClientConVar["visu_xyz"]						= "1.0"
TOOL.ClientConVar["keep_mass"]						= "1.0"
TOOL.ClientConVar["keep_constrs_local_positions"]	= "0"
TOOL.ClientConVar["disable_cl_phys"]				= "0"
TOOL.ClientConVar["copy"]							= "1"


if SERVER then


	local advresizer_clamp = CreateConVar( mode .. "_clamp", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Force the Prop Resizer to clamp its values." )


	local function clampVector( vec )

		for i = 1, 3 do
			vec[i] = math.Clamp( vec[i], 0.1, 10 )
		end

	end


	function TOOL:GetClientVector( prefix )

		return Vector(
			self:GetClientNumber( prefix .. "_x" ),
			self:GetClientNumber( prefix .. "_y" ),
			self:GetClientNumber( prefix .. "_z" )
		)

	end

	function TOOL:SetClientVector( prefix, x, y, z )

		local ply = self:GetOwner()

		for axis, value in pairs({ x = x, y = y, z = z }) do
			ply:ConCommand( mode .. "_" .. prefix .. "_" .. axis .. " " .. value )
		end

	end



	function TOOL:LeftClick( trace )

		local ent = trace.Entity
		if not CollisionResizer.SupportsPhysicalData( ent ) then return false end

		local scalePhys = self:GetClientVector( "phys" )
		local scaleVisu = self:GetClientBool( "use_phys_for_visu" ) and scalePhys or self:GetClientVector( "visu" )

		if advresizer_clamp:GetBool() then
			clampVector( scalePhys )
			clampVector( scaleVisu )
		end

		return CollisionResizer.SetScale(
			ent,
			scalePhys,
			scaleVisu,
			self:GetClientBool( "keep_constrs_local_positions" ),
			self:GetClientBool( "disable_cl_phys" ),
			self:GetClientBool( "keep_mass" )
		)

	end


	function TOOL:RightClick( trace )

		local ent = trace.Entity

		if not CollisionResizer.SupportsPhysicalData( ent ) then return false end

		return CollisionResizer.SetScale(
			ent,
			Vector( 1, 1, 1 ),
			Vector( 1, 1, 1 ),
			self:GetClientBool( "keep_constrs_local_positions" ),
			self:GetClientBool( "disable_cl_phys" ),
			self:GetClientBool( "keep_mass" )
		)

	end


	function TOOL:Reload( trace )

		local scalePhys, scaleVisu = CollisionResizer.GetScale( trace.Entity )

		if not scalePhys then return end

		phys_x = string.format( "%.4f", scalePhys.x )
		phys_y = string.format( "%.4f", scalePhys.y )
		phys_z = string.format( "%.4f", scalePhys.z )

		visu_x = string.format( "%.4f", scaleVisu.x )
		visu_y = string.format( "%.4f", scaleVisu.y )
		visu_z = string.format( "%.4f", scaleVisu.z )

		local ply = self:GetOwner()

		ply:ChatPrint( phys_x .. ", " .. phys_y .. ", " .. phys_z .. " | " .. visu_x .. ", " .. visu_y .. ", " .. visu_z )

		if not self:GetClientBool( "copy" ) then return true end

		self:SetClientVector( "phys", phys_x, phys_y, phys_z )
		self:SetClientVector( "visu", visu_x, visu_y, visu_z )

		return true

	end

else

	--[[
	Without the 4 function definitions below there is no sound and no trace on the client.
	But on the original addon there was no need for that.
	I've already tried fixing this issue but i just can't find what causes it.
	It might be due to the mode variable (from TOOL.Mode) that i've used instead of using the string "advresizer"
	I could try removing the reload function on server-side and see if it's caused by that since it's the biggest change i've done.

	I found another problem: client doesn't detect when the trace hits a resized prop if hit outside of the unresized bounding box...

	function check(ent) return (CollisionResizer.IsValidEntity( ent ) and not ent:IsRagdoll()) end
	]]--

	function TOOL:LeftClick( trace )
		return CollisionResizer.SupportsPhysicalData( trace.Entity )
	end

	function TOOL:RightClick( trace )
		return CollisionResizer.SupportsPhysicalData( trace.Entity )
	end

	function TOOL:Reload( trace )
		return CollisionResizer.SupportsPhysicalData( trace.Entity )
	end

	TOOL.Information =	{
					{ name = "left" },
					{ name = "right" },
					{ name = "reload" }
				}

	language.Add( "tool." .. mode .. ".name", "Prop Resizer" )
	language.Add( "tool." .. mode .. ".desc", "Resizes props" )
	language.Add( "tool." .. mode .. ".left", "Resize" )
	language.Add( "tool." .. mode .. ".right", "Reset size" )
	language.Add( "tool." .. mode .. ".reload", "Copy or see scale" )

	language.Add( "tool." .. mode .. ".phys_xyz", "Physical XYZ Scale" )
	language.Add( "tool." .. mode .. ".phys_x", "Physical X Scale" )
	language.Add( "tool." .. mode .. ".phys_y", "Physical Y Scale" )
	language.Add( "tool." .. mode .. ".phys_z", "Physical Z Scale" )
	language.Add( "tool." .. mode .. ".use_phys_for_visu", "Scale Visual with Physical" )
	language.Add( "tool." .. mode .. ".use_phys_for_visu.help", "Use the above values to scale visually." )
	language.Add( "tool." .. mode .. ".keep_mass", "Preserve mass" )
	language.Add( "tool." .. mode .. ".visu_xyz", "Visual XYZ Scale" )
	language.Add( "tool." .. mode .. ".visu_x", "Visual X Scale" )
	language.Add( "tool." .. mode .. ".visu_y", "Visual Y Scale" )
	language.Add( "tool." .. mode .. ".visu_z", "Visual Z Scale" )
	language.Add( "tool." .. mode .. ".keep_constrs_local_positions", "Preserve Constraint Locations" )
	language.Add( "tool." .. mode .. ".keep_constrs_local_positions.help", "If selected, constraints stay fixed in the prop’s local space when resizing." )
	language.Add( "tool." .. mode .. ".disable_cl_phys", "Disable Client Physics" )
	language.Add( "tool." .. mode .. ".copy", "Copy values on reload" )


	local cvarlist = TOOL:BuildConVarList()

	function TOOL.BuildCPanel( cPanel )

		local prefix = "#tool." .. mode .. "."

		cPanel:Help( prefix .. "desc" )

		cPanel:ToolPresets( mode, cvarlist )

		local function createScaleSliders( scaleType )

			local scaleSliders = {}

			-- HACK: convar is set so that going past the max still updates the other sliders...
			local t = scaleType .. "_xyz"
			local XYZNumSlider = cPanel:NumSlider( prefix .. t, mode .. "_" .. t, 0.1, 10, 4 )

				local oOVC = XYZNumSlider.Scratch.OnValueChanged
				function XYZNumSlider.Scratch:OnValueChanged( value )

					for _, slider in pairs( scaleSliders ) do
						if slider:IsEditing() then return end
					end
					-- if not XYZNumSlider:HasFocus() then return end
					for _, slider in ipairs( scaleSliders ) do
						slider.Scratch:SetValue( value )
						slider:ValueChanged( value )
					end

					oOVC( self, value )
				end

			for i, axis in ipairs( { "x", "y", "z" } ) do
				t = scaleType .. "_" .. axis
				local slider = cPanel:NumSlider( prefix .. t, mode .. "_" .. t, 0.1, 10, 4 )
				scaleSliders[i] = slider
			end

		end

		createScaleSliders( "phys" )

		cPanel:CheckBox( prefix .. "keep_mass", mode .. "_keep_mass" )

		cPanel:CheckBox( prefix .. "use_phys_for_visu", mode .. "_use_phys_for_visu" )

		createScaleSliders( "visu" )

		cPanel:CheckBox( prefix .. "keep_constrs_local_positions", mode .. "_keep_constrs_local_positions" )
			cPanel:ControlHelp( prefix .. "keep_constrs_local_positions.help" )
		cPanel:CheckBox( prefix .. "disable_cl_phys", mode .. "_disable_cl_phys" )
		cPanel:CheckBox( prefix .. "copy", mode .. "_copy" )

	end

end