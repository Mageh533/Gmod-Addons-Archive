CreateClientConVar("bsmod_yakuza_tigerdrop_chance", 2, true, false, "Chance of the Tiger Drop killmoe. 0-10", 0, 10)
CreateClientConVar("bsmod_yakuza_tigerdrop_force", 300, true, false, "Tiger Drop Force. 0-9999", 0, 9999)

if CLIENT then
    local function yakuzaTigerDropOptions(panel)
        panel:ClearControls()
        
        local text1 = vgui.Create("DLabel")
        text1:SetText("Settings for modifying chances of Misc Yakuza Killmoves.")
        text1:SetColor(Color(0, 0, 0))
        
        panel:AddItem(text1)
        
        panel:NumSlider("Tiger Drop Chance", "bsmod_yakuza_tigerdrop_chance", 0, 10, 0)
        panel:NumSlider("Tiger Drop Force", "bsmod_yakuza_tigerdrop_force", 0, 2000, 0)
        
        panel:AddItem(text0)
    end
    
    hook.Add("PopulateToolMenu", "BSModTigerDropSettings", function()
        spawnmenu.AddToolMenuOption("Options", "BSMod", "BSModTigerDropSettings", "Misc Yakuza Settings", "", "", yakuzaTigerDropOptions)
    end)
end