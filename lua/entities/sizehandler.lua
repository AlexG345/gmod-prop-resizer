AddCSLuaFile()

ENT.Type				= "anim"
ENT.DisableDuplicator	= true

local RESET = Vector( 1, 1, 1 )
local EMPTY = Vector( 0, 0, 0 )
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

	self:NetworkVar( "String",	0,	"VisualScale",			{ KeyName = "visualscale" } )

	self:NetworkVar( "String",	1,	"ActualPhysicsScale",	{ KeyName = "actualphysicsscale" } )

	if CLIENT then

		local ent = self:GetParent()

		if CollisionResizer.IsValidEntity( ent ) then

			if isfunction( self.RefreshVisualSize ) then self:RefreshVisualSize( ent ) end

			if isfunction( self.RefreshClientPhysics ) then self:RefreshClientPhysics( ent ) end

		end

	end

end


if CLIENT then


	function ENT:Think()

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		if not CollisionResizer.ClientPhysics[ent] then return end

		local physobj = ent:GetPhysicsObject()

		if not CollisionResizer.IsValidPhysicsObject( physobj ) then return end

		physobj:SetPos( ent:GetPos() )
		physobj:SetAngles( ent:GetAngles() )
		physobj:EnableMotion( false )
		physobj:Sleep()

	end


	function ENT:RefreshVisualSize( ent )

		local sizedata = CollisionResizer.ResizedEntities[ ent ]
		local scale

		if not sizedata and isfunction( self.GetVisualScale ) then

			scale = Vector( self:GetVisualScale() )

			if scale ~= RESET and scale ~= EMPTY then

				sizedata = CollisionResizer.CreateSizeData( ent )
				sizedata[1]:Set( scale )

			end

		end

		if not sizedata then return end

		scale = scale or sizedata[ 1 ]

		local m = Matrix()

		m:Scale( scale )
		ent:EnableMatrix( "RenderMultiply", m )
		ent:SetRenderBounds( sizedata[ 2 ] * scale, sizedata[ 3 ] * scale )
		ent:DestroyShadow()
		ent:SetLOD( CollisionResizer.IsBig( scale ) and 0 or -1 )

	end


	function ENT:RefreshClientPhysics( ent )

		local physdata = CollisionResizer.ClientPhysics[ent]
		local scale

		if not physdata and isfunction( self.GetActualPhysicsScale ) then

			scale = Vector( self:GetActualPhysicsScale() )

			if scale ~= RESET and scale ~= EMPTY then

				physdata = CollisionResizer.CreateClientPhysicsData( ent )
				physdata[1]:Set( scale )

			end

		end

		if physdata then

			local success = CollisionResizer.ResizePhysics( ent, scale or physdata[ 1 ] )

			if success then

				local physobj = ent:GetPhysicsObject()

				physobj:SetPos( ent:GetPos() )
				physobj:SetAngles( ent:GetAngles() )
				physobj:EnableMotion( false )
				physobj:Sleep()

			end

		end

	end


	function ENT:OnNetworkEntityCreated()

		local ent = self:GetParent()

		if not CollisionResizer.IsValidEntity( ent ) then return end

		self:RefreshVisualSize( ent )
		self:RefreshClientPhysics( ent )

	end

end

scripted_ents.Register( ENT, "sizehandler" )