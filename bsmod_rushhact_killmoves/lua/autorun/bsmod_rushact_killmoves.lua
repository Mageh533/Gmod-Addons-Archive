--IMPORTANT: Make sure this is the only custom killmove lua file for your addon since having multiple can cause conflicts and issues

--This makes sure the functions in this if statement are only ran on the server since they aren't needed on the client
if SERVER then

	--Detect if there is a wall behind for the other killmove

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

	--This is the hook for custom killmoves
	--IMPORTANT: Make sure to change the UniqueName to something else to avoid conflicts with other custom killmove addons
	hook.Add("CustomKillMoves", "RushHeatActions", function(ply, target, angleAround)
		local crushingChance = math.Round(GetConVar("bsmod_rush_crushing"):GetFloat())
		local barrageChance = math.Round(GetConVar("bsmod_rush_barrage"):GetFloat())
		local wallCrushingChance = math.Round(GetConVar("bsmod_rush_wallcrushing"):GetFloat())
		
		--Setup some values for custom killmove data
		local plyKMModel = nil
		local targetKMModel = nil
		local animName = nil
		local plyKMPosition = nil
		local plyKMAngle = nil
		
		local kmData = {1, 2, 3, 4, 5} --We'll use this at the end of the hook
		
		plyKMModel = "models/weapons/killmove_rushhact_player.mdl" --We set the Players killmove model to the custom one that has the animations
		
		--Use these checks for angle specific killmoves, make sure to keep the brackets when using them
		if (angleAround <= 45 or angleAround > 315) then
			--print("in front of target")
			plyKMAngle = target:GetAngles()
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
		if target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= wallCrushingChance then
			newpos = nil
			animcount = 1
			i = 0
			animperm = perm(animcount)
			halfobb = Vector(0, 0, ply:OBBMaxs().z*0.5)
			hpos, hnormal = hasWall(ply:GetPos() + halfobb, (target:GetPos() - ply:GetPos()):GetNormalized())
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
					animName = "killmove_rushhact_crushing_wall"
					targetKMModel = "models/killmove_rushhact_target.mdl"
					local phi = hnormal:Angle().yaw
					target:SetPos((hpos - halfobb) + hnormal * 90)
					target:SetAngles(Angle(0, phi + 180, 0))
				end
			end
		elseif target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= crushingChance then
			targetKMModel = "models/killmove_rushhact_target.mdl"

			animName = "killmove_rushhact_crushing"
		elseif target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= barrageChance then
			targetKMModel = "models/killmove_rushhact_target.mdl"

			animName = "killmove_rushhact_barrage"
		elseif target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and barrageChance == 10 and crushingChance == 10 then
			if math.random(1,2) == 1 then
				targetKMModel = "models/killmove_rushhact_target.mdl"

				animName = "killmove_rushhact_crushing"
			else
				targetKMModel = "models/killmove_rushhact_target.mdl"
			
				animName = "killmove_rushhact_barrage"
			end
		end

		

		--Positioning the Player for different killmove animations
		if animName == "killmove_rushhact_barrage" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 70 ) --Position the player in front of the Target and x distance away
		elseif animName == "killmove_rushhact_crushing" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 35 ) + (target:GetRight() * 5)
		elseif animName == "killmove_rushhact_crushing_wall" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 60 ) + (target:GetRight() * 5)
		end

		--IMPORTANT: Make sure not to duplicate the rest of the code below, it isn't nessecary and can cause issues, just keep them at the bottom of this function
		kmData[1] = plyKMModel
		kmData[2] = targetKMModel
		kmData[3] = animName
		kmData[4] = plyKMPosition
		kmData[5] = plyKMAngle

		if animName != nil then return kmData end --Send the killmove data to the main addons killmove check function
	end)

	--This is the hook for custom killmove effects and sounds

	hook.Add("CustomKMEffects", "RushHeatActionsEffects", function(ply, animName, targetModel)
		
		local targetHeadBone = nil
			
		if IsValid (targetModel) then targetHeadBone = targetModel:GetHeadBone() end
		
		if animName == "killmove_rushhact_barrage" then --Check the killmove animation names
			
			--Set a timer for effects, you can add more timers for more sounds
			
			timer.Create("barrageTimer" , 1, 3, function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
				
				--This function will play random sounds. for example: here are 2 sound files killmovesound1 and killmovesound2, using this function with min being 1 and max being 2, it will choose a random one of those between that range to play.
				
				PlayRandomSound(ply, 1 --[[min]], 5 --[[max]], "player/killmove/km_hit" --[[path to the sound]])
			end)

			timer.Simple(4.2, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
			end)

			timer.Simple(5.8, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
				
				if targetHeadBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
			
			--Repeat the same for different animations
			
		elseif animName == "killmove_rushhact_crushing" then
			timer.Simple(0.7, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 3, "player/killmove/km_bonebreak")
			end)
			timer.Simple(2, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
			end)
		elseif animName == "killmove_rushhact_crushing_wall" then
			timer.Simple(1, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 3, "player/killmove/km_bonebreak")
			end)
			timer.Simple(3.8, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
			end)
			timer.Simple(6.7, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
			end)
		end
		
	end)
end

--This is the hook for modifying the ragdoll after being killmoved
--it's also outside of the server check because it's needed for serverside and clientside ragdolls

hook.Add( "KMRagdoll", "RushHeatActionsRagdoll", function(entity, ragdoll, animName)
	
	--Define the position and angles of a bone, we'll talk about this further down
	local spinePos, spineAng = nil
	
	if ragdoll:LookupBone("ValveBiped.Bip01_Spine") then 
		spinePos, spineAng = ragdoll:GetBonePosition(ragdoll:LookupBone("ValveBiped.Bip01_Spine"))
	end
	
	--Loop through all of the ragdoll's bones that have a physics mesh attached, this will basically move the entire ragdoll
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum(i)
		
		if bone and bone:IsValid() then
			
			--We won't be needing this but if you do then feel free to uncomment it
			--local bonepos, boneang = ragdoll:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
			
			if animName == "killmove_zombie_kick1" then
				if spineAng != nil then
					--Set the ragdoll's velocity to move to the east direction of the spine bone (it's -spineAng:Up because source engine bones are weird)
					--if you dont get the right direction then mess around with it by using spineAng:Up, spineAng:Forward or spineAng:Right. use a minus symbol(-) before it for the opposite direction
					bone:SetVelocity(-spineAng:Up() * 75)
				end
			elseif animName == "killmove_zombie_punch1" then
				--Put code here and delete this comment lol, make sure to change the animation name
			end
		end
	end
	
	--You can also rotate the ragdoll by changing it's angular velocity, here's an example below
	
	--bone:SetAngleVelocity(bone:WorldToLocalVector(-spineAng:Forward() * 2500))
	
	--This basically makes the ragdoll spin like a torpedo, it's -spineAng:Forward() because again source engine bones are weird but it basically means the up direction of it
end)