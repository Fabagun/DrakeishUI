local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;



local customPartyFrames = {}
local partyFramesVisible = true
local partyFrameScale = 0.9 -- Default scale

-- List of addons that replace party frames (similar to how Blizzard frames hide)
local competingAddons = {
    "CompactRaidFrame",
    "oUF", -- oUF and its layouts
    "ShadowedUnitFrames",
    "PitBull4",
    "Grid",
    "Grid2",
    "VuhDo",
    "ElvUI", -- ElvUI has its own party frames
}

-- Function to check if any competing addon is loaded
local function IsCompetingAddonLoaded()
    for _, addonName in ipairs(competingAddons) do
        if IsAddOnLoaded(addonName) then
            return true
        end
    end
    return false
end

-- Function to update party frame visibility based on competing addons
local function UpdatePartyFrameVisibilityForCompetingAddons()
    local shouldHide = IsCompetingAddonLoaded()
    
    if shouldHide then
        -- Hide all custom party frames when competing addon is loaded
        for i = 1, 4 do
            local frame = customPartyFrames[i]
            if frame then
                frame:Hide()
            end
        end
        -- Also hide the toggle button
        if partyToggleButton then
            partyToggleButton:Hide()
        end
    else
        -- Show frames based on normal logic (party_state, unit existence, etc.)
        if partyToggleButton then
            partyToggleButton:Show()
        end
        -- Visibility will be handled by existing UpdatePartyFrame logic
    end
    
    return shouldHide
end

-- Function to update party frame positions based on unitframe toggle state
function UpdatePartyFramePositions()
    if customPartyFrames[1] then
        local orbsActive = (_G.diablo_orbs_state == 1)
        local useTopPosition = (unitframes_state == 1) or orbsActive
        local petOrbEnabled = _G.D32CharacterData and _G.D32CharacterData.petOrb and _G.D32CharacterData.petOrb.enabled
        -- Reserve space above party for Blizzard PetFrame when Diablo orbs are on but pet orb is off.
        -- Skip when raid frames own the rectangular pet (Blizzard PetFrame stays hidden).
        local hidePetFrame = (_G.hide_pet_frame_state or 0) == 1
        local raidOwnsPet = _G.DrakeishUI_ShouldShowRaidStylePet and _G.DrakeishUI_ShouldShowRaidStylePet()
        local reservePetSpace = orbsActive and not petOrbEnabled and not hidePetFrame and UnitExists("pet") and not raidOwnsPet
        local PET_SPACE = 60

        if useTopPosition then
            local y = -14
            if reservePetSpace then
                y = -14 - PET_SPACE
            end
            customPartyFrames[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, y)
        else
            -- Normal position when unitframes are in original positions
            customPartyFrames[1]:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -200)
        end
        
        -- Also update the party toggle button position
        UpdatePartyToggleButtonPosition()
    end
    if _G.DrakeishUI_UpdateRaidFramePositions then
        _G.DrakeishUI_UpdateRaidFramePositions()
    end
end

-- Function to update party toggle button position
function UpdatePartyToggleButtonPosition()
    if not partyToggleButton then return end
    partyToggleButton:ClearAllPoints()
    -- While raid frames are active, sit next to the first raid unit (same offset as party)
    if _G.DrakeishUI_RaidModeActive and _G.DrakeishUI_RaidModeActive() and _G.DrakeishUI_RaidFrames then
        local root = _G.DrakeishUI_RaidFrames
        if root:IsShown() then
            partyToggleButton:SetPoint("TOPLEFT", root, "TOPLEFT", -15, -10)
            return
        end
    end
    if customPartyFrames[1] then
        partyToggleButton:SetPoint("TOPLEFT", customPartyFrames[1], "TOPLEFT", -15, -10)
    else
        partyToggleButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, -190)
    end
end
_G.UpdatePartyToggleButtonPosition = UpdatePartyToggleButtonPosition

-- Function to update party frame scale
function UpdatePartyFrameScale()
    for i = 1, 4 do
        local frame = customPartyFrames[i]
        if frame then
            frame:SetScale(partyFrameScale)
        end
    end
end

-- Function to set party frame scale
function SetPartyFrameScale(scale)
    partyFrameScale = scale or 1.0
    UpdatePartyFrameScale()
    -- print("Party frame scale set to:", partyFrameScale) -- Debug line
end

-- Hook into party frame positioning to update button position only when needed
local function HookPartyFramePositioning()
    if customPartyFrames[1] then
        -- Hook the SetPoint method of the first party frame
        local originalSetPoint = customPartyFrames[1].SetPoint
        customPartyFrames[1].SetPoint = function(self, ...)
            originalSetPoint(self, ...)
            -- Only update button position if unitframes are in DragonflightUI position
            -- This prevents overriding manual position changes when unitframes are in normal position
            if unitframes_state == 1 then
                UpdatePartyToggleButtonPosition()
            end
        end
    end
end


local function HideDefaultPartyFrames()
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame"..i]
        if frame then
            frame:UnregisterAllEvents()
            frame:Hide()
            frame:SetScript("OnShow", frame.Hide)
        end
    end
end

-- UTF-8 helpers (WotLK has no string.utf8sub; strlenutf8 exists)
local function PartyUtf8Len(s)
    local _, n = string.gsub(s, "[^\128-\191]", "")
    return n
end

local function PartyUtf8Sub(s, startChar, endChar)
    if not s or s == "" then return "" end
    startChar = startChar or 1
    endChar = endChar or -1
    local len = PartyUtf8Len(s)
    if endChar < 0 then
        endChar = len + endChar + 1
    end
    if startChar < 1 then startChar = 1 end
    if endChar > len then endChar = len end
    if startChar > endChar then return "" end

    local i = 1
    local bytes = #s
    local charIndex = 0
    local startByte, endByte
    while i <= bytes do
        local b = string.byte(s, i)
        local charBytes = 1
        if b >= 240 then
            charBytes = 4
        elseif b >= 224 then
            charBytes = 3
        elseif b >= 192 then
            charBytes = 2
        end
        charIndex = charIndex + 1
        if charIndex == startChar then
            startByte = i
        end
        if charIndex == endChar then
            endByte = i + charBytes - 1
            break
        end
        i = i + charBytes
    end
    if not startByte then return "" end
    return string.sub(s, startByte, endByte or bytes)
end

-- Truncate party name so it never overlaps the level text
local function SetPartyNameTruncated(frame, name)
    local fontString = frame.name
    local levelString = frame.level
    if not fontString then return end

    name = name or "Unknown"
    fontString:SetText(name)

    -- Space from name left edge to level left edge (with padding)
    local maxWidth = 52
    if levelString and frame:GetWidth() then
        local levelWidth = levelString:GetStringWidth() or 14
        -- portrait(4+40) + gap(10) ... level anchored RIGHT -16
        maxWidth = frame:GetWidth() - 16 - levelWidth - 4 - (4 + 40 + 10)
        if maxWidth < 24 then maxWidth = 24 end
    end

    fontString:SetWidth(maxWidth)
    fontString:SetWordWrap(false)
    fontString:SetNonSpaceWrap(false)

    if fontString:GetStringWidth() <= maxWidth then
        return
    end

    local ellipsis = ".."
    local len = PartyUtf8Len(name)
    while len > 1 do
        len = len - 1
        local truncated = PartyUtf8Sub(name, 1, len) .. ellipsis
        fontString:SetText(truncated)
        if fontString:GetStringWidth() <= maxWidth then
            return
        end
    end
end

local function UpdatePartyFrame(frame, unit)
    -- First check if competing addon is loaded - if so, hide frame
    if IsCompetingAddonLoaded() then
        frame:Hide()
        return
    end

    -- Compact raid mode takes over while in a raid with raid toggle on
    if _G.DrakeishUI_RaidModeActive and _G.DrakeishUI_RaidModeActive() then
        frame:Hide()
        return
    end
    
    if UnitExists(unit) then
    if party_state ~= 1 then
        frame:Show()
    else
        frame:Hide()
    end
        SetPortraitTexture(frame.portrait, unit)
        local name = UnitName(unit) or "Unknown"
local _, class = UnitClass(unit)
local color = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
-- Make colors 10% more vibrant
local vibrantR = math.min(1, color.r * 1.1)
local vibrantG = math.min(1, color.g * 1.1)
local vibrantB = math.min(1, color.b * 1.1)
        local level = UnitLevel(unit) or "??"
frame.level:SetText(level)
frame.level:SetTextColor(vibrantR, vibrantG, vibrantB)
        -- Truncate after level is set so width calculation can reserve space for it
        SetPartyNameTruncated(frame, name)
frame.name:SetTextColor(vibrantR, vibrantG, vibrantB)

        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)
        frame.healthBar:SetMinMaxValues(0, maxHealth)
        frame.healthBar:SetValue(health)

        local power = UnitPower(unit)
        local maxPower = UnitPowerMax(unit)
        frame.powerBar:SetMinMaxValues(0, maxPower)
        frame.powerBar:SetValue(power)

        -- Status text: always update values; show if CVar on OR mouseover
        local usePercent = DrakeishUI_StatusTextUsePercent and DrakeishUI_StatusTextUsePercent()
        local fmt = DrakeishUI_FormatStatusText
        if fmt then
            frame.healthText:SetText(fmt(health, maxHealth, usePercent))
            frame.powerText:SetText(fmt(power, maxPower, usePercent))
        else
            frame.healthText:SetText(health .. " / " .. maxHealth)
            local powerPercent = maxPower > 0 and math.floor((power / maxPower) * 100) or 0
            frame.powerText:SetText(powerPercent .. "%")
        end
        local showText = true
        if DrakeishUI_StatusTextVisible then
            showText = DrakeishUI_StatusTextVisible("party", frame.statusTextHover)
        elseif DrakeishUI_StatusTextIsShown then
            showText = DrakeishUI_StatusTextIsShown("party") or frame.statusTextHover
        end
        if showText then
            frame.healthText:Show()
            frame.powerText:Show()
        else
            frame.healthText:Hide()
            frame.powerText:Hide()
        end
        
        -- Set health bar color to class color (10% more vibrant)
        frame.healthBar:SetStatusBarColor(vibrantR, vibrantG, vibrantB)

       local powerType = UnitPowerType(unit)
       local color = PowerBarColor[powerType] or PowerBarColor["MANA"]
       
       -- Lighten mana bar color
       if powerType == 0 then  -- 0 = MANA
           frame.powerBar:SetStatusBarColor(0.1, 0.5, 1.0)  -- light blue
       else
           frame.powerBar:SetStatusBarColor(color.r, color.g, color.b)
       end
    else
        frame:Hide()
    end
end


local function CreateCustomPartyFrames()
    -- Check if competing addon is loaded before creating frames
    if IsCompetingAddonLoaded() then
        return
    end
    
    local playerFrame = _G["PlayerFrame"]

    for i = 1, 4 do
        local unit = "party"..i
        local frame = customPartyFrames[i]
        local r, g, b = GameFontNormal:GetTextColor()

        if not frame then
            frame = CreateFrame("Button", "CustomPartyFrame"..i, UIParent, "SecureUnitButtonTemplate")
            frame:SetSize(140, 40)
            frame:SetScale(partyFrameScale)
            frame:RegisterForClicks("AnyUp")
            frame:SetAttribute("unit", unit)
            frame:SetAttribute("*type1", "target")
            frame:SetAttribute("*type2", "togglemenu")
            customPartyFrames[i] = frame

            -- Portrait
            frame.portrait = frame:CreateTexture(nil, "ARTWORK")
            frame.portrait:SetDrawLayer("ARTWORK", 1)
            frame.portrait:SetSize(40, 40)
            frame.portrait:SetPoint("LEFT", frame, "LEFT", 4, 0)

            -- Name (truncated in UpdatePartyFrame so it never overlaps level)
            frame.name = frame:CreateFontString(nil, "OVERLAY")
            frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            frame.name:SetPoint("TOPLEFT", frame.portrait, "TOPRIGHT", 10, 2)
            frame.name:SetText("Offline")
            frame.name:SetTextColor(r, g, b)
			frame.name:SetShadowColor(0, 0, 0, 0.7)
            frame.name:SetShadowOffset(1, -1)
			frame.name:SetWidth(52)
            frame.name:SetWordWrap(false)
            frame.name:SetNonSpaceWrap(false)
            frame.name:SetJustifyH("LEFT")

            -- Level (drawn above name so it stays readable if anything overlaps)
            frame.level = frame:CreateFontString(nil, "OVERLAY")
            frame.level:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            frame.level:SetPoint("RIGHT", frame, "RIGHT", -16, 17)
            frame.level:SetJustifyH("RIGHT")
            frame.level:SetText("??")
            frame.level:SetTextColor(r, g, b)
			frame.level:SetShadowColor(0, 0, 0, 0.7)
            frame.level:SetShadowOffset(1, -1)
            frame.level:SetDrawLayer("OVERLAY", 7)

            -- Health bar
            frame.healthBar = CreateFrame("StatusBar", nil, frame)
            frame.healthBar:SetStatusBarTexture("Interface\\AddOns\\DrakeishUI\\assets\\DF-StatusBar")
            frame.healthBar:SetPoint("TOPLEFT", frame.portrait, "TOPRIGHT", 0, -12)
            frame.healthBar:SetSize(85, 11)
            frame.healthBar:SetStatusBarColor(1, 1, 1) -- Default white, will be updated with class color
            frame.healthBar:SetFrameLevel(frame:GetFrameLevel() + 1)
            frame.healthBar:EnableMouse(false)

           -- Health text
            frame.healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
            frame.healthText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
            frame.healthText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            frame.healthText:SetTextColor(1, 1, 1)

            -- Power bar
            frame.powerBar = CreateFrame("StatusBar", nil, frame)
            frame.powerBar:SetStatusBarTexture("Interface\\AddOns\\DrakeishUI\\assets\\DF-StatusBar")
            frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", -2, -2)
            frame.powerBar:SetSize(87, 7)
            frame.powerBar:SetFrameLevel(frame:GetFrameLevel() + 1)
            frame.powerBar:EnableMouse(false)
			
			-- Power text
            frame.powerText = frame.powerBar:CreateFontString(nil, "OVERLAY")
            frame.powerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")  -- You can adjust font size
            frame.powerText:SetPoint("CENTER", frame.powerBar, "CENTER", 0, 0)
            frame.powerText:SetTextColor(1, 1, 1)

            -- Overlay
            frame.overlayFrame = CreateFrame("Frame", nil, frame)
            frame.overlayFrame:SetAllPoints(frame)
            frame.overlayFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
            frame.overlayFrame:EnableMouse(false)

            frame.overlay = frame.overlayFrame:CreateTexture(nil, "ARTWORK")
            frame.overlay:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\PartyFrames")
            frame.overlay:SetSize(150, 75)
            frame.overlay:SetPoint("CENTER", frame, "CENTER", 0, -9)

            -- Background
            frame.bgFrame = CreateFrame("Frame", nil, frame)
            frame.bgFrame:SetAllPoints(frame)
            frame.bgFrame:SetFrameLevel(frame:GetFrameLevel() - 1)
            frame.bgFrame:EnableMouse(false)

            frame.background = frame.bgFrame:CreateTexture(nil, "BACKGROUND")
            frame.background:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\PartyFramesBackground")
            frame.background:SetSize(150, 75)
            frame.background:SetPoint("CENTER", frame, "CENTER", 0, -9)
			
        end
		
frame.statusTextHover = false

local function ApplyPartyStatusTextVisibility(self)
    if not self.healthText or not self.powerText then return end
    local show = true
    if DrakeishUI_StatusTextVisible then
        show = DrakeishUI_StatusTextVisible("party", self.statusTextHover)
    elseif DrakeishUI_StatusTextIsShown then
        show = DrakeishUI_StatusTextIsShown("party") or self.statusTextHover
    else
        show = self.statusTextHover
    end
    if show then
        self.healthText:Show()
        self.powerText:Show()
    else
        self.healthText:Hide()
        self.powerText:Hide()
    end
end

frame:SetScript("OnEnter", function(self)
    self.statusTextHover = true
    ApplyPartyStatusTextVisibility(self)
    local unit = self:GetAttribute("unit")
    if UnitExists(unit) then
        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE") -- Clear mouse anchor
        GameTooltip:SetPoint("TOPLEFT", _G["PartyMemberFrame"..self:GetID()], "TOPRIGHT", -250, -850) -- Anchor to default Blizzard party frame position
        GameTooltip:SetUnit(unit)
        
        -- Make party member name green
        local nameLine = _G["GameTooltipTextLeft1"]
        if nameLine then
            nameLine:SetTextColor(0, 1, 0) -- Green color
        end
        
        GameTooltip:Show()
    end
end)

frame:SetScript("OnLeave", function(self)
    self.statusTextHover = false
    ApplyPartyStatusTextVisibility(self)
    GameTooltip:Hide()
end)

-- Custom right-click handler for party frame menu
frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        local unit = self:GetAttribute("unit")
        if UnitExists(unit) then
            -- Show the Blizzard party frame dropdown menu
            local dropdown = _G["PartyMemberFrame"..i.."DropDown"]
            if dropdown then
                ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
            else
                -- Fallback: create a temporary dropdown
                local tempFrame = CreateFrame("Frame", "TempPartyDropDown", UIParent, "UIDropDownMenuTemplate")
                tempFrame.unit = unit
                tempFrame.name = UnitName(unit)
                tempFrame.id = i
                tempFrame.initialize = function(self, level)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = self.name
                    info.isTitle = 1
                    info.notCheckable = 1
                    UIDropDownMenu_AddButton(info, level)
                    
                    info = UIDropDownMenu_CreateInfo()
                    info.text = "Target"
                    info.notCheckable = 1
                    info.func = function() TargetUnit(self.unit) end
                    UIDropDownMenu_AddButton(info, level)
                    
                    info = UIDropDownMenu_CreateInfo()
                    info.text = "Whisper"
                    info.notCheckable = 1
                    info.func = function() ChatFrame_SendTell(self.name) end
                    UIDropDownMenu_AddButton(info, level)
                    
                    if UnitIsGroupLeader("player") then
                        info = UIDropDownMenu_CreateInfo()
                        info.text = "Remove from Party"
                        info.notCheckable = 1
                        info.func = function() UninviteUnit(self.name) end
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
                ToggleDropDownMenu(1, nil, tempFrame, "cursor", 0, 0)
            end
        end
    end
end)


        if i == 1 then
            -- Check if unitframes are in DragonflightUI position or Diablo orbs are active
            local orbsActive = (_G.diablo_orbs_state == 1)
            local petOrbEnabled = _G.D32CharacterData and _G.D32CharacterData.petOrb and _G.D32CharacterData.petOrb.enabled
            local hidePetFrame = (_G.hide_pet_frame_state or 0) == 1
            local raidOwnsPet = _G.DrakeishUI_ShouldShowRaidStylePet and _G.DrakeishUI_ShouldShowRaidStylePet()
            local reservePetSpace = orbsActive and not petOrbEnabled and not hidePetFrame and UnitExists("pet") and not raidOwnsPet
            if unitframes_state == 1 or orbsActive then
                local y = -14
                if reservePetSpace then
                    y = -14 - 60
                end
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, y)
            else
                -- Normal position when unitframes are in original positions
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -200)
            end
        else
            frame:SetPoint("TOPLEFT", customPartyFrames[i - 1], "BOTTOMLEFT", 0, -20)
        end

        UpdatePartyFrame(frame, unit)
        
        -- Update party toggle button position after frames are created
        if i == 1 then
            -- Only update if unitframes are in DragonflightUI position
            if unitframes_state == 1 then
                UpdatePartyToggleButtonPosition()
            end
            -- Hook into party frame positioning for automatic updates
            HookPartyFramePositioning()
        end
    end
end




-- FRAME EVENTS
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("PARTY_LEADER_CHANGED")
f:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
f:RegisterEvent("UNIT_NAME_UPDATE")
f:RegisterEvent("ADDON_LOADED") -- Register for addon load events


f:SetScript("OnEvent", function(self, event, arg1)
    HideDefaultPartyFrames()
    
    -- Check for competing addons on ADDON_LOADED event
    if event == "ADDON_LOADED" then
        -- Check if the loaded addon is in our competing list
        for _, addonName in ipairs(competingAddons) do
            if arg1 == addonName then
                -- Competing addon just loaded, hide our frames
                UpdatePartyFrameVisibilityForCompetingAddons()
                return
            end
        end
        return
    end
    
    if event == "PLAYER_LOGIN" then
        -- Check for competing addons on login
        if UpdatePartyFrameVisibilityForCompetingAddons() then
            return -- Don't show frames if competing addon is loaded
        end
        -- Handle saved state restoration on login
        CreateCustomPartyFrames()
        -- Update frame visibility based on both toggle state and party membership
        for i = 1, 4 do
            local frame = customPartyFrames[i]
            if frame then
                -- Check party_state first (if it exists)
                if party_state == 1 then
                    frame:Hide()
                elseif partyFramesVisible then
                    -- Only show frame if there's an actual party member
                    local unit = "party"..i
                    if UnitExists(unit) then
                        frame:Show()
                    else
                        frame:Hide()
                    end
                else
                    frame:Hide()
                end
            end
        end
        
        -- Update party toggle button position after frames are created
        -- Only update if unitframes are in DragonflightUI position
        if unitframes_state == 1 then
            UpdatePartyToggleButtonPosition()
        end
        -- Hook into party frame positioning for automatic updates
        HookPartyFramePositioning()

    elseif event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_NAME_UPDATE" then
        if arg1 and string.find(arg1, "party") then
            local index = tonumber(string.match(arg1, "%d"))
            if index and customPartyFrames[index] then
                UpdatePartyFrame(customPartyFrames[index], arg1)
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or 
           event == "PARTY_MEMBERS_CHANGED" or event == "PARTY_LEADER_CHANGED" or 
           event == "PARTY_LOOT_METHOD_CHANGED" then
        -- Check for competing addons first
        if UpdatePartyFrameVisibilityForCompetingAddons() then
            return -- Don't show frames if competing addon is loaded
        end
        
        -- Ensure frames exist
        if not customPartyFrames[1] then
            CreateCustomPartyFrames()
        end
        
        -- Update all party frames based on current party state
        for i = 1, 4 do
            local frame = customPartyFrames[i]
            if frame then
                local unit = "party"..i
                -- Check if party_state is set to hide frames
                if party_state == 1 then
                    frame:Hide()
                else
                    -- Show/hide based on whether unit exists
                    if UnitExists(unit) then
                        frame:Show()
                        UpdatePartyFrame(frame, unit)
                    else
                        frame:Hide()
                    end
                end
            end
        end
        
        -- Update party toggle button position after frames are created
        -- Only update if unitframes are in DragonflightUI position
        if unitframes_state == 1 then
            UpdatePartyToggleButtonPosition()
        end
        -- Hook into party frame positioning for automatic updates
        HookPartyFramePositioning()
    end
end)

partyToggleButton = CreateFrame('CheckButton', 'partytoggle', UIParent)
do
	partyToggleButton:SetSize(10, 14)
	partyToggleButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, -190)
	partyToggleButton:SetAlpha(0.3)
	partyToggleButton:SetNormalTexture''
	partyToggleButton:SetPushedTexture''
	partyToggleButton:SetHighlightTexture''
	partyToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = partyToggleButton:GetNormalTexture()
	normal:set_atlas('bag-arrow-2x')

	local pushed = partyToggleButton:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = partyToggleButton:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	partyToggleButton:SetScript('OnClick',function(self)
		-- Check if competing addon is loaded
		if IsCompetingAddonLoaded() then
			UIErrorsFrame:AddMessage("Party frames are managed by another addon!", 1.0, 1.0, 0.0, 1.0)
			return
		end
		
		-- Check if in combat
		if InCombatLockdown() then
			-- Reset button state to prevent visual change
			self:SetChecked(not self:GetChecked())
			-- Show combat message
			UIErrorsFrame:AddMessage("Cannot toggle party frames while in combat!", 1.0, 1.0, 0.0, 1.0)
			return
		end
		
		local checked = self:GetChecked();
		if checked then
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			-- Hide all party frames
			for i = 1, 4 do
				local frame = customPartyFrames[i]
				if frame then
					frame:Hide()
				end
			end	
		else
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			-- Show party frames if they have members
			for i = 1, 4 do
				local frame = customPartyFrames[i]
				if frame then
					local unit = "party"..i
					if UnitExists(unit) then
						frame:Show()
					else
						frame:Hide()
					end
				end
			end	
		end
		party_state = checked and 1 or 0
		-- print("party_state saved as:", party_state) -- Debug line
		if _G.DrakeishUI_UpdateRaidFrames then
			_G.DrakeishUI_UpdateRaidFrames()
		end
		UpdatePartyToggleButtonPosition()
	end)
	
	-- Add mouseover effects to match other toggle button
	partyToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	partyToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	-- Use a timer to run after the main event handler
	local initTimer = CreateFrame("Frame")
	initTimer:SetScript("OnUpdate", function(self, delta)
		self.elapsed = (self.elapsed or 0) + delta
		if self.elapsed >= 0.1 then -- Run after main event handler
			self:SetScript("OnUpdate", nil)
			
			-- Check for competing addons first
			if IsCompetingAddonLoaded() then
				-- Hide frames and button if competing addon is loaded
				for i = 1, 4 do
					local frame = customPartyFrames[i]
					if frame then
						frame:Hide()
					end
				end
				partyToggleButton:Hide()
				return
			else
				partyToggleButton:Show()
			end
			
			if not party_state then party_state = 0 end
			if party_state == 1 then
				-- Hide all party frames
				for i = 1, 4 do
					local frame = customPartyFrames[i]
					if frame then
						frame:Hide()
					end
				end	
				normal:set_atlas('bag-arrow-invert-2x')
				pushed:set_atlas('bag-arrow-invert-2x')
				highlight:set_atlas('bag-arrow-invert-2x')
				partyToggleButton:SetChecked(1)
			else
				-- Show party frames if they have members
				for i = 1, 4 do
					local frame = customPartyFrames[i]
					if frame then
						local unit = "party"..i
						if UnitExists(unit) then
							frame:Show()
						else
							frame:Hide()
						end
					end
				end	
				normal:set_atlas('bag-arrow-2x')
				pushed:set_atlas('bag-arrow-2x')
				highlight:set_atlas('bag-arrow-2x')
				partyToggleButton:SetChecked(nil)
			end
		end
	end)
end

-- Combat state visual indicator
local function UpdatePartyToggleCombatState()
    if InCombatLockdown() then
        -- Make button appear disabled during combat
        partyToggleButton:SetAlpha(0.1)
        -- Add red tint to indicate combat lock
        local combatOverlay = partyToggleButton:CreateTexture(nil, "OVERLAY")
        combatOverlay:SetAllPoints()
        combatOverlay:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        combatOverlay:SetVertexColor(1, 0, 0, 0.3) -- Red tint
        combatOverlay:SetDrawLayer("OVERLAY", 1)
        partyToggleButton.combatOverlay = combatOverlay
    else
        -- Restore normal appearance
        partyToggleButton:SetAlpha(0.3)
        if partyToggleButton.combatOverlay then
            partyToggleButton.combatOverlay:Hide()
        end
    end
end

-- Register combat events for visual feedback
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    UpdatePartyToggleCombatState()
end)

-- Slash command for party frame scale
SLASH_PARTYFRAMESCALE1 = "/partyframescale"
SLASH_PARTYFRAMESCALE2 = "/pfscale"
SlashCmdList["PARTYFRAMESCALE"] = function(msg)
    local scale = tonumber(msg)
    if scale and scale > 0 and scale <= 3 then
        SetPartyFrameScale(scale)
    else
        print("Usage: /partyframescale <scale> (0.1 to 3.0)")
        print("Current scale:", partyFrameScale)
    end
end

-- Refresh party status text when Interface > Status Text CVars change
if DrakeishUI_RegisterStatusTextListener then
    DrakeishUI_RegisterStatusTextListener(function()
        for i = 1, 4 do
            local frame = customPartyFrames[i]
            if frame and frame:IsShown() then
                UpdatePartyFrame(frame, "party"..i)
            end
        end
    end)
end

function DrakeishUI_RefreshPartyFrames()
    for i = 1, 4 do
        local frame = customPartyFrames[i]
        if frame then
            UpdatePartyFrame(frame, "party"..i)
        end
    end
end
_G.DrakeishUI_RefreshPartyFrames = DrakeishUI_RefreshPartyFrames

