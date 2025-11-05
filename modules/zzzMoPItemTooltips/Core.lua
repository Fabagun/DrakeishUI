local addonName = ...


local AceTimer = LibStub("AceTimer-3.0");

local tooltip_core = true

if not tooltip_core then
  return
end

local Colors = {
    { 0, 1, 0 },
    { 0, 1, 0.75 },
    { GetItemQualityColor(0) },
    { GetItemQualityColor(1) },
    { GetItemQualityColor(2) },
    { GetItemQualityColor(3) },
    { GetItemQualityColor(4) },
    { GetItemQualityColor(5) },
    { GetItemQualityColor(6) },
}

local MoPItemTooltipEnchantText, MoPItemTooltipSocketText, MoPItemTooltipDebug;
local function InitDefaultSettings()
    MoPItemTooltipEnabled = true
    MoPItemTooltipColor = Colors[1]
    MoPItemTooltipEnchantColor = Colors[1]
    MoPItemTooltipEnchantText = GetLocale() == "ruRU" and "Зачаровано: %s" or "Enchanted: %s"
    MoPItemTooltipSocketColor = Colors[1]
    MoPItemTooltipSocketText = ITEM_SOCKET_BONUS
    MoPItemTooltipSeparators = true
    MoPItemTooltipItemLevel = true
    MoPItemTooltipFaction = true
    MoPItemTooltipDebug = false
end
InitDefaultSettings();

local factionReplacements = { GetLocale() == "ruRU" and "Только для Альянса" or "Alliance Only", GetLocale() == "ruRU" and "Только для Орды" or "Horde Only" };

function string.starts(str, sub)
    return str:gsub("|c%w%w%w%w%w%w%w%w", ""):gsub("|r", ""):sub(1, sub:len()) == sub
end
local function formatToPattern(fmt)
    return "^"..fmt:gsub("[+-]", "%%%1"):gsub("%%c", "[+-]"):gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%d", "(%%d+)"):gsub("%.", "%%."):gsub("%%s", "(.*)"):gsub("|4[^:]-:[^:]-:[^:]-;", ".-"):gsub("|4[^:]-:[^:]-;", ".-").."$"
end

local pattern_PETITION_TITLE = formatToPattern(PETITION_TITLE);
local pattern_GUILD_CHARTER_TITLE = formatToPattern(GUILD_CHARTER_TITLE);
local pattern_FERAL_DRUID_ITEM_AP = formatToPattern(FERAL_DRUID_ITEM_AP);
local pattern_itemRecipeReagents = formatToPattern("\n"..ITEM_REQ_SKILL);
local pattern_ITEM_SET_BONUS = formatToPattern(ITEM_SET_BONUS);
local pattern_ITEM_SET_BONUS_GRAY = formatToPattern(ITEM_SET_BONUS_GRAY);
local pattern_EQUIPMENT_SETS = formatToPattern(EQUIPMENT_SETS);
local pattern_REFUND_TIME_REMAINING = formatToPattern(REFUND_TIME_REMAINING);
local pattern_BIND_TRADE_TIME_REMAINING = formatToPattern(BIND_TRADE_TIME_REMAINING);
local pattern_PLUS_DAMAGE_TEMPLATE_WITH_SCHOOL = formatToPattern(PLUS_DAMAGE_TEMPLATE_WITH_SCHOOL);
local pattern_DPS_TEMPLATE_modified = formatToPattern(DPS_TEMPLATE:gsub("%%%.1f", "%%s"));
local pattern_ARMOR_TEMPLATE = formatToPattern(ARMOR_TEMPLATE);
local pattern_SHIELD_BLOCK_TEMPLATE = formatToPattern(SHIELD_BLOCK_TEMPLATE);
local pattern_ITEM_MIN_LEVEL = "^"..ITEM_MIN_LEVEL:gsub("%%d", "%%d+");
local pattern_ITEM_LEVEL = "^"..ITEM_LEVEL:gsub("%%d", "%%d+");
local pattern_ITEM_MIN_SKILL = "^"..ITEM_MIN_SKILL:gsub("%%d", "%%d+");
local pattern_ITEM_LEVEL_RANGE = "^"..ITEM_LEVEL_RANGE:gsub("%%d", "%%d+");
local pattern_ITEM_LEVEL_AND_MIN = "^"..ITEM_LEVEL_AND_MIN:gsub("%%d", "%%d+");
local pattern_ITEM_LEVEL_RANGE_CURRENT = "^"..ITEM_LEVEL_RANGE_CURRENT:gsub("%%d", "%%d+");
local pattern_DURABILITY_TEMPLATE = "^"..DURABILITY_TEMPLATE:gsub("%%d", "%%d+");
local pattern_ITEM_SOCKET_BONUS_prefix = ITEM_SOCKET_BONUS:gsub("%%s", "");
local pattern_ITEM_SOCKET_BONUS = ITEM_SOCKET_BONUS:gsub("%%s", "(.+)");

local mods = {
    "ITEM_MOD_ARMOR_PENETRATION_RATING",
    "ITEM_MOD_ATTACK_POWER",
    "ITEM_MOD_BLOCK_RATING",
    "ITEM_MOD_BLOCK_VALUE",
    "ITEM_MOD_CRIT_MELEE_RATING",
    "ITEM_MOD_CRIT_RANGED_RATING",
    "ITEM_MOD_CRIT_RATING",
    "ITEM_MOD_CRIT_SPELL_RATING",
    "ITEM_MOD_CRIT_TAKEN_MELEE_RATING",
    "ITEM_MOD_CRIT_TAKEN_RANGED_RATING",
    "ITEM_MOD_CRIT_TAKEN_RATING",
    "ITEM_MOD_CRIT_TAKEN_SPELL_RATING",
    "ITEM_MOD_DEFENSE_SKILL_RATING",
    "ITEM_MOD_DODGE_RATING",
    "ITEM_MOD_EXPERTISE_RATING",
    "ITEM_MOD_FERAL_ATTACK_POWER",
    "ITEM_MOD_HASTE_MELEE_RATING",
    "ITEM_MOD_HASTE_RANGED_RATING",
    "ITEM_MOD_HASTE_RATING",
    "ITEM_MOD_HASTE_SPELL_RATING",
    "ITEM_MOD_HEALTH_REGEN",
    "ITEM_MOD_HEALTH_REGENERATION",
    "ITEM_MOD_HIT_MELEE_RATING",
    "ITEM_MOD_HIT_RANGED_RATING",
    "ITEM_MOD_HIT_RATING",
    "ITEM_MOD_HIT_SPELL_RATING",
    "ITEM_MOD_HIT_TAKEN_MELEE_RATING",
    "ITEM_MOD_HIT_TAKEN_RANGED_RATING",
    "ITEM_MOD_HIT_TAKEN_RATING",
    "ITEM_MOD_HIT_TAKEN_SPELL_RATING",
    "ITEM_MOD_MANA_REGENERATION",
    "ITEM_MOD_MASTERY_RATING",
    "ITEM_MOD_PARRY_RATING",
    "ITEM_MOD_PVP_POWER",
    "ITEM_MOD_RANGED_ATTACK_POWER",
    "ITEM_MOD_RESILIENCE_RATING",
    "ITEM_MOD_SPELL_DAMAGE_DONE",
    "ITEM_MOD_SPELL_HEALING_DONE",
    "ITEM_MOD_SPELL_PENETRATION",
    -- "ITEM_MOD_SPELL_POWER", -- Cannot outright replace this format, because heirlooms with scalable spell power take a different codepath which doens't support %c
    "FERAL_DRUID_ITEM_AP",
}
local function prepmodcheck(str, selectnum)
    return str:gsub("%%c", "[+-]"):gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%d", selectnum and "(%%d+)" or "%%d+"):gsub("%.", "%%.").."$"
end

-- in case the stat is provides through an On Equip spell
local customs = {
    "ITEM_MOD_SPELL_POWER",
    "ITEM_MOD_BLOCK_RATING",
    "ITEM_MOD_BLOCK_VALUE",
    "ITEM_MOD_CRIT_RATING",
    "ITEM_MOD_DEFENSE_SKILL_RATING",
    "ITEM_MOD_DODGE_RATING",
    "ITEM_MOD_HIT_RATING",
    "ITEM_MOD_PARRY_RATING",
    --"ITEM_MOD_SPELL_PENETRATION", -- Handled separately, custom text for ruRU
    "ITEM_MOD_MANA_REGENERATION",
    "ITEM_MOD_HEALTH_REGENERATION",
}

local modchecks = {
    ["FERAL_DRUID_ITEM_AP_CUSTOM"] = prepmodcheck(ITEM_MOD_ATTACK_POWER, true),
    ["ITEM_MOD_SPELL_PENETRATION_CUSTOM"] = prepmodcheck(ITEM_MOD_SPELL_PENETRATION, true),
}

for _, mod in ipairs(customs) do modchecks[mod.."_CUSTOM"] = prepmodcheck(_G[mod], true); end

local backups = {
}

do
    for _,mod in pairs(mods) do
        local new = _G[mod]
        if new then
            local old = new
            local newdef
            if mod == "FERAL_DRUID_ITEM_AP" then
                new = "+%d "..ITEM_MOD_FERAL_ATTACK_POWER_SHORT
            elseif mod == "ITEM_MOD_SPELL_PENETRATION" and GetLocale() == "ruRU" then
                new = "%c%d к проникающей способности заклинаний"
            else
                newdef = _G[mod.."_SHORT"]
                if newdef then
                    new = "%c%d "..newdef
                end
            end
            backups[mod] = { old, new }
            _G[mod] = new
            modchecks[mod] = prepmodcheck(new)
        end
    end
end

if ITEM_MOD_MASTERY_RATING then
    modchecks["ITEM_MOD_MASTERY_RATING_CUSTOM"] = prepmodcheck(ITEM_MOD_MASTERY_RATING, true):gsub("%$", "")
end

local modreplaces = {
    ["FERAL_DRUID_ITEM_AP_CUSTOM"] = "+%d "..ITEM_MOD_ATTACK_POWER_SHORT,
    ["ITEM_MOD_SPELL_PENETRATION_CUSTOM"] = "+%d "..(GetLocale() == "ruRU" and "к проникающей способности заклинаний" or ITEM_MOD_SPELL_PENETRATION_SHORT),
    ["ITEM_MOD_MASTERY_RATING_CUSTOM"] = "+%d "..(ITEM_MOD_MASTERY_RATING_SHORT or ""),
    ["ITEM_MOD_SPELL_POWER_CUSTOM"] = "+%d "..(ITEM_MOD_SPELL_POWER_SHORT or ""), -- Read above for the reason of this inclusion (heirlooms)
}

for _, mod in ipairs(customs) do modreplaces[mod.."_CUSTOM"] = "+%d ".._G[mod.."_SHORT"]; end

-- Custom fixes for plethora of different phrasing and spelling in On Equip spell descriptions
local spelldesc =
{
    ["ITEM_MOD_ARMOR_PENETRATION_RATING"] = { { "Increases armor penetration rating by $s1." }, { "Увеличивает рейтинг пробивания брони на $s1." } },
    ["ITEM_MOD_ATTACK_POWER"] = { { "Increases your attack power by $s1.", "Increases melee and ranged attack power by $s1." }, { "Увеличение силы атаки на $s1 ед.", "Увеличение силы атаки ближнего и дальнего боя на $s1 ед." } },
    ["ITEM_MOD_BLOCK_RATING"] = { { "Increases your block rating by $s1." }, { "Увеличение рейтинга блока на $s1 ед." } },
    ["ITEM_MOD_BLOCK_VALUE"] = { { }, { "Увеличивает показатель блокирования вашего щита на $s1 ед." } },
    ["ITEM_MOD_CRIT_RANGED_RATING"] = { { "Increases your ranged critical strike rating by $s1." }, { "Увеличение рейтинга критического урона атак дальнего боя на $s1 ед." } },
    ["ITEM_MOD_CRIT_RATING"] = { { "Increases your critical strike rating by $s1.", "Increases your spell critical strike rating by $s1.", "Improves your critical strike rating by $s1.", "Increases your crit rating by $s1.", "Crit Rating increased by $s1." }, { "Повышает рейтинг критического удара на $s1.", "Увеличение рейтинга критического эффекта заклинаний на $s1.", "Увеличение рейтинга критического удара на $s1.", "Увеличивает рейтинг критического удара на $s1.", "Рейтинг критического эффекта повышен на $s1." } },
    ["ITEM_MOD_CRIT_SPELL_RATING"] = { { "Increases spell critical strike rating by $s1." }, { "Увеличение рейтинга критического удара вашего заклинания на $s1 ед." } },
    ["ITEM_MOD_DEFENSE_SKILL_RATING"] = { { }, { "Увеличивает рейтинг защиты на $s1." } },
    ["ITEM_MOD_DODGE_RATING"] = { { }, { "Увеличивает рейтинг уклонения на $s1." } },
    ["ITEM_MOD_EXPERTISE_RATING"] = { { "Increases expertise rating by $s1." }, { "Увеличение рейтинга мастерства на $s1 ед." } },
    ["ITEM_MOD_FERAL_ATTACK_POWER"] = { { }, { "Увеличивает силу атаки на $s1 в облике кошки, медведя, лютого медведя или лунного совуха." } },
    ["ITEM_MOD_HASTE_RATING"] = { { "Increases haste rating by $s1.", "Increases your haste rating by $s1." }, { "Увеличивает рейтинг скорости на $s1." } },
    ["ITEM_MOD_HEALTH_REGEN"] = { { "Restores $s1 health and mana every 5 sec." }, { "Восполняет $s1 ед. здоровья каждые 5 секунд.", "Восполнение $s1 ед. здоровья за 5 секунд.", "Восполнение $s1 ед. маны и здоровья раз в 5 сек." } },
    ["ITEM_MOD_HIT_RANGED_RATING"] = { { "Increases your ranged hit rating by $s1." }, { "Повышение на $s1 ед. рейтинга меткости атак дальнего боя." } },
    ["ITEM_MOD_HIT_RATING"] = { { "Increases your hit rating by $s1." }, { "Повышает рейтинг меткости на $s1." } },
    ["ITEM_MOD_HIT_SPELL_RATING"] = { { "Increases your spell hit rating by $s1." }, { "Повышение на $s1 ед. рейтинга меткости применения заклинаний." } },
    ["ITEM_MOD_MANA_REGENERATION"] = { { "Gain $s1 mana every 5 seconds.", "Restores $s1 health and mana every 5 sec.", "Restores $s1 mana every 5 seconds." }, { "Восполнение $s1 ед. маны раз в 5 секунд.", "Восполнение $s1 ед. маны в 5 сек.", "Восполняет $s1 ед. маны раз в 5 секунд.", "Восполнение $s1 ед. маны за 5 секунд.", "Восполнение $s1 ед. маны и здоровья раз в 5 сек.", "Повышение нормальной скорости восполнения здоровья и маны заклинателя на 5 ед." } },
    ["ITEM_MOD_PARRY_RATING"] = { { }, { "Увеличивает рейтинг парирования на $s1." } },
    ["ITEM_MOD_RESILIENCE_RATING"] = { { "+$s1 Resilience Rating.", "+$s1 resilience rating.", "Increases resilience by $s1." }, { "+$s1 к рейтингу устойчивости.", "Повышение устойчивости на $s1 ед." } },
    ["ITEM_MOD_SPELL_DAMAGE_DONE"] = { { "Increases damage from spells and effects by $s1." }, { "Повышение урона от заклинаний и эффектов на $s1 ед." } },
    ["ITEM_MOD_SPELL_HEALING_DONE"] = { { "Increases healing done by spells and effects by up to $s1." }, { "Повышение исцеляющих эффектов не более чем на $s1 ед." } },
    ["ITEM_MOD_SPELL_PENETRATION"] = { { "Increases your spell penetration by $s1." }, { } },
    ["ITEM_MOD_SPELL_POWER"] = { { "Increases your spell power by $s1." }, { "Повышает силу заклинаний на $s1.", "Увеличивает вашу силу заклинаний на $s2." } },
};
for mod, patterns in pairs(spelldesc) do
    for i, pattern in ipairs(patterns[GetLocale() == "ruRU" and 2 or 1]) do
        modchecks[mod.."_SPELLDESC"..i] = prepmodcheck(pattern:gsub("%-", "%%-"):gsub("%+", "%%+"):gsub("%$s%d+", "%%d"), true);
        modreplaces[mod.."_SPELLDESC"..i] = "+%d ".._G[mod.."_SHORT"];
    end
end

--[[
local MoPReforgeScannerTooltip = CreateFrame("GameTooltip")
local f = {}
f.PassiveBonuses = {
	{ pattern = string.gsub(ITEM_MOD_DEFENSE_SKILL_RATING, "%%d", "(%%d+)%%"), effect = "DEFENSE" },
 	{ pattern = string.gsub(ITEM_MOD_RESILIENCE_RATING, "%%d", "(%%d+)%%"), effect = "RESILIENCE" }	, 
  	{ pattern = string.gsub(ITEM_MOD_EXPERTISE_RATING, "%%d", "(%%d+)%%"), effect = "EXPERTISE" },
	{ pattern = string.gsub(ITEM_MOD_BLOCK_RATING, "%%d", "(%%d+)%%"), effect = "BLOCK" },
	{ pattern = string.gsub(ITEM_MOD_DODGE_RATING, "%%d", "(%%d+)%%"), effect = "DODGE" },
	{ pattern = string.gsub(ITEM_MOD_PARRY_RATING, "%%d", "(%%d+)%%"), effect = "PARRY" },
	{ pattern = string.gsub(ITEM_MOD_CRIT_RATING , "%%d", "(%%d+)%%"), effect = "CRIT" },
	{ pattern = string.gsub(ITEM_MOD_CRIT_MELEE_RATING, "%%d", "(%%d+)%%"), effect = "CRIT" },
	{ pattern = string.gsub(ITEM_MOD_HIT_RATING, "%%d", "(%%d+)%%"), effect = "TOHIT" },
	{ pattern = string.gsub(ITEM_MOD_HASTE_RATING, "%%d", "(%%d+)%%"), effect = "HASTE" },
	{ pattern = string.gsub(ITEM_MOD_MASTERY_RATING, "%%d", "(%%d+)%%"), effect = "MASTERY"},
	{ pattern = string.gsub(ITEM_MOD_ARMOR_PENETRATION_RATING , "%%d", "(%%d+)%%"), effect = "ARMORPEN" },
};
f.GenericBonuses = {
	[SPELL_STATALL] 					= {"STR", "AGI", "STA", "INT", "SPI"},
	["to All Stats"] 					= {"STR", "AGI", "STA", "INT", "SPI"},
	[ITEM_MOD_STRENGTH_SHORT]			= "STR",
	[ITEM_MOD_AGILITY_SHORT]			= "AGI",
	[ITEM_MOD_STAMINA_SHORT]			= "STA",
	[ITEM_MOD_INTELLECT_SHORT]			= "INT",
	[ITEM_MOD_SPIRIT_SHORT]				= "SPI",
	[STAT_ATTACK_POWER] 				= "ATTACKPOWER",
	[ITEM_MOD_CRIT_RATING_SHORT] 		= "CRIT",
	[ITEM_MOD_MASTERY_RATING_SHORT] 	= "MASTERY",
	[COMBAT_RATING_NAME3] 				= "DODGE",
	[COMBAT_RATING_NAME4] 				= "PARRY",
	[COMBAT_RATING_NAME15] 				= "RESILIENCE",
	[COMBAT_RATING_NAME24] 				= "EXPERTISE",
	[ITEM_MOD_EXPERTISE_RATING_SHORT] 	= "EXPERTISE",
	[ITEM_MOD_DODGE_RATING_SHORT]		= "DODGE",
	[COMBAT_RATING_NAME5]				= "BLOCK",
	[COMBAT_RATING_NAME6]				= "TOHIT",
	[RESILIENCE]						= "RESILIENCE",
};
local L = {}
L["STA"] = "Stamina";
L["INT"] = "Intellect";
L["SPI"] = "Spirit";
L["AGI"] = "Agility";
L["STR"] = "Strength";
L["DODGE"] = "Dodge";
L["PARRY"] = "Parry";
L["CRIT"] = "Crit";
L["HASTE"] = "Haste";
L["TOHIT"] = "Hit";
L["EXPERTISE"] = "Expertise";
L["MASTERY"] = "Mastery";

local AddValue
AddValue = function(Effect, Value, Bonuses)
	if ( type(Effect) == "string" ) then
		Value = tonumber(Value);
		Bonuses[Effect] = ( Bonuses[Effect] or 0 ) + Value;
	else
		if ( type(Value) == "table" ) then
			for i,v in pairs(Effect) do
				Bonuses = AddValue(v, Value[i], Bonuses);
			end;
		else
			for i,v in pairs(Effect) do
				Bonuses = AddValue(v, Value, Bonuses);
			end;
		end;
	end;
	return Bonuses;
end;
local function CheckOther(Line, Bonuses)
	return Bonuses, false;
end;
local function CheckToken(Token, Value, Bonuses)
	local S1, S2;
	if ( strlower(Token) == strlower(SPELL_STATALL) ) then Token = SPELL_STATALL; end;
	if ( f.GenericBonuses[Token] ) then
		Bonuses = AddValue( f.GenericBonuses[Token], Value, Bonuses ) 
	end;
	return Bonuses;
end;
local function CheckPassive(Line, Bonuses)
	local Results, ResultCount, Found, Start, Value;
	for i,v in pairs(f.PassiveBonuses) do
		Results = {string.find(Line, "^" .. v.pattern)}
		if ( Results ) then ResultCount = #Results; end;
		if ( ResultCount ) == 3 then
			Bonuses = AddValue(v.effect, Results[3], Bonuses);
			Found = 1;
			break;
		end;
		Start, _, Value = string.find(Line, "^"..v.pattern);
		if ( Start ) and ( v.value ) then
			Bonuses = AddValue(v.effect, v.value, Bonuses);
			Found = 1;
			break;
		end;
	end;
	return Bonuses;
end;
local function CheckGeneric(Line, Bonuses)
	local Value, Token, POS, POS2, POS3, TempString, Sepend;
	Line = string.gsub( Line, "\n", L["GLOBAL_SEP"]);
	while ( string.len(Line) > 0 ) do
		for _, SEP in ipairs(L["SEPARATORS"]) do
			Line = string.gsub(Line, SEP, L["GLOBAL_SEP"]);
		end;
		POS = string.find(Line, L["PREFIX_SET"], 1, true);
		if ( POS ) then
			return Bonuses;
		end;
		POS = string.find(Line, L["GLOBAL_SEP"], 1, true);
		if ( POS ) then
			TempString = string.sub(Line,1,POS-1);
			Line = string.sub(Line, POS + string.len(L["GLOBAL_SEP"]));
		else
			TempString = Line;
			Line = "";
		end;
		TempString = string.gsub( TempString, "^%s+", "" );
		TempString = string.gsub( TempString, "%s+$", "" );
		TempString = string.gsub( TempString, "%.$", "" );
		TempString = string.gsub( TempString, "\n", "" );
		_, _, Value, Token = string.find(TempString, BONUSSCANNER_PATTERN_GENERIC_PREFIX);
		if ( not Value ) then
			_, _, Token, Value = string.find(TempString, BONUSSCANNER_PATTERN_GENERIC_SUFFIX);
		end;
		if ( not Value ) then
			_, _, Token, Value = string.find(TempString, BONUSSCANNER_PATTERN_GENERIC_SUFFIX2);
		end;
		if ( Token ) and ( Value ) then
			Token = string.gsub( Token, "^%s+", "" );
			Token = string.gsub( Token, "%s+$", "" );
			Token = string.gsub( Token, "%.$", "" );
			Token = string.gsub( Token, "|r", "" );
			Bonuses = CheckToken(Token, Value, Bonuses);
		else
			Bonuses, Found = CheckOther(TempString, Bonuses);
		end;
	end;
	return Bonuses;
end;
local function ScanLine(Line, Red, Green, Blue, Bonuses)
	local TempString, Found, NewLine, ff, Value;
	if ( (Red==128) and (Green==128) and (Blue==128) ) or (string.sub(Line,0,10) == "|cff808080") then
		return Bonuses;
	end;
	if ( string.sub(Line,0, string.len(ITEM_SPELL_TRIGGER_ONEQUIP)) == ITEM_SPELL_TRIGGER_ONEQUIP ) then
		TempString = string.sub(Line, string.len(ITEM_SPELL_TRIGGER_ONEQUIP)+2);
		Bonuses = CheckPassive(TempString, Bonuses);
	elseif ( string.sub(Line, 0, string.len(string.gsub(ITEM_SOCKET_BONUS, "%%s", ""))) == string.gsub(ITEM_SOCKET_BONUS, "%%s", "") ) then
		if ( (Red == 0) and (Green == 255) and (Blue == 0) ) then
			TempString = string.sub(Line, string.len( string.len(string.gsub(ITEM_SOCKET_BONUS, "%%s", "")))+1);
			Bonuses, Found = CheckOther(TempString, Bonuses);
			if ( not Found ) then
				Bonuses = CheckGeneric(TempString, Bonuses);
			end;
		end;
	else
		if ( string.sub(Line,0,10) == "|cffffffff" ) or ( string.sub(Line, 0, 10) == "|cffff2020" ) then
			NewLine = string.sub(Line, 11, -3);
			Line = NewLine;
			Line = string.gsub(Line, "%|$", "" );
		end;
		Bonuses, Found = CheckOther(Line, Bonuses);
		if ( not Found ) then
			Bonuses = CheckGeneric(Line, Bonuses);
		end;
	end;
	return Bonuses;
end;
local function ScanTooltip(ItemLink, Bonuses)
	MoPReforgeScannerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	MoPReforgeScannerTooltip:ClearLines();
	MoPReforgeScannerTooltip:SetHyperlink(ItemLink);
	local LeftText, Line, RightText, Line2, RightLine, Red, Green, Blue;
	local LineCount = MoPReforgeScannerTooltip:NumLines();
	for LineNumber = 1, LineCount do
		LeftText = _G["MoPReforgeScannerTooltipTextLeft"..LineNumber];
		if ( LeftText:GetText() ) then
			Line = LeftText:GetText();
			Red, Green, Blue = LeftText:GetTextColor();
			Red, Green, Blue = ceil(Red*255), ceil(Green*255), ceil(Blue*255);
			Bonuses = ScanLine(Line, Red, Green, Blue, Bonuses);
		end;
	end;
	return Bonuses;
end;
local function ScanItem(ItemLink)
	if ( not ItemLink ) or ( ItemLink == "") then return; end;
	return ScanTooltip(ItemLink, {});
end;
local function CheckReforge(ItemLink)
	local currentBonuses = ScanItem(ItemLink);
	local bonuses = {};
	local ItemSubStringTable = {};
	local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]")
	for v in string.gmatch(ItemSubString, "[^:]+") do tinsert(ItemSubStringTable, v); end
	ItemSubStringTable[10] = 0;
	ItemSubStringTable[11] = 0;
	local baseItem = strjoin(":", unpack(ItemSubStringTable));
	--local baseItem = "|Hitem:"..ItemSubStringTable[2]..":"..ItemSubStringTable[3]..;
	local ItemName, ItemLink, ItemQuality, ItemLevel, ItemReqLevel, ItemClass, ItemSubclass, ItemMaxStack, ItemEquipSlot, ItemTexture, ItemVendorPrice = GetItemInfo(baseItem);
	local originalBonuses = ScanItem(ItemLink);
	for i,v in pairs(currentBonuses) do
		bonuses[i] = tonumber(v) - tonumber(originalBonuses[i] or 0);
		if ( bonuses[i] == 0 ) then bonuses[i] = nil; end;
	end;
	return bonuses;
end;]]

--[[local prevItemLink
local prevDisplayCount
local maxDisplayCount = 2]]
local lastmodline
local modlinefound
local modsseparated
local modstatstotal = 0
local linetable = {}
local recipeFallbacks, recipeSpellFallbacks -- defined at the bottom
local function PerformTooltipChange(self)
    if not MoPItemTooltipEnabled then return end
    if self.mopitHandled then return end
    self.mopitHandled = true;
    local shopping, shoppingdelta
    if self:GetName():match("ShoppingTooltip") then
        shopping = true
    end
    -- if MoPItemTooltipDebug then
    --     print("run by", self:GetName()) -- Debug line
    -- end
    --[[local _,ItemLink = self:GetItem();
    if ItemLink ~= prevItemLink then
        prevItemLink = ItemLink
        prevDisplayCount = 0
    end]]
    local evermatched
    local rebuildtable = true
    --[[prevDisplayCount = prevDisplayCount + 1
    if prevDisplayCount >= maxDisplayCount then
        rebuildtable = false
        evermatched = true
    end]]
    local lines = self:NumLines()
    local name = self:GetName().."TextLeft"
    local rname = self:GetName().."TextRight"
    local tname = self:GetName().."Texture"
    local mname = self:GetName().."MoneyFrame"
    local lookingforlastmodline = true
    
    local isRecipe = false;
    local recipeProductStartLine;
    do
        local itemName, productName;
        for i = 1, lines do
            local line = _G[name..i]
            if i == 1 and line and line:IsShown() then
                itemName = line:GetText();
                local itemID = tonumber((select(2, self:GetItem()) or ""):match("item:(%d+)"));
                local spellID = select(3, self:GetSpell());
                local productID = itemID and recipeFallbacks[itemID] or spellID and recipeSpellFallbacks[spellID];
                productName = productID and GetItemInfo(productID) or (itemName or ""):match(".-: (.+)");
                productName = productName and "\n"..productName:utf8lower();
            end
            if i ~= 1 and line and line:IsShown() and productName and (line:GetText() or ""):utf8lower() == productName then
                isRecipe = true;
                recipeProductStartLine = i;
            end
        end
    end
    
    -- Build a table containing data about current tooltip
    if rebuildtable then
        lastmodline = nil
        modlinefound = nil
        linetable = {}
        local moneyframes = self.hasMoney and {} or nil
        for i = 1, lines do
            local line = _G[name..i]
            local rline = _G[rname..i]
            
            if line and MoPItemTooltipFaction then
                local linetext = line:GetText()
                if linetext == "Races: Human, Dwarf, Night Elf, Gnome, Draenei" or linetext == "Расы: Человек, Дворф, Ночной эльф, Гном, Дреней" then
                    line:SetText(factionReplacements[1])
                elseif linetext == "Races: Orc, Undead, Tauren, Troll, Blood Elf" or linetext == "Расы: Орк, Нежить, Таурен, Тролль, Эльф крови" then
                    line:SetText(factionReplacements[2])
                end
            end
            if shopping and line then
                local linetext = line:GetText()
                if linetext and linetext:match(ITEM_DELTA_DESCRIPTION) then
                    shoppingdelta = true
                end
            end
            local linetex
            for j = 1, 10 do
                local tex = _G[tname..j]
                if tex then
                    local _,parent = tex:GetPoint()
                    if parent == line and tex:IsShown() then
                        linetex = tex:GetTexture()
                        break
                    end
                end
            end
            local linemoney
            if moneyframes then
                for j = 1, self.numMoneyFrames do
                    local money = _G[mname..j]
                    local _,parent = money:GetPoint()
                    if parent == line and money:IsShown() then
                        linemoney = { money.staticMoney, money.moneyType, _G[mname..j.."PrefixText"]:GetText(), _G[mname..j.."SuffixText"]:GetText() }
                        break
                    end
                end
            end
            local r,g,b,a = line:GetTextColor()
            local rr,rg,rb,ra = rline:GetTextColor()
            local align = line:GetJustifyH()
            align = align == "CENTER" and "LEFT" or align
            local rtext = rline and rline:IsShown() and rline:GetText()
            rtext = rtext ~= "" and rtext
            local text = line:GetText()
            local wrap = false;
            if not rtext then
                if text:find(pattern_PETITION_TITLE)
                or text:find(pattern_GUILD_CHARTER_TITLE)
                -- missing item stats
                -- missing enchant conditions
                or text:find(pattern_FERAL_DRUID_ITEM_AP)
                or text:starts(ITEM_SPELL_TRIGGER_ONEQUIP)
                or text:starts(ITEM_SPELL_TRIGGER_ONPROC)
                or text:starts(ITEM_SPELL_TRIGGER_ONUSE)
                -- missing ITEM_REQ_SKILL
                or text:find(pattern_itemRecipeReagents) -- wrap in reagent list, it's prepended by \n
                -- missing charges
                or text:find(pattern_ITEM_SET_BONUS)
                or text:find(pattern_ITEM_SET_BONUS_GRAY)
                or text:find("^\".*\"$")
                or text:find(pattern_EQUIPMENT_SETS)
                or text:find(pattern_REFUND_TIME_REMAINING)
                or text:find(pattern_BIND_TRADE_TIME_REMAINING)
                or text:starts(SPELL_REAGENTS)
                then
                    wrap = true;
                end
            end
            linetable[i] = { text, rtext, r, g, b, rr, rg, rb, wrap, linetex, linemoney, align }
        end
    end
    --if shopping and not shoppingdelta then return end
    if rebuildtable then
        modsseparated = nil
        modstatstotal = 0
        --[[local _,ItemLink = self:GetItem();
        local forgedBonuses = CheckReforge(ItemLink);]]
        -- Scan all lines for item stat mods
        local start = recipeProductStartLine or 1;
        for i = start, lines do
            local line = _G[name..i]
            if line then
                local linetext = line:GetText()
                
                -- Search for last line containing item stat mods
                -- Also modify enchant and socket lines to reflect user specified colors
                if (linetext:starts("+") or linetext:starts("-")) and not linetable[i][10] and not linetext:match(pattern_PLUS_DAMAGE_TEMPLATE_WITH_SCHOOL) then
                    modlinefound = true
                    local r,g,b = line:GetTextColor()
                    if (r == 0 and g >= 0.999 and b == 0) or
                       (r >= 0.999 and g <= 0.13 and b <= 0.13) then
                        if lookingforlastmodline then
                            lastmodline = i - 1
                            lookingforlastmodline = false
                        end
                        if MoPItemTooltipEnchantText then
                            if MoPItemTooltipEnchantText:match("%%s") then
                                linetable[i][1] = MoPItemTooltipEnchantText:format(linetext)
                            else
                                linetable[i][1] = linetext.." "..MoPItemTooltipEnchantText
                            end
                            line:SetText(linetable[i][1])
                        end
                        if g >= 0.999 then
                            linetable[i][3], linetable[i][4], linetable[i][5] = unpack(MoPItemTooltipEnchantColor)
                            line:SetTextColor(linetable[i][3], linetable[i][4], linetable[i][5])
                        end
                    else
                        if lookingforlastmodline then
                            lastmodline = i
                        end
                    end
                elseif linetext:match(pattern_DPS_TEMPLATE_modified) or linetext:match(pattern_ARMOR_TEMPLATE) or linetext:match(pattern_SHIELD_BLOCK_TEMPLATE) then
                    modlinefound = true
                    if lookingforlastmodline then
                        lastmodline = i
                    end
                else
                    if lastmodline and lookingforlastmodline then
                        lookingforlastmodline = false
                    end
                end
                if (lookingforlastmodline or (not modsseparated and modlinefound)) and (
                   linetext:match(pattern_ITEM_MIN_LEVEL) or
                   linetext:match(pattern_ITEM_LEVEL) or
                   linetext:match(pattern_ITEM_MIN_SKILL) or
                   linetext:match(pattern_ITEM_LEVEL_RANGE) or
                   linetext:match(pattern_ITEM_LEVEL_AND_MIN) or
                   linetext:match(pattern_ITEM_LEVEL_RANGE_CURRENT) or
                   linetext:match(pattern_DURABILITY_TEMPLATE) or
                   linetext == factionReplacements[1] or
                   linetext == factionReplacements[2]
                    ) then
                    if lookingforlastmodline then
                        lastmodline = i - 1
                        lookingforlastmodline = false
                    end
                    if not modsseparated and modlinefound then
                        modsseparated = i + modstatstotal
                        evermatched = true
                    end
                end
                if linetext:starts(pattern_ITEM_SOCKET_BONUS_prefix) then
                    local match = linetext:match(pattern_ITEM_SOCKET_BONUS)
                    if MoPItemTooltipSocketText:match("%%s") then
                        linetable[i][1] = MoPItemTooltipSocketText:format(match)
                    else
                        linetable[i][1] = MoPItemTooltipSocketText.." "..match
                    end
                    line:SetText(linetable[i][1])
                    local r,g,b = line:GetTextColor()
                    if r == 0 and g >= 0.999 and b == 0 then
                        linetable[i][3], linetable[i][4], linetable[i][5] = unpack(MoPItemTooltipSocketColor)
                        line:SetTextColor(linetable[i][3], linetable[i][4], linetable[i][5])
                    end
                    if modlinefound then
                        modsseparated = i + 1
                        evermatched = true
                    end
                end
                
                -- Check if line matches "Equip: %c%d ..."
                local matches = false
                local feralcheck = modchecks["FERAL_DRUID_ITEM_AP"] or modchecks["ITEM_MOD_FERAL_ATTACK_POWER"]
                if feralcheck then
                    local match = linetext:match(feralcheck)
                    if match then
                        linetable[i][1] = match
                        line:SetText(linetable[i][1])
                        matches = true
                    end
                end
                if not matches and linetext:starts(ITEM_SPELL_TRIGGER_ONEQUIP) then
                    for mod,check in pairs(modchecks) do
                        local match = linetext:match(check)
                        if match then
                            local rep = modreplaces[mod]
                            if rep then
                                match = rep:format(tonumber(match))
                            end
                            linetable[i][1] = match
                            line:SetText(linetable[i][1])
                            --[[do
                                local from
                                for j,v in pairs(forgedBonuses) do
                                    if ( v < 0 ) then
                                        from = L[j] or j
                                        break;
                                    end;
                                end
                                for j,v in pairs(forgedBonuses) do
                                    if ( v > 0 ) then
                                        if linetable[i][1]:lower():match((L[j] or j):lower()) then
                                            linetable[i][1] = linetable[i][1].." (Reforged from "..from..")"
                                            line:SetText(linetable[i][1])
                                        end
                                        break;
                                    end;
                                end;
                            end]]
                            linetable[i][3], linetable[i][4], linetable[i][5] = unpack(MoPItemTooltipColor)
                            line:SetTextColor(linetable[i][3], linetable[i][4], linetable[i][5])
                            matches = true
                            break
                        end
                    end
                end
                
                -- Shift all previous lines down and place current line above
                if matches and lastmodline then
                    modlinefound = true
                    modstatstotal = modstatstotal + 1
                    if modsseparated then
                        modsseparated = modsseparated + 1
                    end
                    lastmodline = lastmodline + 1
                    local templine = linetable[i]
                    for j = i, lastmodline + 1, -1 do
                        linetable[j] = linetable[j - 1]
                    end
                    linetable[lastmodline] = templine
                    evermatched = true
                end
            end
        end
    end
    -- If any change to the tooltip is needed - rebuild whole tooltip (alas...)
    self:mopitClearModified();
    if evermatched or MoPItemTooltipItemLevel then
        if MoPItemTooltipSeparators and rebuildtable then
            if modsseparated then
                tinsert(linetable, modsseparated, { " " })
            end
            if modlinefound and modsseparated ~= lastmodline + 1 then
                tinsert(linetable, lastmodline + 1, { " " })
            end
        end
        lines = table.getn(linetable)
        local ilvlmoved
        if MoPItemTooltipItemLevel and rebuildtable then
            local start = recipeProductStartLine or 1;
            local newi = start + 1
            for i = start, math.min(start + 5, lines) do
                if linetable[i][1]:match(CURRENTLY_EQUIPPED) then
                    newi = i + 2
                    break
                end
                if linetable[i][1]:match(ITEM_HEROIC) or linetable[i][1]:match(ITEM_HEROIC_EPIC) then
                    newi = i + 1
                    break
                end
            end
            for i = 1, lines do
                if linetable[i][1]:match(pattern_ITEM_LEVEL) then
                    local temp = linetable[i]
                    temp[3] = 1
                    temp[4] = 0.824
                    temp[5] = 0
                    tremove(linetable, i)
                    tinsert(linetable, newi, temp)
                    ilvlmoved = true
                    break
                end
            end
        end
        if not ilvlmoved then return end
        if linetable[lines][1] == " " and not linetable[lines][2] and not linetable[lines][10] and not linetable[lines][11] then tremove(linetable, lines); end -- Remove trailing separator
        self.modifiedItemName, self.modifiedItemLink = self:origGetItem()
        self.modifiedSpellName, self.modifiedSpellRank, self.modifiedSpellID = self:origGetSpell()
        --print(self:GetName().."::: DATA : "..(self.modifiedItemName or "nil").. " : "..(self.modifiedItemLink or "nil"))
        local notfirst
        self:origClearLines()
        for i = 1, lines do
            local line = linetable[i] or { }
            if line[11] then
                SetTooltipMoney(self, unpack(line[11]))
            else
                if line[2] then
                    self:AddDoubleLine(line[1], line[2], line[3], line[4], line[5], line[6], line[7], line[8])
                else
                    self:AddLine(line[1], line[3], line[4], line[5], line[9])
                end
                local lastline = _G[self:GetName().."TextLeft"..self:NumLines()]
                if line[12] then
                    lastline:SetJustifyH(line[12])
                end
                if notfirst then
                    local a,b,c,x,y = lastline:GetPoint()
                    lastline:SetPoint(a,b,c,x,-2)
                end
                notfirst = true
                if line[10] then
                    self:AddTexture(line[10])
                end
            end
        end
    end
    
    return isRecipe;
end

-- Hooking handler to known tooltips
--[[local funcs = {
    "SetAction",
    "SetAuctionItem",        "SetAuctionSellItem",     "SetBagItem",
    "SetBuybackItem",        "SetGuildBankItem",       "SetHyperlinkCompareItem",
    "SetInboxItem",          "SetInventoryItem",       "SetInventoryItemByID",
    "SetItemByID",           "SetLootItem",            "SetLootRollItem",
    "SetMerchantCostItem",   "SetMerchantItem",        "SetMissingLootItem",
    "SetQuestItem",          "SetQuestLogSpecialItem", "SetReforgeItem",
    "SetSendMailItem",       "SetSocketedItem",        "SetTradePlayerItem",
    "SetTradeSkillItem",     "SetTradeTargetItem",     "SetTransmogrifyItem",
    "SetUpgradeItem",        "SetVoidDepositItem",     "SetVoidItem",
    "SetVoidWithdrawalItem",
}]]
local ignores = { "LibStatLogic", "TenTonHammerTooltip", "ShoppingTooltip", "MoPITCompTooltip" }
local hookedto = {}
local hooked
local HookTo

local function HookOverrides(frame)
    frame.origGetItem = frame.GetItem;
    frame.origGetSpell = frame.GetSpell;
    frame.origHide = frame.Hide;
    frame.origSetOwner = frame.SetOwner;
    frame.origClearLines = frame.ClearLines;
    function frame:GetItem(...)
        local name, link = self:origGetItem(...);
        name = name or self.modifiedItemName;
        link = link or self.modifiedItemLink;
        return name, link;
    end
    function frame:GetSpell(...)
        local name, rank, id = self:origGetSpell(...);
        name = name or self.modifiedSpellName;
        rank = rank or self.modifiedSpellRank;
        id   = id   or self.modifiedSpellID;
        return name, rank, id;
    end
    function frame:mopitClearModified()
        self.modifiedItemName, self.modifiedItemLink = nil;
        self.modifiedSpellName, self.modifiedSpellRank, self.modifiedSpellID = nil;
    end
    hooksecurefunc(frame, "Hide", frame.mopitClearModified);
    hooksecurefunc(frame, "SetOwner", frame.mopitClearModified);
    hooksecurefunc(frame, "ClearLines", frame.mopitClearModified);
end

local function HookToAllTooltips()
    if hooked then return end
    
    CreateFrame("GameTooltip", "MoPITCompTooltip", nil, "GameTooltipTemplate")
    MoPITCompTooltip:SetOwner(WorldFrame, "ANCHOR_NONE");
    MoPITCompTooltip:AddFontStrings(MoPITCompTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"), MoPITCompTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText"));
    for i = 1, 30 do MoPITCompTooltip:AddLine(" ") end
    MoPITCompTooltip:ClearLines()
        
    -- Fix tooltip bug, see http://wowwiki.wikia.com/wiki/UIOBJECT_GameTooltip#Example:_Looping_through_all_tooltip_lines
    local function EnumerateTooltipLines_helper(...)
        local seenLeft = false
        local seenRight = false
        for i = 1, select("#", ...) do
            local region = select(i, ...)
            if region and region:GetObjectType() == "FontString" then
                if region:GetName() == "MoPITCompTooltipTextLeft1" then
                    if seenLeft then
                        MoPITCompTooltipTextLeft9 = region
                    else
                        seenLeft = true
                    end
                end
                if region:GetName() == "MoPITCompTooltipTextRight1" then
                    if seenRight then
                        MoPITCompTooltipTextRight9 = region
                    else
                        seenRight = true
                    end
                end
                local text = region:GetText() -- string or nil
            end
        end
    end
    EnumerateTooltipLines_helper(MoPITCompTooltip:GetRegions())
    
    local frame = EnumerateFrames()
    while frame do
        local name = frame:GetName()
        if frame.SetBagItem and not hookedto[name] then
            local ignore
            if name then
                for k,v in pairs(ignores) do
                    if name:match(v) then
                        ignore = true
                        break
                    end
                end
            end
            if not ignore then
                -- if MoPItemTooltipDebug then print("hooking to", name) end -- Debug line
                HookTo(frame)
            end
            if name and name:match("ShoppingTooltip") then
                -- if MoPItemTooltipDebug then print("special hooking to", name) end -- Debug line
                local oSetHyperlinkCompareItem = frame.SetHyperlinkCompareItem
                frame.SetHyperlinkCompareItem = function(self, ...)
                    if not MoPItemTooltipEnabled then
                        return oSetHyperlinkCompareItem(self, ...)
                    end
                    self.mopitHandled = false
                    local link = select(1, ...)
                    local slot = select(2, ...)
                    local shift = select(3, ...)
                    MoPITCompTooltip:ClearLines()
                    MoPITCompTooltip:SetHyperlink(link)
                    local success = oSetHyperlinkCompareItem(self, link, slot, shift, MoPITCompTooltip)
                    if success then
                        PerformTooltipChange(self)
                    end
                    return success
                end
                HookOverrides(frame);
            end
        end
        frame = EnumerateFrames(frame)
    end
    
    hooked = true
end
HookTo = function(tooltip)
    if not tooltip then return end
    if not tooltip:GetName() then return end
    if hookedto[tooltip:GetName()] then return end
    hookedto[tooltip:GetName()] = true
    -- if MoPItemTooltipDebug then
    --     print("hooked to", tooltip:GetName()) -- Debug line
    -- end
    --[[for _,func in pairs(funcs) do
        local o = tooltip[func]
        tooltip[func] = function(self, ...)
            HookToAllTooltips()
            local result = o(self, ...)
            PerformTooltipChange(self, ...)
            self:Show()
            return result
        end
    end]]
    tooltip:HookScript("OnTooltipSetItem", function(self)
        self.mopitHandled = self.mopitWasRecipe or false;
        self.mopitWasRecipe = nil;
        HookToAllTooltips()
        self.mopitWasRecipe = PerformTooltipChange(self)
        if self.mopitWasRecipe then
            AceTimer:ScheduleTimer(function() self.mopitWasRecipe = nil; end, 0);
        end
        self:Show()
    end)
    --[[local oSetHyperlink = tooltip.SetHyperlink
    tooltip.SetHyperlink = function(self, ...)
        HookToAllTooltips()
        local result = oSetHyperlink(self, ...)
        local link = select(1, ...)
        local linktype = link:match("[^:]+")
        if linktype == "item" then
            PerformTooltipChange(self, ...)
            self:Show()
        end
        return result
    end]]
    hooksecurefunc(tooltip, "SetHyperlink", function() HookToAllTooltips(); end);
    HookOverrides(tooltip);
end

local function Toggle(ignorevar)
    if not ignorevar then
        MoPItemTooltipEnabled = not MoPItemTooltipEnabled
    end
    for mod,vals in pairs(backups) do
        _G[mod] = MoPItemTooltipEnabled and vals[2] or vals[1]
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        SetCVar("showItemLevel", "1");
        if not MoPItemTooltipEnabled then
            Toggle(true)
        end
        local tooltips = { GameTooltip, ItemRefTooltip }
        for _,tooltip in pairs(tooltips) do
            HookTo(tooltip)
        end
        local oSetItemRef = SetItemRef
        SetItemRef = function(...)
            HookToAllTooltips()
            local result = oSetItemRef(...)
            PerformTooltipChange(ItemRefTooltip, ...)
            ItemRefTooltip:Show()
            return result
        end
    end
    if event == "ADDON_LOADED" and arg1 == "AtlasLoot" then
        HookTo(AtlasLootTooltipTEMP);
    end
end)

SlashCmdList["MOPITEMTOOLTIP"] = function(msg)
    if not msg or msg == "" then
        Toggle()
        return
    end
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    command = command:lower()
    if command == "toggle" then
        Toggle()
    elseif command == "color" then
        local r, g, b = rest:match("(%S+)%s+(%S+)%s+(%S+)");
        if r ~= nil and g ~= nil and b ~= nil and tonumber(r) and tonumber(g) and tonumber(b) then
            MoPItemTooltipColor = { tonumber(r), tonumber(g), tonumber(b) }
        else
            local found
            for k,v in pairs(Colors) do
                if v[1] == MoPItemTooltipColor[1] and
                   v[2] == MoPItemTooltipColor[2] and
                   v[3] == MoPItemTooltipColor[3] then
                    local len = table.getn(Colors)
                    local i = mod(k, len)
                    MoPItemTooltipColor = Colors[i + 1]
                    found = true
                    break
                end
            end
            if not found then MoPItemTooltipColor = Colors[1] end
        end
    elseif command == "enchantcolor" then
        local r, g, b = rest:match("(%S+)%s+(%S+)%s+(%S+)");
        if r ~= nil and g ~= nil and b ~= nil and tonumber(r) and tonumber(g) and tonumber(b) then
            MoPItemTooltipEnchantColor = { tonumber(r), tonumber(g), tonumber(b) }
        else
            local found
            for k,v in pairs(Colors) do
                if v[1] == MoPItemTooltipEnchantColor[1] and
                   v[2] == MoPItemTooltipEnchantColor[2] and
                   v[3] == MoPItemTooltipEnchantColor[3] then
                    local len = table.getn(Colors)
                    local i = mod(k, len)
                    MoPItemTooltipEnchantColor = Colors[i + 1]
                    found = true
                    break
                end
            end
            if not found then MoPItemTooltipEnchantColor = Colors[1] end
        end
    elseif command == "socketcolor" then
        local r, g, b = rest:match("(%S+)%s+(%S+)%s+(%S+)");
        if r ~= nil and g ~= nil and b ~= nil and tonumber(r) and tonumber(g) and tonumber(b) then
            MoPItemTooltipSocketColor = { tonumber(r), tonumber(g), tonumber(b) }
        else
            local found
            for k,v in pairs(Colors) do
                if v[1] == MoPItemTooltipSocketColor[1] and
                   v[2] == MoPItemTooltipSocketColor[2] and
                   v[3] == MoPItemTooltipSocketColor[3] then
                    local len = table.getn(Colors)
                    local i = mod(k, len)
                    MoPItemTooltipSocketColor = Colors[i + 1]
                    found = true
                    break
                end
            end
            if not found then MoPItemTooltipSocketColor = Colors[1] end
        end
    elseif command == "enchanttext" then
        MoPItemTooltipEnchantText = rest:gsub("\\n", "\n")
    elseif command == "sockettext" then
        MoPItemTooltipSocketText = rest:gsub("\\n", "\n")
    elseif command == "separators" or command == "seps" or command == "sep" then
        MoPItemTooltipSeparators = not MoPItemTooltipSeparators
    elseif command == "itemlevel" or command == "itemlvl" or command == "ilvl" or command == "level" or command == "lvl" or command == "il" then
        MoPItemTooltipItemLevel = not MoPItemTooltipItemLevel
    elseif command == "faction" then
        MoPItemTooltipFaction = not MoPItemTooltipFaction
    elseif command == "debug" then
        MoPItemTooltipDebug = not MoPItemTooltipDebug
    elseif command == "resetdefaults" then
        InitDefaultSettings();
    elseif command == "hook" then
        hooked = false
        HookToAllTooltips()
    end
end
SLASH_MOPITEMTOOLTIP1 = "/mopitemtooltips"
SLASH_MOPITEMTOOLTIP2 = "/mopitemtooltip"
SLASH_MOPITEMTOOLTIP3 = "/mopitem"
SLASH_MOPITEMTOOLTIP4 = "/moptooltips"
SLASH_MOPITEMTOOLTIP5 = "/mopit"

recipeFallbacks =
{
    -- Mismatched enGB recipe name and product name
    [21940]=21756,[21949]=21769,[21944]=21763,[24183]=24128,[21943]=21760,[31358]=24125,[24182]=24127,[24179]=24124,[21941]=21758,[21953]=21777,[21955]=21784,[21956]=21789,[24180]=24125,[24181]=24126,
    -- Mismatched ruRU recipe name and product name
    [8403]=8210,[8404]=8211,[8405]=8214,[8406]=8213,[8407]=8212,[8408]=8215,[10605]=10502,[12705]=12422,[14470]=13857,[14488]=13864,[15738]=15078,[15753]=15056,[16045]=15999,[23628]=23539,[29729]=29508,[23800]=23747,[23611]=23520,[23612]=23521,[23613]=23522,[23620]=23531,[24162]=24086,[35190]=35182,[35192]=35184,[35194]=34356,[35195]=34354,[35197]=34353,[35198]=34362,[35199]=34363,[35202]=34360,[35204]=34366,[35214]=34370,[35187]=35185,[46108]=45854,
};
recipeSpellFallbacks =
{
    -- Mismatched spell name and product name
    [26407]=21542,[32499]=25697,[32499]=25697,[26407]=21542,
};
