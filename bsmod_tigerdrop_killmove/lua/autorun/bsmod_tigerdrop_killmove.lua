--IMPORTANT: Make sure this is the only custom killmove lua file for your addon since having multiple can cause conflicts and issues

--This makes sure the functions in this if statement are only ran on the server since they aren't needed on the client
if SERVER then

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
	hook.Add("CustomKillMoves", "TigerDrop", function(ply, target, angleAround)
		
		--Setup some values for custom killmove data
		local plyKMModel = nil
		local targetKMModel = nil
		local animName = nil
		local plyKMPosition = nil
		local plyKMAngle = nil
		
		local kmData = {1, 2, 3, 4, 5} --We'll use this at the end of the hook

		local tigerDropChance = math.Round(GetConVar("bsmod_yakuza_tigerdrop_chance"):GetFloat())
		
		plyKMModel = "models/weapons/killmove_tigerdrop_player.mdl" --We set the Players killmove model to the custom one that has the animations


		if ply:OnGround() and target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and math.random(1, 10) <= tigerDropChance then
		
			targetKMModel = "models/killmove_tigerdrop_target.mdl" --Set the Targets killmove model
			
			animName = "killmove_tigerdrop" --Set the name of the animation that will play for both the Player and Target model
		end
		
		--Positioning the Player for different killmove animations
		if animName == "killmove_tigerdrop" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 50 ) + (target:GetUp() * -5) --Position the player in front of the Target and x distance away
			plyKMAngle = target:GetAngles()
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

	hook.Add("CustomKMEffects", "UniqueName", function(ply, animName, targetModel)
		
		local targetHeadBone = nil
			
		if IsValid (targetModel) then targetHeadBone = targetModel:GetHeadBone() end
		
		if animName == "killmove_tigerdrop" then --Check the killmove animation names
			
			--Set a timer for effects, you can add more timers for more sounds
			
			timer.Simple(0.1 --[[delay]], function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
				
				--This function will play random sounds. for example: here are 2 sound files killmovesound1 and killmovesound2, using this function with min being 1 and max being 2, it will choose a random one of those between that range to play.
				
				PlayRandomSound(ply, 1 --[[min]], 5 --[[max]], "player/killmove/km_hit" --[[path to the sound]])
				
				if targetHeadBone != nil then
					
					--This will emit a blood effect at the target's head bone
					
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
					
					--You can also specify which bone you want the effect to be positioned to
					--effectdata:SetOrigin(targetModel:GetBonePosition(targetModel:LookupBone("ValveBiped.Bip01_Spine")))
					
					util.Effect("BloodImpact", effectdata)
				end
			end)
		end
			--Repeat the same for different animations
	end)
end

--This is the hook for modifying the ragdoll after being killmoved
--it's also outside of the server check because it's needed for serverside and clientside ragdolls

hook.Add( "KMRagdoll", "UniqueName", function(entity, ragdoll, animName)
	
	--Define the position and angles of a bone, we'll talk about this further down
	local spinePos, spineAng = nil
	
	if ragdoll:LookupBone("ValveBiped.Bip01_Spine") then 
		spinePos, spineAng = ragdoll:GetBonePosition(ragdoll:LookupBone("ValveBiped.Bip01_Spine"))
	end

	local tigerDropForce = math.Round(GetConVar("bsmod_yakuza_tigerdrop_force"):GetFloat())
	
	--Loop through all of the ragdoll's bones that have a physics mesh attached, this will basically move the entire ragdoll
	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local bone = ragdoll:GetPhysicsObjectNum(i)
		
		if bone and bone:IsValid() then
			
			--We won't be needing this but if you do then feel free to uncomment it
			--local bonepos, boneang = ragdoll:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
			
			if animName == "killmove_tigerdrop" then
				if spineAng != nil then
					--Set the ragdoll's velocity to move to the east direction of the spine bone (it's -spineAng:Up because source engine bones are weird)
					--if you dont get the right direction then mess around with it by using spineAng:Up, spineAng:Forward or spineAng:Right. use a minus symbol(-) before it for the opposite direction
					bone:SetVelocity((spineAng:Right() * 300) + (spineAng:Forward() * tigerDropForce))
				end
			end
		end
	end
	
	--You can also rotate the ragdoll by changing it's angular velocity, here's an example below
	
	--bone:SetAngleVelocity(bone:WorldToLocalVector(-spineAng:Forward() * 2500))
	
	--This basically makes the ragdoll spin like a torpedo, it's -spineAng:Forward() because again source engine bones are weird but it basically means the up direction of it
end)