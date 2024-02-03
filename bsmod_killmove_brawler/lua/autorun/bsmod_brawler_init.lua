--This creates a console variable to manipulate the dropkick chance
CreateClientConVar("bsmod_brawler_brawling", 2, true, false, "Chance of essence of the brawling. 0-10", 0, 10)
CreateClientConVar("bsmod_brawler_finblow", 2, true, false, "Chance of essence of the finishing blow 0-10", 0, 10)
CreateClientConVar("bsmod_brawler_disarming", 2, true, false, "Chance of essence of the disarming. 0-10", 0, 10)

if CLIENT then
    local function yakuzaBrawlerOptions(panel)
        panel:ClearControls()
        
        local text1 = vgui.Create("DLabel")
        text1:SetText("Settings for modifying chances of Brawler Killmoves.")
        text1:SetColor(Color(0, 0, 0))
        
        panel:AddItem(text1)
        
        panel:NumSlider("Essence of Brawling Chance", "bsmod_brawler_brawling", 0, 10, 0)
        panel:NumSlider("Essence of Finishing blow Chance", "bsmod_brawler_finblow", 0, 10, 0)
        panel:NumSlider("Essence of Disarming Chance", "bsmod_brawler_disarming", 0, 10, 0)
        
        panel:AddItem(text0)
    end
    
    hook.Add("PopulateToolMenu", "BSModBrawlerSettings", function()
        spawnmenu.AddToolMenuOption("Options", "BSMod", "BSModBrawlerSettings", "Brawler Settings", "", "", yakuzaBrawlerOptions)
    end)
end