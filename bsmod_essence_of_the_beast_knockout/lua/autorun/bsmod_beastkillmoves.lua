--IMPORTANT: Make sure this is the only custom killmove lua file for your addon since having multiple can cause conflicts and issues

if SERVER then

	local function isSolid(ent)
		return (  not ent:IsNPC() && not ent:IsPlayer() && (ent:GetCollisionGroup() != 20 || ent:IsWorld()) )
	end

	local function perm(n)
		local res = {}
		for i = 1, n do
			res[i] = i
		end
		for i = n, 2, -1 do
			local j = math.random(1, i)
			res[j], res[i] = res[i], res[j]
		end
		return res
	end

	local function hasWall(pos, fwd)
		local walldist = 100
		local tr = {
			start = pos,
			endpos = pos - fwd * walldist,
			filter = function( ent ) return isSolid(ent) end
		}
		local td = util.TraceLine(tr)
		if (td.Hit) then
			return td.HitPos, td.HitNormal
		else
			return nil
		end
	end

	local function isStuck(pos)
		local tr = {
			start = pos,
			endpos = pos,
			mins = Vector( -16, -16, 0 ),
			maxs = Vector( 16, 16, 71 ),
			filter = function( ent ) return isSolid(ent) end
		}

		local hullTrace = util.TraceHull(tr)
		return hullTrace.Hit;
	end


	--This adds to a list of entities that can be killmovable (highlighted blue) when taking damage
	--ValveBipeds by default are on this list so use this only for entities with different bone structures such as headcrabs
	--Make sure the entity you're checking for in the killmove function below is added to this list, you can add as many as you want
	timer.Simple(0, function()
		if killMovableEnts then

			--These are commented out because we won't be using them in this example, feel free to uncomment them if you want to add more non ValveBiped npcs to be killmovable

			--[[if !table.HasValue(killMovableEnts, "npc_strider") then
				table.insert( killMovableEnts, "npc_strider" )
			end
			if !table.HasValue(killMovableEnts, "npc_headcrab") then
				table.insert( killMovableEnts, "npc_headcrab" )
			end]]
		end
	end)

	hook.Add("CustomKillMoves", "EssenceOfTheBeast", function(ply, target, angleAround)
	
		--Setup some values for custom killmove data
		local plyKMModel = nil
		local targetKMModel = nil
		local animName = nil
		local plyKMPosition = nil
		local plyKMAngle = nil

		local knockoutThrowChance = math.Round(GetConVar("bsmod_beast_knockoutthrow"):GetFloat())
		local electricPanelChance = math.Round(GetConVar("bsmod_beast_electricpanel"):GetFloat())
		local pileDiveChance = math.Round(GetConVar("bsmod_beast_piledive"):GetFloat())
		local heavyHitChance = math.Round(GetConVar("bsmod_beast_heavyhit"):GetFloat())
		local wallPinChance = math.Round(GetConVar("bsmod_beast_wallpin"):GetFloat())

		local kmData = {1, 2, 3, 4, 5} --We'll use this at the end of the hook

		plyKMModel = "models/weapons/c_limbs_beasthact.mdl" --We set the Players killmove model to the custom one that has the animations

		--Use these checks for angle specific killmoves, make sure to keep the brackets when using them
		if (angleAround <= 45 or angleAround > 315) then
			--print("in front of target")
		elseif (angleAround > 45 and angleAround <= 135) then
			--print("left of target")
		elseif (angleAround > 135 and angleAround <= 225) then
			--print("behind target")
		elseif (angleAround > 225 and angleAround <= 315) then
			--print("right of target")
		end
	
		--No need to add if checks for tons of npcs when you can put target:LookupBone("bonename") in them, an example of this being used is below
	
		--This checks if the target is a Zombie, the Player is on the ground and that the Target model is a valvebiped one
		--It also has a chance to not happen as shown by the math.random, that way other killmoves can have a chance of happening
		if (target:LookupBone("ValveBiped.Bip01_Spine") and ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround > 135 and angleAround <= 225) and math.random(1, 10) <= knockoutThrowChance) then
	
			targetKMModel = "models/bsmodimations_beasthact.mdl" --Set the Targets killmove model
		
			animName = "killmove_beasthact_back" --Set the name of the animation that will play for both the Player and Target model

		elseif (target:LookupBone("ValveBiped.Bip01_Spine") and ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= electricPanelChance) then
			plyKMModel = "models/weapons/c_limbs_beast_panel.mdl" 

			targetKMModel = "models/bsmodimations_beasthact.mdl" --Set the Targets killmove model

			animName = "killmove_beasthact_panel" --Set the name of the animation that will play for both the Player and Target model

		elseif (target:LookupBone("ValveBiped.Bip01_Spine") and ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= pileDiveChance) then
			targetKMModel = "models/bsmodimations_beasthact.mdl" --Set the Targets killmove model
		
			animName = "killmove_beasthact_piledive" --Set the name of the animation that will play for both the Player and Target model

		elseif (target:LookupBone("ValveBiped.Bip01_Spine") and ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround > 45 and angleAround <= 135) and math.random(1, 10) <= heavyHitChance) then
			plyKMModel = "models/weapons/c_limbs_bycicle.mdl"

			targetKMModel = "models/bsmodimations_beasthact.mdl" --Set the Targets killmove model

			animName = "killmove_beasthact_heavyhit" --Set the name of the animation that will play for both the Player and Target model
		elseif (target:LookupBone("ValveBiped.Bip01_Spine") and ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= wallPinChance) then
			newpos = nil
			animcount = 1
			i = 0
			animperm = perm(animcount)
			halfobb = Vector(0, 0, target:OBBMaxs().z*0.5)
			hpos, hnormal = hasWall(target:GetPos() + halfobb, (ply:GetPos() - target:GetPos()):GetNormalized())
			if (hpos && math.abs(hnormal.z) < 0.1) then
			repeat
				if animperm[i + 1] == 1 then
					local rotplyfwd = ply:GetForward()
					rotplyfwd:Rotate(Angle(0, 90, 0))
					newpos = (hpos - halfobb) + hnormal * 23.839 - rotplyfwd * 20
				end
				i = i + 1
				until (i > animcount) || (not isStuck(newpos))
			end
			if newpos && (not isStuck(newpos)) then
				if animperm[i] == 1 then
					plyKMModel = "models/weapons/c_limbs_bycicle.mdl"
					targetKMModel = "models/bsmodimations_beasthact.mdl"
					animName = "killmove_beasthact_wallpin"
					local phi = hnormal:Angle().yaw
					target:SetPos((hpos - halfobb) + hnormal * 50)
					ply:SetAngles(Angle(0, phi + 180, 0))
				end
			end
		end
	
		--Positioning the Player for different killmove animations
		if animName == "killmove_beasthact_back" then
			plyKMPosition = target:GetPos() + (target:GetForward() * -45) + (target:GetUp() * 5) --Position the player in front of the Target and x distance away
		end

		if animName == "killmove_beasthact_piledive" then
			plyKMAngle = target:GetForward():Angle()
			plyKMPosition = target:GetPos() + (target:GetForward() * 20)
		end

			--Positioning the Player for different killmove animations
		if animName == "killmove_beasthact_panel" then
			plyKMAngle = target:GetForward():Angle()
			plyKMPosition = target:GetPos() + (target:GetForward() * 95) + (target:GetUp() * 5)
		end

		if animName == "killmove_beasthact_heavyhit" then
			plyKMAngle = target:GetForward():Angle()
			plyKMPosition = target:GetPos() + (target:GetForward() * 95) + (target:GetUp() * 5) + (target:GetRight() * 20)
		end

		if animName == "killmove_beasthact_wallpin" then
			plyKMAngle = target:GetForward():Angle()
			plyKMPosition = target:GetPos() + (target:GetForward() * 75) + (target:GetUp() * 5) + (target:GetRight() * 20)
		end

		--IMPORTANT: Make sure not to duplicate the rest of the code below, it isn't nessecary and can cause issues, just keep them at the bottom of this function
		kmData[1] = plyKMModel
		kmData[2] = targetKMModel
		kmData[3] = animName
		kmData[4] = plyKMPosition
		kmData[5] = plyKMAngle

		if animName != nil then return kmData end --Send the killmove data to the main addons killmove check function
	end)


end

--This is the hook for custom killmove effects and sounds

hook.Add("CustomKMEffects", "EssenceOfTheBeast", function(ply, animName, targetModel)
	
	local targetHeadBone = nil
		
	if IsValid (targetModel) then targetHeadBone = targetModel:GetHeadBone() end
	
	if animName == "killmove_beasthact_back" then --Check the killmove animation names
		
		--Set a timer for effects, you can add more timers for more sounds
		
		timer.Simple(0.8 --[[delay]], function()
			if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
			
			--This function will play random sounds. for example: here are 2 sound files killmovesound1 and killmovesound2, using this function with min being 1 and max being 2, it will choose a random one of those between that range to play.
			
			PlayRandomSound(ply, 1 --[[min]], 3 --[[max]], "player/fists/fists_miss0" --[[path to the sound]])
			
			if targetHeadBone != nil then
				
				--This will emit a blood effect at the target's head bone
				
				local effectdata = EffectData()
				effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
				
				--You can also specify which bone you want the effect to be positioned to
				--effectdata:SetOrigin(targetModel:GetBonePosition(targetModel:LookupBone("ValveBiped.Bip01_Spine")))
				
				util.Effect("BloodImpact", effectdata)
			end
		end)
		
		--Repeat the same for different animations
		
	elseif animName == "killmove_beasthact_panel" then
		timer.Simple(6.5, function()
			if !IsValid(targetModel) then return end
			
			PlayRandomSound(ply, 1, 3, "player/killmove/km_bonebreak")
			
			if targetHeadBone != nil then
				local effectdata = EffectData()
				effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
				util.Effect("BloodImpact", effectdata)
			end
		end)

		timer.Simple(1.5, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 3, "player/fists/fists_miss0")
		end)

	elseif animName == "killmove_beasthact_piledive" then

		if !IsValid(targetModel) then return end

		PlayRandomSound(ply, 1, 3, "player/fists/fists_miss0")

		timer.Simple(4.8, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 3, "player/killmove/km_bonebreak")
		end)

	elseif animName == "killmove_beasthact_heavyhit" then
		timer.Simple(1, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
		end)

		timer.Simple(3.8, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 3, "player/killmove/km_bonebreak")
		end)

	elseif animName == "killmove_beasthact_wallpin" then
		timer.Simple(0.5, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 3, "player/fists/fists_miss0")
		end)

		timer.Simple(1, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
		end)

		timer.Simple(3.8, function()
			if !IsValid(targetModel) then return end

			PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
		end)
	end

end)

hook.Add( "KMRagdoll", "EssenceOfTheBeast", function(entity, ragdoll, animName)
	
	--Define the position and angles of a bone, we'll talk about this further down
	local spinePos, spineAng = nil

	local knockoutThrowForce = math.Round(GetConVar("bsmod_beast_knockoutthrow_force"):GetFloat())
	
	if ragdoll:LookupBone("ValveBiped.Bip01_Spine") then 
		spinePos, spineAng = ragdoll:GetBonePosition(ragdoll:LookupBone("ValveBiped.Bip01_Spine"))
	end
	
	--Loop through all of the ragdoll's bones that have a physics mesh attached, this will basically move the entire ragdoll
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum(i)
		
		if bone and bone:IsValid() then
			
			--We won't be needing this but if you do then feel free to uncomment it
			--local bonepos, boneang = ragdoll:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
			
			if animName == "killmove_beasthact_back" then
				if spineAng != nil then
					--Set the ragdoll's velocity to move to the east direction of the spine bone (it's -spineAng:Up because source engine bones are weird)
					--if you dont get the right direction then mess around with it by using spineAng:Up, spineAng:Forward or spineAng:Right. use a minus symbol(-) before it for the opposite direction
					bone:SetVelocity((spineAng:Forward() * knockoutThrowForce))
				end
			end
		end
	end
	
	--You can also rotate the ragdoll by changing it's angular velocity, here's an example below
	
	--bone:SetAngleVelocity(bone:WorldToLocalVector(-spineAng:Forward() * 2500))
	
	--This basically makes the ragdoll spin like a torpedo, it's -spineAng:Forward() because again source engine bones are weird but it basically means the up direction of it
end)