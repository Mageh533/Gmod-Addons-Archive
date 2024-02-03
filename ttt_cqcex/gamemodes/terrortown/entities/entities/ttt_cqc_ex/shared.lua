CreateConVar("ttt_cqcex_detective", 1, SERVER and {FCVAR_ARCHIVE, FCVAR_REPLICATED} or FCVAR_REPLICATED, "Should Detectives be able to buy CQC EX?")
CreateConVar("ttt_cqcex_traitor", 1, SERVER and {FCVAR_ARCHIVE, FCVAR_REPLICATED} or FCVAR_REPLICATED, "Should Traitors be able to buy CQC EX?")

EQUIP_CQC_EX = GenerateNewEquipmentID()

local perk = {
	id = EQUIP_CQC_EX,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_ttt_cqcex",
	name = "cqc_ex_name",
	desc = "cqc_ex_desc",
}

if (GetConVar("ttt_cqcex_detective"):GetBool()) then
	table.insert(EquipmentItems[ROLE_DETECTIVE], perk)
end

if (GetConVar("ttt_cqcex_traitor"):GetBool()) then
	table.insert(EquipmentItems[ROLE_TRAITOR], perk)
end