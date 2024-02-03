--This creates a console variable to manipulate the dropkick chance
CreateClientConVar("bsmod_rush_crushing", 2, true, false, "Chance of essence of the crushing 0-10", 0, 10)
CreateClientConVar("bsmod_rush_barrage", 2, true, false, "Chance of essence of the relentless barrage 0-10", 0, 10)
CreateClientConVar("bsmod_rush_wallcrushing", 2, true, false, "Chance of essence of the wall crushing. 0-10", 0, 10)

if CLIENT then
    local function yakuzaRushOptions(panel)
        panel:ClearControls()
        
        local text1 = vgui.Create("DLabel")
        text1:SetText("Settings for modifying chances of Rush Killmoves.")
        text1:SetColor(Color(0, 0, 0))
        
        panel:AddItem(text1)
        
        panel:NumSlider("Essence of Crushing Chance", "bsmod_rush_crushing", 0, 10, 0)
        panel:NumSlider("Essence of Relentless Barrage Chance", "bsmod_rush_barrage", 0, 10, 0)
        panel:NumSlider("Essence of Wall Crushing Chance", "bsmod_rush_wallcrushing", 0, 10, 0)
        
        panel:AddItem(text0)
    end
    
    hook.Add("PopulateToolMenu", "BSModRushSettings", function()
        spawnmenu.AddToolMenuOption("Options", "BSMod", "BSModRushSettings", "Rush Settings", "", "", yakuzaRushOptions)
    end)
end