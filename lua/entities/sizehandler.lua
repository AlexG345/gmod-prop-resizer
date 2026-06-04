AddCSLuaFile()

ENT.Type				= "anim"
ENT.DisableDuplicator	= true

local vector_ones = Vector( 1, 1, 1 )
local models_error = Model( "models/error.mdl" )


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

	CollisionResizer.ResizedEntities[ent] = nil

	if CollisionResizer.IsValidEntity( ent ) then

		ent.SizeHandler = nil

	end

end



function ENT:SetupDataTables()

	self:NetworkVar( "String",	0,	"VisualScale",		{ KeyName = "visual_scale" } )

	self:NetworkVar( "String",	1,	"PhysicalScale",	{ KeyName = "physical_scale" } )

	if CLIENT then

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		self:RefreshVisualScale( ent )
		self:RefreshPhysicalScale( ent )

	end

end


if CLIENT then


	function ENT:Think()

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		if not CollisionResizer.ClientPhysics[ent] then return end

		self:RefreshPhysObj( ent )

	end


	function ENT:RefreshPhysObj( ent )

		ent = ent or self:GetParent()

		local physobj = ent:GetPhysicsObject()

		if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

		physobj:SetPos( ent:GetPos() )
		physobj:SetAngles( ent:GetAngles() )
		physobj:EnableMotion( false )
		physobj:Sleep()

	end


	function ENT:RefreshVisualScale( ent )

		local sizedata = CollisionResizer.ResizedEntities[ ent ]
		local scale

		if not sizedata then

			scale = Vector( self:GetVisualScale() )

			if scale == vector_ones or scale == vector_origin then return end

			sizedata = CollisionResizer.CreateSizeData( ent )
			if not sizedata then return end
			sizedata[1]:Set( scale )

		end

		scale = scale or sizedata[1]

		local m = Matrix()

		m:Scale( scale )
		ent:EnableMatrix( "RenderMultiply", m )
		ent:SetRenderBounds( sizedata[2] * scale, sizedata[3] * scale )
		ent:DestroyShadow()
		ent:SetLOD( CollisionResizer.IsBig( scale ) and 0 or -1 )

	end


	function ENT:RefreshPhysicalScale( ent )

		local physdata = CollisionResizer.ClientPhysics[ent]
		local scale

		if not physdata then

			scale = Vector( self:GetPhysicalScale() )

			if scale == vector_ones or scale == vector_origin then return end

			physdata = CollisionResizer.CreateClientPhysicsData( ent )
			if not physdata then return end
			physdata[1]:Set( scale )

		end

		local success = CollisionResizer.ResizePhysics( ent, scale or physdata[1] )

		if not success then return end

		self:RefreshPhysObj( ent )

	end


	function ENT:OnNetworkEntityCreated()

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		self:RefreshVisualScale( ent )
		self:RefreshPhysicalScale( ent )

	end

end

scripted_ents.Register( ENT, "sizehandler" )