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
	hook.Add("CustomKillMoves", "BrawlerHeatActions", function(ply, target, angleAround)
		local brawlingChance = math.Round(GetConVar("bsmod_brawler_brawling"):GetFloat())
		local finblowChance = math.Round(GetConVar("bsmod_brawler_finblow"):GetFloat())
		local disarmingChance = math.Round(GetConVar("bsmod_brawler_disarming"):GetFloat())
		
		--Setup some values for custom killmove data
		local plyKMModel = nil
		local targetKMModel = nil
		local animName = nil
		local plyKMPosition = nil
		local plyKMAngle = nil
		
		local kmData = {1, 2, 3, 4, 5} --We'll use this at the end of the hook
		
		plyKMModel = "models/weapons/killmove_brawlerhact_player.mdl" --We set the Players killmove model to the custom one that has the animations
		
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
		
		if target:LookupBone("ValveBiped.Bip01_Spine") and brawlingChance == 10 and finblowChance == 10 then
			if math.random(1,2) == 1 then
				targetKMModel = "models/killmove_brawlerhact_target.mdl" 

				animName = "killmove_brawlerhact_brawling" 
			else
				targetKMModel = "models/killmove_brawlerhact_target.mdl" 
				
				animName = "killmove_brawlerhact_finishingblow"
			end
		else
			if target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and (math.random(1, 10) <= brawlingChance) then
		
				targetKMModel = "models/killmove_brawlerhact_target.mdl" 

				animName = "killmove_brawlerhact_brawling" 
			end

			if target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround <= 45 or angleAround > 315) and (math.random(1, 10) <= finblowChance) then
		
				targetKMModel = "models/killmove_brawlerhact_target.mdl" 

				animName = "killmove_brawlerhact_finishingblow"
			end


			if target:LookupBone("ValveBiped.Bip01_Spine") and (angleAround > 225 and angleAround <= 315) and (math.random(1, 10) <= disarmingChance) then
		
				targetKMModel = "models/killmove_brawlerhact_target.mdl" 
			
				animName = "killmove_brawlerhact_disarming"
			end
		end
		--Positioning the Player for different killmove animations
		if animName == "killmove_brawlerhact_brawling" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 25 ) --Position the player in front of the Target and x distance away
			plyKMAngle = target:GetAngles()
		elseif animName == "killmove_brawlerhact_finishingblow" then
			plyKMPosition = target:GetPos() + (target:GetForward())
		elseif animName == "killmove_brawlerhact_disarming" then
			plyKMPosition = target:GetPos() + (target:GetForward() * 60 ) + (target:GetRight() * 5)
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

	hook.Add("CustomKMEffects", "BrawlerHeatActionsEffects", function(ply, animName, targetModel)
		
		local targetHeadBone = nil
			
		if IsValid (targetModel) then targetHeadBone = targetModel:GetHeadBone() end
		
		if animName == "killmove_brawlerhact_brawling" then --Check the killmove animation names
			
			--Set a timer for effects, you can add more timers for more sounds
			
			timer.Simple(2.5, function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
								
				PlayRandomSound(ply, 1 --[[min]], 5 --[[max]], "player/killmove/km_hit" --[[path to the sound]])
				
				if targetHeadBone != nil then
					
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
					
					util.Effect("BloodImpact", effectdata)
				end
			end)

			timer.Simple(0.25, function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
								
				PlayRandomSound(ply, 1 --[[min]], 5 --[[max]], "player/killmove/km_hit" --[[path to the sound]])
			end)

			timer.Simple(0.9, function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
								
				PlayRandomSound(ply, 1 --[[min]], 5 --[[max]], "player/killmove/km_hit" --[[path to the sound]])
			end)
			
			--Repeat the same for different animations
			
		elseif animName == "killmove_brawlerhact_finishingblow" then
			timer.Simple(0.7, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
				
				if targetHeadBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		elseif animName == "killmove_brawlerhact_disarming" then
			timer.Simple(1.4, function()
				if !IsValid(targetModel) then return end --Check if the Target still exists to avoid script errors
								
				PlayRandomSound(ply, 1 --[[min]], 3 --[[max]], "player/killmove/km_bonebreak" --[[path to the sound]])
			end)

			timer.Simple(3.1, function()
				if !IsValid(targetModel) then return end
				
				PlayRandomSound(ply, 1, 5, "player/killmove/km_hit")
				
				if targetHeadBone != nil then
					local effectdata = EffectData()
					effectdata:SetOrigin(targetModel:GetBonePosition(targetHeadBone))
					util.Effect("BloodImpact", effectdata)
				end
			end)
		end
	end)
end

--This is the hook for modifying the ragdoll after being killmoved
--it's also outside of the server check because it's needed for serverside and clientside ragdolls

hook.Add( "KMRagdoll", "BrawlerHeatActionsRagdoll", function(entity, ragdoll, animName)
	
	--Define the position and angles of a bone, we'll talk about this further down
	local spinePos, spineAng = nil
	
	if ragdoll:LookupBone("ValveBiped.Bip01_Spine") then 
		spinePos, spineAng = ragdoll:GetBonePosition(ragdoll:LookupBone("ValveBiped.Bip01_Spine"))
	end
end)