local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local floor = math.floor;
local format = string.format;
local gsub = string.gsub;

local GetKeyText
do
	local keyButton = gsub(KEY_BUTTON4, '%d', '')
	local keyNumpad = gsub(KEY_NUMPAD1, '%d', '')
	local displaySubs = {
		{ '('..keyButton..')', 'M' },
		{ '('..keyNumpad..')', 'N' },
		{ '(a%-)', 'a' },
		{ '(c%-)', 'c' },
		{ '(s%-)', 's' },
		{ KEY_BUTTON3, 'M3' },
		{ KEY_MOUSEWHEELUP, 'MU' },
		{ KEY_MOUSEWHEELDOWN, 'MD' },
		{ KEY_SPACE, 'BAR' },
		{ CAPSLOCK_KEY_TEXT, 'CL' },
		{ KEY_NUMLOCK, 'NL' },
		{ 'BUTTON', 'M' },
		{ 'NUMPAD', 'N' },
		{ '(ALT%-)', 'a' },
		{ '(CTRL%-)', 'c' },
		{ '(SHIFT%-)', 's' },
		{ 'MOUSEWHEELUP', 'MU' },
		{ 'MOUSEWHEELDOWN', 'MD' },
		{ 'SPACE', 'BAR' },
		{ '0 (цифр. кл.)', 'N0' },
		{ '1 (цифр. кл.)', 'N1' },
		{ '2 (цифр. кл.)', 'N2' },
		{ '3 (цифр. кл.)', 'N3' },
		{ '4 (цифр. кл.)', 'N4' },
		{ '5 (цифр. кл.)', 'N5' },
	};

	-- returns formatted key for text.
	-- @param key - a hotkey name
	function GetKeyText(key)
		if not key then return '' end
		for _,value in pairs(displaySubs) do
			key = gsub(key, value[1], value[2])
		end
		return key or error('invalid key string: '..tostring(key))
	end
end
addon.GetKeyText = GetKeyText

-- Blizzard Interface > Status Text (WotLK 3.3.5)
-- CVars: playerStatusText / petStatusText / partyStatusText / targetStatusText (0|1)
--        statusTextPercentage (0 = numeric, 1 = percent)
local STATUS_TEXT_CVARS = {
	playerStatusText = true,
	petStatusText = true,
	partyStatusText = true,
	targetStatusText = true,
	statusTextPercentage = true,
}

local statusTextListeners = {}

function addon.StatusTextIsShown(kind)
	local cvar = kind .. "StatusText"
	local ok, value = pcall(GetCVar, cvar)
	if not ok or value == nil then
		return true
	end
	return tostring(value) == "1"
end

-- Blizzard TextStatusBar: CVar on = always show; CVar off = show only while hovering.
function addon.StatusTextVisible(kind, hovering)
	if addon.StatusTextIsShown(kind) then
		return true
	end
	return hovering and true or false
end

function addon.StatusTextUsePercent()
	if GetCVarBool then
		local ok, value = pcall(GetCVarBool, "statusTextPercentage")
		if ok then return value and true or false end
	end
	local ok, value = pcall(GetCVar, "statusTextPercentage")
	if not ok or value == nil then
		return false
	end
	return tostring(value) == "1"
end

function addon.FormatStatusText(current, maxValue, usePercent)
	current = tonumber(current) or 0
	maxValue = tonumber(maxValue) or 0
	if usePercent then
		if maxValue <= 0 then return "0%" end
		return math.floor((current / maxValue) * 100 + 0.5) .. "%"
	end
	local curStr, maxStr = tostring(math.floor(current + 0.5)), tostring(math.floor(maxValue + 0.5))
	if TextStatusBar_CapDisplayOfNumericValue then
		curStr = TextStatusBar_CapDisplayOfNumericValue(curStr)
		maxStr = TextStatusBar_CapDisplayOfNumericValue(maxStr)
	end
	return curStr .. " / " .. maxStr
end

function addon.RegisterStatusTextListener(fn)
	if type(fn) == "function" then
		table.insert(statusTextListeners, fn)
	end
end

function addon.NotifyStatusTextListeners()
	for i = 1, #statusTextListeners do
		pcall(statusTextListeners[i])
	end
end

_G.DrakeishUI_StatusTextIsShown = addon.StatusTextIsShown
_G.DrakeishUI_StatusTextVisible = addon.StatusTextVisible
_G.DrakeishUI_StatusTextUsePercent = addon.StatusTextUsePercent
_G.DrakeishUI_FormatStatusText = addon.FormatStatusText
_G.DrakeishUI_RegisterStatusTextListener = addon.RegisterStatusTextListener
_G.DrakeishUI_NotifyStatusTextListeners = addon.NotifyStatusTextListeners

local statusTextWatcher = CreateFrame("Frame")
statusTextWatcher:RegisterEvent("CVAR_UPDATE")
statusTextWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
statusTextWatcher:SetScript("OnEvent", function(self, event, cvar)
	if event == "PLAYER_ENTERING_WORLD" then
		addon.NotifyStatusTextListeners()
		return
	end
	-- WotLK may pass CVar name or STATUS_TEXT_* label
	local key = cvar and tostring(cvar) or ""
	if key == "" or STATUS_TEXT_CVARS[key] or string.find(string.lower(key), "status") then
		addon.NotifyStatusTextListeners()
	end
end)
