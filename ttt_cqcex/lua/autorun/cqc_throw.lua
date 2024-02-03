local plymeta = FindMetaTable("Player")
if not plymeta then return end

local entmeta = FindMetaTable("Entity")
if not entmeta then return end

local plymeta = FindMetaTable("Player")
if not plymeta then return end

if SERVER then	
	------------------------------------ Tranq code below --------------------------------------
	local function CreateTranqRagdoll( pl )
		local ragdoll = ents.Create( "prop_ragdoll" )
		ragdoll:SetModel( pl:GetModel() )
		ragdoll:SetPos( pl:GetPos() + Vector( 0, 0, 5 ) )
		ragdoll:SetAngles( pl:GetAngles() )
		ragdoll:Spawn()
		
		for i = 1, ragdoll:GetPhysicsObjectCount() - 1 do
			local bone = ragdoll:GetPhysicsObjectNum( i )
			
			if ( IsValid( bone ) ) then
				local pl_bonepos, pl_boneang = pl.kmModel:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
				
				bone:SetPos( pl_bonepos )
				bone:SetAngles( pl_boneang )
				bone:SetVelocity( vector_origin )
			end
		end

		pl.CQCRagdoll = ragdoll
		timer.Simple( 0.1, function()
			net.Start( "TranqRagdoll" )
				net.WriteEntity( pl )
				net.WriteEntity( ragdoll )
			net.Broadcast()
		end )

		ragdoll:SetCollisionGroup( 2 )
		
		return ragdoll
	end
	
	CreateConVar( "cqc_tranqtime", 15, FCVAR_ARCHIVE )
	
	util.AddNetworkString( "TranqRagdoll" )
	hook.Add( "PlayerTick", "TranqPlayersCQC", function( pl )
		if ( pl.CQCTime and pl.CQCTime < CurTime() ) then
			if ( string.find( pl:GetModel(), "female" ) ) then
				pl:EmitSound( "vo/npc/female01/pain01.wav" )
			elseif ( string.find( pl:GetModel(), "male" ) ) then
				pl:EmitSound( "vo/npc/male01/pain04.wav" )
			elseif ( string.find( pl:GetModel(), "combine" ) or string.find( pl:GetModel(), "police" ) ) then
				pl:EmitSound( "npc/metropolice/vo/shit.wav" )
			end
			
			pl.CQCWeapons = {} 
			
			for _, wep in ipairs( pl:GetWeapons() ) do
				table.insert( pl.CQCWeapons, wep:GetClass() )
			end
			
			pl:StripWeapons()
			
			local ragdoll = CreateTranqRagdoll( pl )
			
			pl:Spectate( OBS_MODE_CHASE )
			pl:SpectateEntity( ragdoll )
			
			pl.CQCWakeTime = CurTime() + GetConVarNumber( "cqc_tranqtime" )

			
			pl.CQCTime = nil
		end
		
		if ( pl.CQCWakeTime and pl.CQCWakeTime < CurTime() ) then
			local health, armor = pl:Health(), pl:Armor()
			
			pl:UnSpectate()
			pl:Spawn()
			
			pl:SetHealth( health )
			pl:SetArmor( armor )
			
			if ( IsValid( pl.CQCRagdoll ) ) then
				timer.Simple( 0, function()
					pl:SetPos( pl.CQCRagdoll:GetPos() )
				end )
				
				pl.CQCRagdoll:Remove()
			end
			
			for _, wep in ipairs( pl.CQCWeapons ) do
				pl:Give( wep )
			end
			
			pl.CQCWakeTime = nil 
		end
	end )
	
	hook.Add( "EntityTakeDamage", "TranqDamageCQC", function( ent, dmg )
		for _, pl in ipairs( player.GetAll() ) do
			if ( IsValid( pl.CQCRagdoll ) and pl.CQCRagdoll == ent ) then
				if(dmg:GetDamageType() != 1) then
					if ( pl:Health() > dmg:GetDamage() ) then
						pl:SetHealth( pl:Health() - dmg:GetDamage() )
					else
						local pos = pl.CQCRagdoll:GetPos()
						pl:Spawn()
						pl:SetPos( pos )
						pl:SetHealth( 0 )
						pl:TakeDamageInfo( dmg )
					end
				end
			end
		end
	end )
	
	hook.Add( "PlayerDeath", "TranqDeathCQC", function( pl )
		pl.CQCTime = nil
		pl.CQCWakeTime = nil

		if ( IsValid( pl.CQCRagdoll ) ) then
			pl.CQCRagdoll:Remove()
		end
	end )

	------------------------------------ Custom Hooks ------------------------------------------

	-- Sets up the CQC delay
	hook.Add("PlayerInitialSpawn", "CqcDelay", function( pl )
		pl.CQCDelayTime = true
	end)

	------------------------------------ BSMOD Code Below --------------------------------------

	--util.AddNetworkString("showhint")
	util.AddNetworkString("setkillmovable")
	util.AddNetworkString("removedecals")
	util.AddNetworkString("debugbsmodcalcview")
	
	--A list that a player/npc must have to be killmovable (highlighted blue)
	if !killMovableBones then killMovableBones = {"ValveBiped.Bip01_Spine", "MiniStrider.body_joint"} end
	if !killMovableEnts then killMovableEnts = {} end
	
	function entmeta:SetKillMovable(value)
		self.killMovable = value
		--self:Say("I am set to killMovable")
		net.Start("setkillmovable")
		net.WriteEntity(self)
		net.WriteBool(value)
		net.Broadcast()
	end
	
	--[[function plymeta:ShowHint(text, type, length, player)
		net.Start("showhint")
		net.WriteString(text)
		net.WriteInt(type, 4)
		net.WriteFloat(length)
		net.Send(player)
	end]]
	
	hook.Add( "CreateEntityRagdoll", "BSModCreateEntityRagdoll", function(entity, ragdoll)
		if !IsValid(entity.kmModel) or !IsValid(entity) or !IsValid(ragdoll) then return end
		
		for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
			local bone = ragdoll:GetPhysicsObjectNum(i)
			
			if bone and bone:IsValid() then
				local bonepos, boneang = entity.kmModel:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
				
				bone:SetPos(bonepos, true)
				bone:SetAngles(boneang)
				bone:SetVelocity(vector_origin)
			end
		end
		
		hook.Run("KMRagdoll", entity, ragdoll, entity.kmAnim:GetSequenceName(entity.kmAnim:GetSequence()))
	end)
	
	hook.Add("Think", "BSModThink", function()
		for i, ent in ipairs( ents.GetAll() ) do 
			if ent.killMovable then
				if ent:Health() > GetConVar( "cqc_minhealth" ):GetInt() or ent:Health() <= 0 and GetConVar( "cqc_enabled" ):GetInt() != 0 then
					ent:SetKillMovable(false)
				end
			end
		end
	end)
	
	hook.Add( "PlayerDeath", "BSModPlayerDeath", function( victim, inflictor, attacker )
		victim.blocking = false
	end )
	
	--[[hook.Add("PlayerInitialSpawn", "BSModPlayerInitialSpawn", function(ply)
		timer.Simple(2.5, function()
			ply:SendHint("How to BSMod Kick: type ''bind <key> bsmod_kick'' into the console (without quotation marks)", 3, 15)
			
			timer.Simple(5, function()
				ply:SendHint("How to BSMod KillMove: type ''bind <key> bsmod_killmove'' into the console (without quotation marks)", 3, 15)
				
				timer.Simple(5, function()
					ply:SendHint("You can turn these hints off in the Spawnmenu > Options > BSMod > User Options", 0, 15)
				end)
			end)
		end)
	end)]]
	
	hook.Add("EntityTakeDamage", "BSModTakeDamage", function(ent, dmginfo)
		if ent.inKillMove then dmginfo:SetDamage(0) end
		
		if ent.blocking then
			if !dmginfo:IsDamageType( DMG_FALL ) and
				!dmginfo:IsDamageType( DMG_BURN ) and
				!dmginfo:IsDamageType( DMG_DROWN ) and
				!dmginfo:IsDamageType( DMG_POISON ) and
				!dmginfo:IsDamageType( DMG_SLOWBURN ) and
				!dmginfo:IsDamageType( DMG_DROWNRECOVER ) then
				
				dmginfo:SetDamage(dmginfo:GetDamage() / 2)
				
				ent:GetViewModel():SendViewModelMatchingSequence( ent:GetViewModel():LookupSequence( "fist_blocking_flinch" ) )
				
				timer.Simple(ent:GetViewModel():SequenceDuration(), function()
					if !ent.blocking then return end
					
					ent:GetViewModel():SendViewModelMatchingSequence( ent:GetViewModel():LookupSequence( "fist_blocking" ) )
				end )
			end
		else
			--This happens before the damage is taken
			
			if !ent:IsPlayer() and !ent:IsNPC() and !ent:IsNextBot() then return end
			
			local dmg = dmginfo:GetDamage()
			local attacker = dmginfo:GetAttacker()
			
			if dmg >= ent:Health() and ent.killMovable then
				ent:SetKillMovable(false)
			end
			
			timer.Simple(0, function()
				
				--This happens after the damage is taken
				
				if !IsValid(ent) then return end
				
				
				local canSetKillMovable = false
				
				for _, bone in ipairs(killMovableBones) do
					if ent:LookupBone(bone) then canSetKillMovable = true end
				end
				for _, entName in ipairs(killMovableEnts) do
					if ent:GetClass() == entName then canSetKillMovable = true end
				end
				
				if canSetKillMovable then
					if math.random(1, 3) == 1 and IsValid(ent) and !ent.inKillMove and !ent.killMovable and ent:Health() <= GetConVar( "cqc_minhealth" ):GetInt() and ent:Health() > 0 and GetConVar( "cqc_enabled" ):GetInt() == 0 then
						ent:SetKillMovable(true)
						
						--[[if attacker:IsPlayer() then
							attacker:ShowHint("When something is highlighted blue, they can be KillMoved by using the KillMove key", 0, 10)
						end]]
					end
				end
			end)
		end
	end)
	
	function PlayRandomSound(ent, min, max, snd)
		local rand = math.random(min, max)
		
		ent:EmitSound("" .. snd .. rand .. ".wav", 100, 100, 0.5, CHAN_AUTO )
	end
	
	function entmeta:GetHeadBone()
		return self:LookupBone("ValveBiped.Bip01_Head1") or self:LookupBone("ValveBiped.HC_Body_Bone") or self:LookupBone("ValveBiped.HC_BodyCube") or self:LookupBone("ValveBiped.Headcrab_Cube1")
	end
	
	function plymeta:DoKMEffects(animName, plyModel, targetModel)
		
		local headBone = nil
		
		if IsValid (targetModel) then headBone = targetModel:GetHeadBone() end
		
		if animName == "killmove_front_1" then
			timer.Simple(0.3, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 5, "player/killmove/km_hit")
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
			timer.Simple(0.8, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 1, "player/killmove/km_punch")
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		elseif animName == "killmove_front_2" then
			timer.Simple(0.25, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 5, "player/killmove/km_hit")
			end)
			
			timer.Simple(0.45, function()
				if !IsValid(targetModel) then return end
				
				if plyModel:LookupBone("ValveBiped.Bip01_R_Foot") then
					local effectdata = EffectData()
					effectdata:SetOrigin(plyModel:GetBonePosition(plyModel:LookupBone("ValveBiped.Bip01_R_Foot")))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
			timer.Simple(1, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 2, "player/killmove/km_gorehit")
			end)
			
			timer.Simple(1.1, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		elseif animName == "killmove_hunter_front_1" then
			
			timer.Simple(0.5, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 1, "player/killmove/km_grapple")
			end)
			
			timer.Simple(1.3, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 3, "player/killmove/km_stabin")
				PlayRandomSound(self, 1, 2, "player/killmove/km_gorehit")
				PlayRandomSound(self, 1, 2, "npc/ministrider/hunter_foundenemy")
			end)
			
			timer.Simple(2, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 2, "player/killmove/km_stabout")
			end)
		elseif animName == "killmove_front_air_1" then
			timer.Simple(0.25, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 5, "player/killmove/km_hit")
			end)
			
			timer.Simple(1, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 2, "player/killmove/km_gorehit")
			end)
			
			timer.Simple(1.25, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		elseif animName == "killmove_left_1" then
			timer.Simple(0.3, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 1, "player/killmove/km_punch")
			end)
			
			timer.Simple(0.325, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(plyModel:GetBonePosition(plyModel:LookupBone("ValveBiped.Bip01_R_Foot")))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
			timer.Simple(1, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 2, "player/killmove/km_gorehit")
			end)
			
			timer.Simple(1.15, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		elseif animName == "killmove_right_1" then
			timer.Simple(0.2, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 5, "player/killmove/km_hit")
			end)
			
			timer.Simple(0.35, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
			timer.Simple(0.8, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 1, "player/killmove/km_punch")
			end)
			
			timer.Simple(1.0, function()
				if !IsValid(targetModel) then return end
				
				if headBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(headBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
		elseif animName == "killmove_back_1" then
			timer.Simple(0.5, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(self, 1, 3, "player/killmove/km_bonebreak")
			end)
		end
		
		hook.Run("CustomKMEffects", self, animName, targetModel)
	end
	
	function KMCheck(ply)
		if (ply.CQCDelayTime) then

		if ply.inKillMove then return end
		
		local tr = util.TraceLine( {
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
			filter = ply
		} )
		
		if !IsValid(tr.Entity) then
			tr = util.TraceHull( {
				start = ply:EyePos(),
				endpos = ply:EyePos() + ply:EyeAngles():Forward() * 100,
				filter = ply,
				mins = Vector( -1, -1, -1 ),
				maxs = Vector( 1, 1, 1 ),
			} )
		end
		
		if !IsValid(tr.Entity) then return end
		
		local target = tr.Entity
		
		if !target:IsPlayer() and !target:IsNPC() and !target:IsNextBot() then return end
		
		if ply.inKillMove or ply:Health() <= 0 or target.inKillMove or target == ply then return end
		
		--end of return checks
		
		local vec = ( ply:GetPos() - target:GetPos() ):GetNormal():Angle().y
		local targetAngle = target:EyeAngles().y
		
		if targetAngle > 360 then
			targetAngle = targetAngle - 360
		end
		if targetAngle < 0 then
			targetAngle = targetAngle + 360
		end
		
		local angleAround = vec - targetAngle
		
		if angleAround > 360 then
			angleAround = angleAround - 360
		end
		if angleAround < 0 then
			angleAround = angleAround + 360
		end

		-- If the player doesnt have cqc ex, then he is not allowed to perform cqc unless the health is below the min health (disabled by default)

		if !ply:HasEquipmentItem(EQUIP_CQC_EX) and target:Health() > GetConVar("cqc_minhealth"):GetInt() then 
			if GetConVar( "cqc_anytime_behind" ):GetInt() == 0 then 
				if !target.killMovable then
					return 
				end
			elseif !target.killMovable and !(angleAround > 135 and angleAround <= 225) then
				return
			end
		end

		-- Same as above but for CQC EX incase people believe its too broken that EX can perform a throw at full health

		if ply:HasEquipmentItem(EQUIP_CQC_EX) and target:Health() > GetConVar("cqc_minhealth_ex"):GetInt() then 
			if GetConVar( "cqc_anytime_behind_ex" ):GetInt() == 0 then 
				if !target.killMovable then
					return 
				end
			elseif !target.killMovable and !(angleAround > 135 and angleAround <= 225) then
				return
			end
		end
		
		--print ("target eye angles", targetAngle, "angle to target", vec, "the sum thing", angleAround)
		
		local plyKMModel = ""
		local targetKMModel = ""
		local animName = ""
		local plyKMPosition = target:GetPos() + (target:GetForward() * 40 )
		local plyKMAngle = nil
		local plyKMTime = nil
		local targetKMTime = nil
		
		--Custom killmove hook
		local customKMData = hook.Run("CustomKillMoves", ply, target, angleAround)
		
		if customKMData then
			if customKMData[1] != nil then plyKMModel = customKMData[1] end
			if customKMData[2] != nil then targetKMModel = customKMData[2] end
			if customKMData[3] != nil then animName = customKMData[3] end
			if customKMData[4] != nil then plyKMPosition = customKMData[4] end
			if customKMData[5] != nil then plyKMAngle = customKMData[5] end
			if customKMData[6] != nil then plyKMTime = customKMData[6] end
			if customKMData[7] != nil then targetKMTime = customKMData[7] end
		end
		
		--Default killmoves
		if animName == "" and GetConVar( "cqc_bsmod_killmove_disable_default" ):GetInt() == 0 then
			plyKMModel = "models/weapons/c_limbs.mdl"
			
			if target:LookupBone("ValveBiped.Bip01_Spine") then
				targetKMModel = "models/bsmodimations_human.mdl"
				
				if angleAround <= 45 or angleAround > 315 then
					if ply:OnGround() then
						--if ply:EyeAngles().x <= 30 then]]
							animName = "killmove_front_" .. math.random(1, 2)
						--end
						
						if animName == "killmove_front_1" then targetKMTime = 1.15 end
					else
						animName = "killmove_front_air_1"
					end
				end
				
				if angleAround > 45 and angleAround <= 135 then
					animName = "killmove_left_1"
				end
				
				if angleAround > 135 and angleAround <= 225 then
					animName = "killmove_back_1"
				end
				
				if angleAround > 225 and angleAround <= 315 then
					animName = "killmove_right_1"
				end
			elseif target:LookupBone("MiniStrider.body_joint") then
				targetKMModel = "models/bsmodimations_hunter.mdl"
				
				animName = "killmove_hunter_front_1"
			end
			
			if animName == "killmove_left_1" then
				plyKMPosition = target:GetPos() + (-target:GetRight() * 31.5 )
			elseif animName == "killmove_right_1" then
				plyKMPosition = target:GetPos() + (target:GetRight() * 95) + (target:GetForward() * 10)
				plyKMAngle = (-target:GetRight()):Angle()
			elseif animName == "killmove_back_1" then
				plyKMPosition = target:GetPos() + (-target:GetForward() * 30 )
			elseif animName == "killmove_front_1" then
				plyKMPosition = target:GetPos() + (target:GetForward() * 31.5 )
			elseif animName == "killmove_front_2" then
				plyKMPosition = target:GetPos() + (target:GetForward() * 29 )
			elseif animName == "killmove_front_air_1" then
				plyKMPosition = target:GetPos() + (target:GetForward() * 39 )
			elseif animName == "killmove_hunter_front_1" then
				plyKMPosition = target:GetPos() + (target:GetForward() * 31.5 )
			end
		end
		
		ply:KillMove(target, animName, plyKMModel, targetKMModel, plyKMPosition, plyKMAngle, plyKMTime, targetKMTime)
	else
		if(timer.Exists("plyCQCDelay")) then
			local time = math.floor(timer.TimeLeft("plyCQCDelay"))
			local chatmsg = "CQC is on Cooldown! Time remaining: " .. time
			ply:ChatPrint(chatmsg)
		end
		
	end
	end

	
	concommand.Add("cqc_throw", KMCheck)
	
	--Now this function has a lot of arguments but that's cuz custom killmoves will use them
	function plymeta:KillMove(target, animName, plyKMModel, targetKMModel, plyKMPosition, plyKMAngle, plyKMTime, targetKMTime)
		if plyKMModel == "" or targetKMModel == "" or animName == "" then return end
		
		if self.inKillMove or self:Health() <= 0 or !IsValid(target) or target.inKillMove or target == self then return end
		
		--End of return checks
		
		net.Start("debugbsmodcalcview")
		net.Broadcast()
		
		self.inKillMove = true
		
		self:SetPos(plyKMPosition)
		
		self:SetAngles((Vector (target:GetPos().x, target:GetPos().y, 0) - Vector (self:GetPos().x, self:GetPos().y, 0)):Angle())
		self:SetEyeAngles((Vector (target:GetPos().x, target:GetPos().y, 0) - Vector (self:GetPos().x, self:GetPos().y, 0)):Angle())
		
		if plyKMAngle != nil then
			self:SetAngles(plyKMAngle)
			self:SetEyeAngles(plyKMAngle)
		end
		
		local prevWeapon = nil
		local prevGodMode = self:HasGodMode()
		local prevMaterial = self:GetMaterial()
		
		if IsValid(self:GetActiveWeapon()) then
			prevWeapon = self:GetActiveWeapon()
		end
		
		if self.killMovable then self:SetKillMovable(false) end
		
		self:Lock()
		self:SetVelocity(-self:GetVelocity())
		self:SetMaterial("null")
		self:DrawShadow( false )
		
		net.Start("removedecals")
		net.WriteEntity(self)
		net.Broadcast()
		
		--Spawn the players animName model
		
		if IsValid(self.kmAnim) then self.kmAnim:Remove() end
		
		self.kmAnim = ents.Create("ent_km_model")
		self.kmAnim:SetPos(self:GetPos())
		self.kmAnim:SetAngles(self:GetAngles())
		self.kmAnim:SetModel(plyKMModel)
		self.kmAnim:SetOwner(self)
		
		self.kmAnim:ResetSequence( animName )
		self.kmAnim:ResetSequenceInfo()
		self.kmAnim:SetCycle(0)
		
		for i = 0, self:GetBoneCount() - 1 do 
			 local bone = self.kmAnim:LookupBone(self:GetBoneName(i))
			if bone then
				self.kmAnim:ManipulateBonePosition(bone, self:GetManipulateBonePosition(i))
				self.kmAnim:ManipulateBoneAngles(bone, self:GetManipulateBoneAngles(i))
				self.kmAnim:ManipulateBoneScale(bone, self:GetManipulateBoneScale(i))
			end
		end
		
		self.kmAnim:SetModelScale(self:GetModelScale())
		
		self.kmAnim:Spawn()
		
		if plyKMTime == nil then plyKMTime = self.kmAnim:SequenceDuration() end
		
		--Spawn the players playermodel
		
		if IsValid(self.kmModel) then self.kmModel:Remove() end
		
		self.kmModel = ents.Create("ent_km_model")
		self.kmModel:SetPos(self:GetPos())
		self.kmModel:SetAngles(self:GetAngles())
		self.kmModel:SetModel(self:GetModel())
		self.kmModel:SetSkin(self:GetSkin())
		self.kmModel:SetColor(self:GetColor())
		self.kmModel:SetMaterial(prevMaterial)
		self.kmModel:SetRenderMode(self:GetRenderMode())
		self.kmModel:SetOwner(self)
		
		if IsValid(self:GetActiveWeapon()) then self.kmModel.Weapon = self:GetActiveWeapon() end
		
		for i, bodygroup in pairs(self:GetBodyGroups()) do
			self.kmModel:SetBodygroup(bodygroup.id, self:GetBodygroup(bodygroup.id))
		end
		
		for i, ent in ipairs(self:GetChildren()) do 
			ent:SetParent(self, ent:GetParentAttachment()) 
			ent:SetLocalPos(vector_origin)
			ent:SetLocalAngles(angle_zero)
		end 
		
		self.kmModel.maxKMTime = plyKMTime
		self.kmModel:Spawn()
		
		self.kmModel:AddEffects(EF_BONEMERGE)
		self.kmModel:SetParent(self.kmAnim)
		
		if IsValid(self:GetActiveWeapon()) then
			if self:GetActiveWeapon():GetClass() != "weapon_bsmod_punch" then
				self:SelectWeapon("weapon_bsmod_killmove")
			end
		end
		
		------------------------------------------------------------------------------------------
		
		local prevTMaterial = target:GetMaterial()
		
		target:SetKillMovable(false)
		target.inKillMove = true
		
		if target:IsPlayer() then
			target:SetMaterial("null")
		else
			target:SetNoDraw(true)
		end
		
		target:DrawShadow( false )
		
		net.Start("removedecals")
		net.WriteEntity(target)
		net.Broadcast()
		
		if target:IsNPC() then
			target:SetCondition(67)
			target:SetNPCState(NPC_STATE_NONE)
		elseif target:IsPlayer() then
			--target:DrawWorldModel(false)
			--target:StripWeapons()
			target:Lock()
			self:SetVelocity(-self:GetVelocity())
		end
		
		--Now for the targets animName model
		
		if IsValid(target.kmAnim) then target.kmAnim:Remove() end
		
		target.kmAnim = ents.Create("ent_km_model")
		target.kmAnim:SetPos(target:GetPos())
		target.kmAnim:SetAngles(target:GetAngles())
		target.kmAnim:SetModel(targetKMModel)
		target.kmAnim:SetOwner(target)
		
		target.kmAnim:ResetSequence( animName )
		target.kmAnim:ResetSequenceInfo()
		target.kmAnim:SetCycle(0)
		
		for i = 0, target:GetBoneCount() - 1 do 
			 local bone = target.kmAnim:LookupBone(target:GetBoneName(i))
			if bone then
				target.kmAnim:ManipulateBonePosition(bone, target:GetManipulateBonePosition(i))
				target.kmAnim:ManipulateBoneAngles(bone, target:GetManipulateBoneAngles(i))
				target.kmAnim:ManipulateBoneScale(bone, target:GetManipulateBoneScale(i))
			end
		end
		
		target.kmAnim:SetModelScale(target:GetModelScale())
		
		target.kmAnim:Spawn()
		
		if targetKMTime == nil then targetKMTime = target.kmAnim:SequenceDuration() end
		
		--And the targets playermodel
		
		if IsValid(target.kmModel) then target.kmModel:Remove() end
		
		target.kmModel = ents.Create("ent_km_model")
		target.kmModel:SetPos(target:GetPos())
		target.kmModel:SetAngles(target:GetAngles())
		target.kmModel:SetModel(target:GetModel())
		target.kmModel:SetSkin(target:GetSkin())
		target.kmModel:SetColor(target:GetColor())
		target.kmModel:SetMaterial(prevTMaterial)
		target.kmModel:SetRenderMode(target:GetRenderMode())
		target.kmModel:SetOwner(target)
		
		if !target:IsNextBot() then if IsValid(target:GetActiveWeapon()) then target.kmModel.Weapon = target:GetActiveWeapon() end end
		
		for i, bodygroup in ipairs(target:GetBodyGroups()) do
			target.kmModel:SetBodygroup(bodygroup.id, target:GetBodygroup(bodygroup.id))
		end
		
		for i, ent in ipairs(target:GetChildren()) do 
			ent:SetParent(target.kmModel, ent:GetParentAttachment()) 
			ent:SetLocalPos(vector_origin)
			ent:SetLocalAngles(angle_zero)
		end 
		
		target.kmModel:Spawn()
		
		target.kmModel:AddEffects(EF_BONEMERGE)
		target.kmModel:SetParent(target.kmAnim)
		
		self:DoKMEffects(animName, self.kmModel, target.kmModel)
		
		--Now for the timers
		
		timer.Simple(targetKMTime, function()
			if IsValid(target) then
				
				target.kmAnim.AutomaticFrameAdvance = false
				
				timer.Simple(0.075, function()
					if IsValid(target) then
						if IsValid(target.kmModel) then target.kmModel:SetNoDraw(true) end
						
						if IsValid(target.kmModel) then
							local bonePos, boneAng = nil
							
							bonePos, boneAng = target.kmModel:GetBonePosition(0)
							
							target:SetPos(Vector(bonePos.x, bonePos.y, target:GetPos().z))
							--target:SetAngles(Angle(0, boneAng.y, 0))
						end
						
						target:DrawShadow( true )
						
						if target:IsPlayer() then
							target:SetMaterial(prevTMaterial)
						else
							target:SetNoDraw(false)
						end
						
						target.inKillMove = false
						
						if target:IsPlayer() then
							--target:DrawWorldModel(true)
							target:UnLock()
							-- Here is the code where the player gets stunned
							if(GetConVar( "cqc_lethal" ):GetInt() >= 1) then
								target:SetHealth(0)
							
								local dmginfo = DamageInfo()
								
								dmginfo:SetAttacker( self )
								dmginfo:SetDamageType( DMG_GENERIC )
								dmginfo:SetDamage( 1 )
								
								target:TakeDamageInfo( dmginfo )
							else
								target.CQCTime = 0
							end
							
						elseif target:IsNPC() or target:IsNextBot() then
							target:SetHealth(0)
							
							local dmginfo = DamageInfo()
							
							dmginfo:SetAttacker( self )
							dmginfo:SetDamageType( DMG_SLASH )
							dmginfo:SetDamage( 1 )
							
							target:TakeDamageInfo( dmginfo )
						end
						
						if IsValid(target.kmModel) then 
							for i, ent in ipairs(target.kmModel:GetChildren()) do 
								ent:SetParent(target, ent:GetParentAttachment()) 
								ent:SetLocalPos(vector_origin)
								ent:SetLocalAngles(angle_zero)
							end 
							
							target.kmModel:RemoveDelay(2)
						end
						if IsValid(target.kmAnim) then target.kmAnim:RemoveDelay(2) end
					end
				end )
			end
		end )
		
		timer.Simple(plyKMTime, function()
			if IsValid(self) then
				
				self.kmAnim.AutomaticFrameAdvance = false
				
				timer.Simple(0.075, function()
					if IsValid(self) then
						if IsValid(self.kmAnim) then
							local headBone = self.kmAnim:GetAttachment(self.kmAnim:LookupAttachment( "eyes" ))
							self:SetPos(Vector(headBone.Pos.x, headBone.Pos.y, headBone.Pos.z + (self:GetPos().z - self:EyePos().z)))
							self:SetEyeAngles(Angle(headBone.Ang.x, headBone.Ang.y, 0))
						end
						
						self:DrawShadow( true )
						
						if self:IsPlayer() then
							self:SetMaterial(prevMaterial)
						else
							self:SetNoDraw(false)
						end
						
						self:DrawWorldModel(true)
						
						if IsValid(prevWeapon) then
							if prevWeapon:GetClass() != "weapon_bsmod_punch" then
								self:StripWeapon("weapon_bsmod_killmove")
							end
							
							self:SelectWeapon(prevWeapon)
						end
						
						self:SetMoveType(MOVETYPE_WALK)
						self:UnLock()
						
						if IsValid(self.kmModel) then 
							for i, ent in ipairs(self.kmModel:GetChildren()) do 
								ent:SetParent(self, ent:GetParentAttachment()) 
								ent:SetLocalPos(vector_origin)
								ent:SetLocalAngles(angle_zero)
							end 
							
							self.kmModel:Remove() 
						end
						if IsValid(self.kmAnim) then self.kmAnim:Remove() end
						
						if prevGodMode then
							self:GodEnable(true)
						end
						
						self.inKillMove = false
					end
				end )
			end
		end	)

		self.CQCDelayTime = false

		if(!timer.Exists( "plyCQCDelay" )) then
			timer.Create("plyCQCDelay", GetConVar("cqc_delay"):GetInt(), 1, function()
				self.CQCDelayTime = true 
				self:ChatPrint("CQC Available!")
			end)
		else
			timer.Start( "plyCQCDelay" )
		end
	end
end

if CLIENT then

	------------------------------ Tranq Code Below -----------------------------------

	net.Receive( "TranqRagdoll", function()
		local pl = net.ReadEntity()
		local ragdoll = net.ReadEntity()
		
		if ( IsValid( pl ) and IsValid( ragdoll ) ) then
			pl.CQCRagdoll = ragdoll
			
			function ragdoll:GetPlayerColor()
				return pl:GetPlayerColor()
			end
		end
	end )
	
	local star = Material( "sprites/glow04_noz" )
	hook.Add( "PostDrawOpaqueRenderables", "DrawTranqStars", function()
		for _, pl in ipairs( player.GetAll() ) do
			local ragdoll = pl.CQCRagdoll
			
			if ( IsValid( ragdoll ) ) then
				local attach = ragdoll:GetAttachment( ragdoll:LookupAttachment( "eyes" ) )
				
				if ( attach ) then
					local stars = 3
					
					for i = 1, stars do
						local time = CurTime() * 3 + ( math.pi * 2 / stars * i )
						local offset = Vector( math.sin( time ) * 5, math.cos( time ) * 5, 10 )
						
						render.SetMaterial( star )
						render.DrawSprite( attach.Pos + offset, 8, 8, Color( 220, 220, 0 ) )
					end
				end
			end
		end
	end )

	------------------------------ BSMOD Code below -----------------------------------
	
	--[[concommand.Add("bsmod_reset_camerasettings", ResetBSModCamSettings, nil, "Reset Thirdperson KillMove Camera Settings.")
	
	function ResetBSModCamSettings()
		GetConVar( "bsmod_killmove_thirdperson_distance" ):Revert()
		GetConVar( "bsmod_killmove_thirdperson_pitch" ):Revert()
		GetConVar( "bsmod_killmove_thirdperson_yaw" ):Revert()
		GetConVar( "bsmod_killmove_thirdperson_offsetup" ):Revert()
		GetConVar( "bsmod_killmove_thirdperson_offsetright" ):Revert()
	end]]
	
	net.Receive("setkillmovable", function()
		net.ReadEntity().killMovable = net.ReadBool()
	end)
	
	net.Receive("removedecals", function()
		net.ReadEntity():RemoveAllDecals()
	end)
	
	net.Receive("debugbsmodcalcview", function()
		if GetConVar( "cqc_debug_calcview" ):GetInt() != 0 then
			PrintTable(hook.GetTable()["CalcView"])
		end
	end)
	
	--[[net.Receive("showhint", function()
		if GetConVar( "bsmod_enable_hints" ):GetInt() == 0 then return end
		
		notification.AddLegacy( net.ReadString(), net.ReadInt(4), net.ReadFloat() )
		
		surface.PlaySound( "ambient/water/drip" .. math.random( 1, 4 ) .. ".wav" )
	end)]]
	
	hook.Add("HUDShouldDraw", "BSModHUDShouldDraw", function(name)
		if IsValid(LocalPlayer().kmviewentity) and !LocalPlayer().kmviewentity:GetNoDraw() then
			if name == "CHudWeaponSelection" then return false end
		end
	end)
	
	hook.Add("HUDWeaponPickedUp", "HideKMWeaponNotify", function(weapon)
		if weapon:GetClass() == "weapon_bsmod_killmove" then return false end
	end)
	
	hook.Add( "CreateClientsideRagdoll", "BSModCreateClientsideRagdoll", function(entity, ragdoll)
		if entity:LookupBone("MiniStrider.body_joint") or !IsValid(entity.kmviewentity) or !IsValid(entity) or !IsValid(ragdoll) then return end
		
		ragdoll:SetMaterial("null")
		ragdoll:RemoveAllDecals()
		
		timer.Simple(0, function()
			if entity:LookupBone("MiniStrider.body_joint") or !IsValid(entity.kmviewentity) or !IsValid(entity) or !IsValid(ragdoll) then return end
			
			local ent = ragdoll
			ragdoll:SetMaterial(entity:GetMaterial())
			for i = 1, ent:GetPhysicsObjectCount() do
				local bone = ent:GetPhysicsObjectNum(i)
				
				local targetEnt = entity.kmviewentity
				
				if !IsValid(targetEnt) then return end
				
				if bone and bone:IsValid() then
					local bonename = ent:GetBoneName(i)
					
					if !IsValid(targetEnt) then return end
					
					local plybone = targetEnt:LookupBone(bonename)
					
					if plybone then
						local bonepos, boneang = targetEnt:GetBonePosition(ent:TranslatePhysBoneToBone(plybone))
						
						bone:SetPos(bonepos, true)
						bone:SetAngles(boneang)
						bone:SetVelocity(vector_origin)
						
						bone:EnableMotion( false )
						
						timer.Simple(0.05, function()
							if !IsValid(bone) then return end
							
							bone:EnableMotion( true )
							
							bone:SetPos(bonepos, true)
							bone:SetAngles(boneang)
							bone:SetVelocity(vector_origin)
						end)
					end
				end
			end
			timer.Simple(0.075, function()
				if !IsValid(entity.kmviewanim) then return end
				
				hook.Run("KMRagdoll", entity, ragdoll, entity.kmviewanim:GetSequenceName(entity.kmviewanim:GetSequence()))
			end)
		end)
	end)
	
	hook.Add( "CalcView", "BSModCalcView", function(ply, pos, angles, fov)
		if IsValid(ply.kmviewentity) and !ply.kmviewentity:GetNoDraw() and ply:GetViewEntity() == ply then
			local KMOrigin = pos
			local KMAngles = angles
			
			KMOrigin = ply.kmviewentity:GetAttachment(ply.kmviewentity:LookupAttachment( "eyes" )).Pos
			KMAngles = ply.kmviewentity:GetAttachment(ply.kmviewentity:LookupAttachment( "eyes" )).Ang
			
			local view = {
				origin = KMOrigin,
				angles = KMAngles,
				drawviewer = true
			}
			
			return view
		end
	end)
end

hook.Add( "KMRagdoll", "BSModKMRagdoll", function(entity, ragdoll, animName)
	
	local spinePos, spineAng = nil
	
	if ragdoll:LookupBone("ValveBiped.Bip01_Spine") then 
		spinePos, spineAng = ragdoll:GetBonePosition(ragdoll:LookupBone("ValveBiped.Bip01_Spine"))
	end
	
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum(i)
		
		if bone and bone:IsValid() then
			--local bonepos, boneang = ragdoll:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
			
			if animName == "killmove_front_1" then
				if spineAng != nil then
					bone:SetVelocity(spineAng:Forward() * 150)
					bone:SetAngleVelocity(bone:WorldToLocalVector(-spineAng:Forward() * 2500))
				end
			elseif animName == "killmove_right_1" then
				bone:SetVelocity(Vector(0, 0, -1) * 50)
				bone:SetAngleVelocity(bone:WorldToLocalVector(-spineAng:Forward() * 1000))
			elseif animName == "killmove_back_1" then
				bone:SetVelocity((-spineAng:Right() * 125) + (-spineAng:Up() * 40))
			end
			
		end
	end
end)