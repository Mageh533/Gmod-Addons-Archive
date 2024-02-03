--This creates a console variable to manipulate the dropkick chance
CreateClientConVar("bsmod_beast_knockoutthrow", 2, true, false, "Chance of essence of the knockout throw. 0-10", 0, 10)
CreateClientConVar("bsmod_beast_knockoutthrow_force", 300, true, false, "Knockout Throw Force. 0-9999", 0, 9999)
CreateClientConVar("bsmod_beast_electricpanel", 2, true, false, "Chance of essence of the Electric Panel. 0-10", 0, 10)
CreateClientConVar("bsmod_beast_piledive", 2, true, false, "Chance of essence of the Pile Dive. 0-10", 0, 10)
CreateClientConVar("bsmod_beast_heavyhit", 2, true, false, "Chance of essence of the Heavy Hit. 0-10", 0, 10)
CreateClientConVar("bsmod_beast_wallpin", 2, true, false, "Chance of essence of the Wall Pin. 0-10", 0, 10)

if CLIENT then
    local function yakuzaBeastOptions(panel)
        panel:ClearControls()
        
        local text1 = vgui.Create("DLabel")
        text1:SetText("Settings for modifying chances of Beast Killmoves.")
        text1:SetColor(Color(0, 0, 0))
        
        panel:AddItem(text1)
        
        panel:NumSlider("Essence of Knockout Chance", "bsmod_beast_knockoutthrow", 0, 10, 0)
        panel:NumSlider("Essence of Knockout Force", "bsmod_beast_knockoutthrow_force", 0, 2000, 0)
        panel:NumSlider("Essence of Electric Panel", "bsmod_beast_electricpanel", 0, 10, 0)
        panel:NumSlider("Essence of Pile Dive Chance", "bsmod_beast_piledive", 0, 10, 0)
        panel:NumSlider("Essence of Heavy Hit Chance", "bsmod_beast_heavyhit", 0, 10, 0)
        panel:NumSlider("Essence of Wall Pin Chance", "bsmod_beast_wallpin", 0, 10, 0)
        
        panel:AddItem(text0)
    end
    
    hook.Add("PopulateToolMenu", "BSModBeastSettings", function()
        spawnmenu.AddToolMenuOption("Options", "BSMod", "BSModBeastSettings", "Beast Settings", "", "", yakuzaBeastOptions)
    end)
end