local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category = "Construction"
TOOL.Name = "#tool." .. mode .. ".name"

TOOL.ClientConVar[ "sx" ]	= "1.0"
TOOL.ClientConVar[ "sy" ]	= "1.0"
TOOL.ClientConVar[ "sz" ]	= "1.0"
TOOL.ClientConVar[ "smwo" ]	= "1"
TOOL.ClientConVar[ "cx" ]	= "1.0"
TOOL.ClientConVar[ "cy" ]	= "1.0"
TOOL.ClientConVar[ "cz" ]	= "1.0"
TOOL.ClientConVar[ "prco" ]	= "0"
TOOL.ClientConVar[ "dcp" ]	= "0"
TOOL.ClientConVar[ "copy" ]	= "1"

if SERVER then


	local advresizer_clamp = CreateConVar( mode .. "_clamp", "0", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Force the Prop Resizer to clamp its values." )


	local function ClampVal( scale )

		scale.x = math.Clamp( scale.x, 0.1, 10 )
		scale.y = math.Clamp( scale.y, 0.1, 10 )
		scale.z = math.Clamp( scale.z, 0.1, 10 )

	end


	function TOOL:GetClientVector( x, y, z )

		return Vector( self:GetClientNumber( x ), self:GetClientNumber( y ), self:GetClientNumber( z ) )

	end


	function TOOL:LeftClick( Trace )

		local ent = Trace.Entity

		if not CollisionResizer.IsValidEntity( ent ) then return false end

		if ent:IsRagdoll() then return false end

		local pscale = self:GetClientVector( "sx", "sy", "sz" )

		local vscale = self:GetClientBool( "smwo" ) and pscale or self:GetClientVector( "cx", "cy", "cz" )

		if advresizer_clamp:GetBool() then
			ClampVal( pscale )
			ClampVal( vscale )
		end

		return CollisionResizer.SetSize( ent, pscale, vscale, self:GetClientBool( "prco" ), self:GetClientBool( "dcp" ) )

	end


	function TOOL:RightClick( Trace )

		local ent = Trace.Entity

		if not CollisionResizer.IsValidEntity( ent ) then return false end

		if ent:IsRagdoll() then return false end

		CollisionResizer.FixPhysicalSize( ent )
		CollisionResizer.FixVisualSize( ent )

		return true

	end


	function TOOL:Reload( Trace )

		local ent = Trace.Entity

		if not CollisionResizer.IsValidEntity( ent ) then return false end

		if ent:IsRagdoll() then return false end

		local physobj = ent:GetPhysicsObject()
		local ply = self:GetOwner()
		local sizedata = CollisionResizer.ResizedEntities[ent] or CollisionResizer.CreateSizeData( ent, physobj )
		local sizeVec = sizedata[ 1 ]

		sx = string.format( "%.2f", sizeVec[1] )
		sy = string.format( "%.2f", sizeVec[2] )
		sz = string.format( "%.2f", sizeVec[3] )

		local sizes = ent.EntityMods and ent.EntityMods["advr"]
			-- We get the visual scale from the table meant for the duplicator!
			-- if it exists, ent.EntityMods["advr"] contains 6 numbers: the collision scale then the visual scale
		local visualVec = sizes and Vector( sizes[4], sizes[5], sizes[6])  or Vector( 1, 1, 1 )
		cx = string.format( "%.2f", visualVec[1] )
		cy = string.format( "%.2f", visualVec[2] )
		cz = string.format( "%.2f", visualVec[3] )
		ply:ChatPrint( sx .. ", " .. sy .. ", " .. sz .. " | " .. cx .. ", " .. cy .. ", " .. cz )

		if self:GetClientBool( "copy" ) then
			ply:ConCommand( mode .. "_sx " .. sx )
			ply:ConCommand( mode .. "_sy " .. sy )
			ply:ConCommand( mode .. "_sz " .. sz )
			ply:ConCommand( mode .. "_cx " .. cx )
			ply:ConCommand( mode .. "_cy " .. cy )
			ply:ConCommand( mode .. "_cz " .. cz )
		end

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

	function TOOL:LeftClick( Trace )
		local ent = Trace.Entity
		return CollisionResizer.IsValidEntity( ent ) and not ent:IsRagdoll()
	end

	function TOOL:RightClick( Trace )
		local ent = Trace.Entity
		return CollisionResizer.IsValidEntity( ent ) and not ent:IsRagdoll()
	end

	function TOOL:Reload( Trace )
		local ent = Trace.Entity
		return CollisionResizer.IsValidEntity( ent ) and not ent:IsRagdoll()
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

	language.Add( "tool." .. mode .. ".sxyz", "Physical XYZ Scale" )
	language.Add( "tool." .. mode .. ".sx", "Physical X Scale" )
	language.Add( "tool." .. mode .. ".sy", "Physical Y Scale" )
	language.Add( "tool." .. mode .. ".sz", "Physical Z Scale" )
	language.Add( "tool." .. mode .. ".smwo", "Scale Visual with Physical" )
	language.Add( "tool." .. mode .. ".smwo.help", "Use the above values to scale visually." )
	language.Add( "tool." .. mode .. ".cxyz", "Visual XYZ Scale" )
	language.Add( "tool." .. mode .. ".cx", "Visual X Scale" )
	language.Add( "tool." .. mode .. ".cy", "Visual Y Scale" )
	language.Add( "tool." .. mode .. ".cz", "Visual Z Scale" )
	language.Add( "tool." .. mode .. ".prco", "Preserve Constraint Locations" )
	language.Add( "tool." .. mode .. ".prco.help", "If selected, constraints stay fixed in the prop’s local space when resizing." )
	language.Add( "tool." .. mode .. ".dcp", "Disable Client Physics" )
	language.Add( "tool." .. mode .. ".copy", "Copy values on reload" )


	local cvarlist = TOOL:BuildConVarList()

	function TOOL.BuildCPanel( cPanel )

		local prefix = "#tool." .. mode .. "."

		cPanel:Help( prefix .. "desc" )

		cPanel:ToolPresets( mode, cvarlist )

		local function createScaleSliders( scaleType )

			local scaleSliders = {}

			local XYZNumSlider = cPanel:NumSlider( prefix .. scaleType .. "xyz", nil, 0.1, 10 )
				function XYZNumSlider.Scratch:OnValueChanged( value )
					for _, slider in ipairs( scaleSliders ) do
						slider.Scratch:SetValue( value )
						slider:ValueChanged( value )
					end
				end

			for i, axis in ipairs( { "x", "y", "z" } ) do
				local t = scaleType .. axis
				local cVar = mode .. "_" .. t
				local slider = cPanel:NumSlider( prefix .. t, cVar, 0.1, 10 )
				slider.m_strConVar = cVar
				scaleSliders[i] = slider
			end

			-- prevents desync when using xyz slider
			local slider = scaleSliders[1]
			function slider:OnValueChanged( value )
				if XYZNumSlider:IsEditing() then
					XYZNumSlider:SetValue( value )
				end
			end

		end

		createScaleSliders( "s" )

		cPanel:CheckBox( prefix .. "smwo", mode .. "_smwo" )

		createScaleSliders( "c" )

		cPanel:CheckBox( prefix .. "prco", mode .. "_prco" )
			cPanel:ControlHelp( prefix .. "prco.help" )
		cPanel:CheckBox( prefix .. "dcp", mode .. "_dcp" )
		cPanel:CheckBox( prefix .. "copy", mode .. "_copy" )

	end

end