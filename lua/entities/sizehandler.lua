AddCSLuaFile()

ENT.Type				= "anim"
ENT.DisableDuplicator	= true

local vector_ones	= Vector( 1, 1, 1 )
local models_error	= Model( "models/error.mdl" )


function ENT:Initialize()

	self:SetNoDraw( true )
	self:DrawShadow( false )
	self:SetNotSolid( true )
	self:SetModel( models_error )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetTransmitWithParent( true )

end


function ENT:OnRemove()

	local ent = self:GetParent()

	-- Can cause some problems.
	-- CollisionResizer.entsPhysicalData[ent] = nil

	if ent:IsValid() then
		ent.sizeHandler = nil
	end

end



function ENT:SetupDataTables()

	self:NetworkVar( "String",	0,	"VisualScale",		{ KeyName = "visual_scale" } )
	self:NetworkVar( "String",	1,	"PhysicalScale",	{ KeyName = "physical_scale" } )

	if CLIENT then

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		self:RefreshVisualScale( ent )

		-- useful for duplicator mostly
		self:RefreshPhysicalScale( ent )

	end

end


if CLIENT then


	function ENT:Think()

		local ent = self:GetParent()

		if not ( CollisionResizer.IsValidEntity( ent ) and CollisionResizer.entsPhysicalData[ent] ) then return end

		CollisionResizer.RefreshPhysObj( ent )

	end


	function ENT:RefreshVisualScale( ent )

		local visualData = CollisionResizer.entsVisualData[ent]

		if not visualData then

			local scale = Vector( self:GetVisualScale() )

			if scale == vector_ones or scale == vector_origin then return end

			visualData = CollisionResizer.CreateVisualData( ent )
			if not visualData then return end
			visualData[1]:Set( scale )

		end

		CollisionResizer.ApplyVisualData( ent, visualData )

	end


	function ENT:RefreshPhysicalScale( ent )

		print("-- Refreshing Physical Scale --", ent)

		local physicalData	= CollisionResizer.entsPhysicalData[ent]
		local scalePhys		= Vector( self:GetPhysicalScale() )

		if not physicalData then

			if scalePhys == vector_ones or scalePhys == vector_origin then return end

			physicalData = CollisionResizer.CreatePhysicalData( ent )
			if not physicalData then return end

		end

		if physicalData[1] == scalePhys then return end
		physicalData[1]:Set( scalePhys )

		CollisionResizer.ApplyPhysicalData( ent, physicalData )

	end


	function ENT:OnNetworkEntityCreated()

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		self:RefreshVisualScale( ent )
		self:RefreshPhysicalScale( ent )

	end


	-- TODO: what the hell does this do?
	hook.Add( "NetworkEntityCreated", "collision_resizer", function( ent )

		if ent:GetClass() == "sizehandler" and isfunction( ent.OnNetworkEntityCreated ) then
			ent:OnNetworkEntityCreated()
		end

	end )

end

scripted_ents.Register( ENT, "sizehandler" )
