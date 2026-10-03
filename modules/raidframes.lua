--[[
    DrakeishUI - Simple Compact Raid Frames
    Inspired by CompactRaidFrame layout (not a copy of the addon).
    Shown only when Toggle Raid Frames is ON and the player is in a raid.
    Layout: groups in columns, 4 per row then next 4 below; player first in their group.
    Anchored top-left like party frames; shares the party toggle for show/hide + position.
]]

local UNIT_W = 72
local UNIT_H_FULL = 36
local UNIT_H_THIN = 18

local function RaidFrameStyle()
    -- Prefer the getter. The style is stored on DrakeishUI_SocialDB because a
    -- newly added SavedVariables name is not written until a full client restart.
    if type(_G.DrakeishUI_GetRaidFrameStyle) == "function" then
        return _G.DrakeishUI_GetRaidFrameStyle()
    end
    local style
    if type(DrakeishUI_SocialDB) == "table" then
        style = tonumber(DrakeishUI_SocialDB.raidFrameStyle)
    end
    if style ~= 1 and style ~= 2 then
        style = tonumber(raid_frame_style_state) or 1
    end
    if style ~= 2 then style = 1 end
    return style
end

local function UnitHeight()
    if RaidFrameStyle() == 2 then return UNIT_H_THIN end
    return UNIT_H_FULL
end
local PAD = 2
local GROUP_GAP = 6
local BAND_GAP = 8
local GROUPS_PER_ROW = 4
local HP_BG_ALPHA = 0.55

local MEDIA = "Interface\\AddOns\\DrakeishUI\\assets\\RaidFrame\\"
local TEX_BORDER = MEDIA .. "RaidFrame_Border"
local TEX_BORDER_THIN = "Interface\\AddOns\\DrakeishUI\\assets\\RaidFrame_Border_a"
-- Rounded alpha baked from each border. 3.3.5a cannot apply a live mask, so the
-- bar art itself carries the border silhouette and the square corners stay hidden.
local TEX_MASK = MEDIA .. "RaidFrame_Mask"
local TEX_MASK_BG = MEDIA .. "RaidFrame_MaskBg"
local TEX_MASK_THIN = MEDIA .. "RaidFrame_Mask_a"
local TEX_MASK_BG_THIN = MEDIA .. "RaidFrame_MaskBg_a"

local function BarTextures()
    if RaidFrameStyle() == 2 then
        return TEX_MASK_BG_THIN, TEX_MASK_THIN
    end
    return TEX_MASK_BG, TEX_MASK
end

local raidRoot
local raidUnits = {}
local raidPet
local CLASS_COLORS = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)

local function SafeSetText(fs, text)
    if fs then fs:SetText(text or "") end
end

local function TruncateName(name, maxLen)
    if not name then return "" end
    maxLen = maxLen or 8
    if string.len(name) <= maxLen then return name end
    return string.sub(name, 1, maxLen - 1) .. ".."
end

function DrakeishUI_ShouldShowRaidFrames()
    local enabled = 0
    if _G.DrakeishUI_GetRaidFramesState then
        enabled = _G.DrakeishUI_GetRaidFramesState()
    else
        enabled = (raid_frames_state == 1 or darken_ui_state == 1) and 1 or 0
    end
    -- Same collapse toggle as party frames (party_state == 1 means hidden)
    if (party_state or 0) == 1 then
        return false
    end
    return enabled == 1 and (GetNumRaidMembers() or 0) > 0
end
_G.DrakeishUI_ShouldShowRaidFrames = DrakeishUI_ShouldShowRaidFrames
_G.DrakeishUI_RaidModeActive = function()
    local enabled = 0
    if _G.DrakeishUI_GetRaidFramesState then
        enabled = _G.DrakeishUI_GetRaidFramesState()
    else
        enabled = (raid_frames_state == 1 or darken_ui_state == 1) and 1 or 0
    end
    return enabled == 1 and (GetNumRaidMembers() or 0) > 0
end

-- Raid-style rectangular pet: pet orb off, "Toggle Pet Frame" off (pet visible), raid frames on.
function DrakeishUI_ShouldShowRaidStylePet()
    if not DrakeishUI_ShouldShowRaidFrames() then
        return false
    end
    if (_G.hide_pet_frame_state or 0) == 1 then
        return false
    end
    local petOrbEnabled = _G.D32CharacterData and _G.D32CharacterData.petOrb and _G.D32CharacterData.petOrb.enabled
    if petOrbEnabled then
        return false
    end
    return UnitExists("pet")
end
_G.DrakeishUI_ShouldShowRaidStylePet = DrakeishUI_ShouldShowRaidStylePet

local function GetClassColor(unit)
    -- Pet uses DragonflightUI green health (same as player/non-classcolored bars).
    if unit == "pet" then
        return 0, 1, 0
    end
    local _, class = UnitClass(unit)
    if class and CLASS_COLORS and CLASS_COLORS[class] then
        local c = CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 0.5, 0.5, 0.5
end

local function ShowRaidUnitMenu(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then
        return
    end

    local unit = frame.unit
    local name = UnitName(unit)

    HideDropDownMenu(1)

    -- Pet: keep Blizzard pet actions dropdown (already works)
    if unit == "pet" then
        if PetFrameDropDown then
            ToggleDropDownMenu(1, nil, PetFrameDropDown, "cursor", 0, 0)
        end
        return
    end

    -- Raid/party members: same style of menu as custom party frames.
    -- Avoid UnitPopup_ShowMenu("RAID_PLAYER") — this client’s UnitPopupMenus
    -- entry can be nil and errors in UnitPopup_HideButtons.
    local dropdown = _G.DrakeishUI_RaidUnitDropDown
    if not dropdown then
        dropdown = CreateFrame("Frame", "DrakeishUI_RaidUnitDropDown", UIParent, "UIDropDownMenuTemplate")
        _G.DrakeishUI_RaidUnitDropDown = dropdown
    end

    dropdown.unit = unit
    dropdown.name = name
    dropdown.displayMode = "MENU"
    dropdown.initialize = function(self, level)
        level = level or 1
        local u = self.unit
        local n = self.name
        if not u or not UnitExists(u) then
            return
        end

        local info = UIDropDownMenu_CreateInfo()
        info.text = n or ""
        info.isTitle = 1
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "Target"
        info.notCheckable = 1
        info.func = function() TargetUnit(u) end
        UIDropDownMenu_AddButton(info, level)

        if n and not UnitIsUnit(u, "player") then
            info = UIDropDownMenu_CreateInfo()
            info.text = "Set Focus"
            info.notCheckable = 1
            info.func = function() FocusUnit(u) end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "Whisper"
            info.notCheckable = 1
            info.func = function() ChatFrame_SendTell(n) end
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "Inspect"
            info.notCheckable = 1
            info.func = function()
                if InspectUnit then
                    InspectUnit(u)
                end
            end
            UIDropDownMenu_AddButton(info, level)

            if UnitIsFriend and UnitIsFriend("player", u) and CheckInteractDistance and CheckInteractDistance(u, 2) then
                info = UIDropDownMenu_CreateInfo()
                info.text = "Trade"
                info.notCheckable = 1
                info.func = function()
                    if InitiateTrade then
                        InitiateTrade(u)
                    end
                end
                UIDropDownMenu_AddButton(info, level)

                info = UIDropDownMenu_CreateInfo()
                info.text = "Follow"
                info.notCheckable = 1
                info.func = function() FollowUnit(u) end
                UIDropDownMenu_AddButton(info, level)
            end
        end

        local canLead = (IsRaidLeader and IsRaidLeader())
            or (IsRaidOfficer and IsRaidOfficer())
            or (IsPartyLeader and IsPartyLeader())

        if canLead and not UnitIsUnit(u, "player") then
            if PromoteToLeader then
                info = UIDropDownMenu_CreateInfo()
                info.text = "Promote to Leader"
                info.notCheckable = 1
                info.func = function() PromoteToLeader(u) end
                UIDropDownMenu_AddButton(info, level)
            end

            if IsRaidLeader and IsRaidLeader() and PromoteToAssistant and DemoteAssistant then
                info = UIDropDownMenu_CreateInfo()
                info.text = "Promote to Assistant"
                info.notCheckable = 1
                info.func = function() PromoteToAssistant(u) end
                UIDropDownMenu_AddButton(info, level)

                info = UIDropDownMenu_CreateInfo()
                info.text = "Demote Assistant"
                info.notCheckable = 1
                info.func = function() DemoteAssistant(u) end
                UIDropDownMenu_AddButton(info, level)
            end

            info = UIDropDownMenu_CreateInfo()
            info.text = "Remove from Group"
            info.notCheckable = 1
            info.func = function() UninviteUnit(n) end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, dropdown.initialize, "MENU")
    ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

local function CreateRaidUnit(parent, index)
    local f = CreateFrame("Button", "DrakeishUI_RaidUnit" .. index, parent, "SecureUnitButtonTemplate")
    f:SetWidth(UNIT_W)
    f:SetHeight(UnitHeight())
    f:RegisterForClicks("AnyUp")
    -- menu shown via OnMouseUp (party-frame style); not SecureUnitButton type2

    local bgTex, hpTex = BarTextures()
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetTexture(bgTex)
    bg:SetVertexColor(0.15, 0.15, 0.15, 1)
    bg:SetAlpha(HP_BG_ALPHA)
    f.bg = bg

    local hp = CreateFrame("StatusBar", nil, f)
    hp:SetAllPoints(f)
    hp:SetStatusBarTexture(hpTex)
    f._barTex = hpTex
    hp:SetMinMaxValues(0, 1)
    hp:SetValue(1)
    hp:EnableMouse(false)
    f.health = hp

    local borderFrame = CreateFrame("Frame", nil, f)
    borderFrame:SetAllPoints()
    borderFrame:SetFrameLevel(hp:GetFrameLevel() + 2)
    borderFrame:EnableMouse(false)
    local border = borderFrame:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture(TEX_BORDER)
    f.border = border

    local nameFS = borderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFS:SetPoint("TOPLEFT", hp, "TOPLEFT", 3, -2)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetTextColor(1, 1, 1)
    f.nameText = nameFS

    local healthFS = borderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    healthFS:SetPoint("TOPRIGHT", hp, "TOPRIGHT", -3, -2)
    healthFS:SetJustifyH("RIGHT")
    healthFS:SetTextColor(1, 1, 1)
    f.healthText = healthFS
    nameFS:SetPoint("RIGHT", healthFS, "LEFT", -2, 0)

    local powerFS = borderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    powerFS:SetPoint("BOTTOMLEFT", hp, "BOTTOMLEFT", 3, 2)
    powerFS:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", -3, 2)
    powerFS:SetJustifyH("RIGHT")
    powerFS:SetTextColor(1, 1, 1)
    f.powerText = powerFS

    f:SetScript("OnEnter", function(self)
        if self.unit and UnitExists(self.unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Party frames use OnMouseUp for the menu; same here (avoid also setting
    -- SecureUnitButton type2=menu or the dropdown toggles open then closed).
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            ShowRaidUnitMenu(self)
        end
    end)

    return f
end

local function EnsureRaidRoot()
    if raidRoot then return raidRoot end

    raidRoot = CreateFrame("Frame", "DrakeishUI_RaidFrames", UIParent)
    raidRoot:SetWidth((UNIT_W + GROUP_GAP) * GROUPS_PER_ROW)
    raidRoot:SetHeight((UnitHeight() + PAD) * 5 * 2 + BAND_GAP)
    raidRoot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -200)
    raidRoot:SetMovable(true)
    raidRoot:EnableMouse(false)
    raidRoot:Hide()

    for i = 1, 40 do
        local u = CreateRaidUnit(raidRoot, i)
        u:Hide()
        raidUnits[i] = u
    end

    raidPet = CreateRaidUnit(raidRoot, "Pet")
    raidPet:Hide()

    return raidRoot
end

local function UpdateRaidUnit(frame, unit)
    if not frame then return end

    if not unit or not UnitExists(unit) then
        frame:Hide()
        frame.unit = nil
        return
    end

    frame.unit = unit

    if not InCombatLockdown or not InCombatLockdown() then
        frame:SetAttribute("unit", unit)
        frame:SetAttribute("*type1", "target")
        -- Right-click menu is handled in OnMouseUp (same as party frames)
        frame:SetAttribute("*type2", nil)
        frame:SetAttribute("type2", nil)
    end

    local thin = (RaidFrameStyle() == 2)
    if frame.border then
        frame.border:SetTexture(thin and TEX_BORDER_THIN or TEX_BORDER)
    end
    local bgTex, hpTex = thin and TEX_MASK_BG_THIN or TEX_MASK_BG, thin and TEX_MASK_THIN or TEX_MASK
    if frame._barTex ~= hpTex then
        frame._barTex = hpTex
        frame.bg:SetTexture(bgTex)
        frame.bg:SetTexCoord(0, 1, 0, 1)
        frame.health:SetStatusBarTexture(hpTex)
    end
    SafeSetText(frame.nameText, TruncateName(UnitName(unit), thin and 11 or 7))
    if thin then
        frame.healthText:Hide()
        frame.powerText:Hide()
        frame.nameText:ClearAllPoints()
        frame.nameText:SetPoint("LEFT", frame.health, "LEFT", 3, 0)
        frame.nameText:SetPoint("RIGHT", frame.health, "RIGHT", -3, 0)
        frame.nameText:SetJustifyH("LEFT")
        frame.nameText:SetJustifyV("MIDDLE")
    else
        frame.healthText:Show()
        frame.powerText:Show()
        frame.nameText:ClearAllPoints()
        frame.nameText:SetPoint("TOPLEFT", frame.health, "TOPLEFT", 3, -2)
        frame.nameText:SetPoint("RIGHT", frame.healthText, "LEFT", -2, 0)
        frame.nameText:SetJustifyH("LEFT")
    end

    local r, g, b = GetClassColor(unit)
    frame.health:SetStatusBarColor(r, g, b, 1)

    local maxHP = UnitHealthMax(unit) or 1
    if maxHP < 1 then maxHP = 1 end
    local curHP = UnitHealth(unit) or 0
    frame.health:SetMinMaxValues(0, maxHP)
    frame.health:SetValue(curHP)

    local maxPP = UnitPowerMax(unit) or 0
    local curPP = UnitPower(unit) or 0
    local powerPct = (maxPP > 0) and math.floor((curPP / maxPP) * 100 + 0.5) or 0

    if UnitIsDeadOrGhost(unit) then
        if not thin then
            SafeSetText(frame.healthText, "")
            SafeSetText(frame.powerText, "Dead")
        end
        frame.health:SetStatusBarColor(0.35, 0.35, 0.35, 1)
    elseif UnitIsConnected and not UnitIsConnected(unit) then
        if not thin then
            SafeSetText(frame.healthText, "")
            SafeSetText(frame.powerText, "Offline")
        end
        frame.health:SetStatusBarColor(0.3, 0.3, 0.3, 1)
    elseif not thin then
        SafeSetText(frame.healthText, math.floor((curHP / maxHP) * 100 + 0.5) .. "%")
        SafeSetText(frame.powerText, powerPct .. "%")
    end

    frame:Show()
end

local function HideAllRaidUnits()
    for i = 1, 40 do
        local f = raidUnits[i]
        if f then
            f:Hide()
            f.unit = nil
        end
    end
    if raidPet then
        raidPet:Hide()
        raidPet.unit = nil
    end
end

local function FindFrameByUnit(unit)
    if not unit then return nil end
    if raidPet and raidPet.unit and (raidPet.unit == unit or UnitIsUnit(raidPet.unit, unit)) then
        return raidPet
    end
    for i = 1, 40 do
        local f = raidUnits[i]
        if f and f.unit and (f.unit == unit or UnitIsUnit(f.unit, unit)) then
            return f
        end
    end
end

-- Same top-left anchor rules as party frames.
-- Raid-style pet lives inside raidRoot, so no Blizzard PetFrame gap is reserved while raid frames show.
local function GetRaidAnchorOffset()
    local orbsActive = (_G.diablo_orbs_state == 1)
    local useTopPosition = (_G.unitframes_state == 1) or orbsActive
    local x, y = 16, -200
    if useTopPosition then
        y = -14
    end
    return x, y
end

function DrakeishUI_UpdateRaidFramePositions()
    if not raidRoot then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local x, y = GetRaidAnchorOffset()
    raidRoot:ClearAllPoints()
    raidRoot:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    if _G.UpdatePartyToggleButtonPosition then
        _G.UpdatePartyToggleButtonPosition()
    end
end
_G.DrakeishUI_UpdateRaidFramePositions = DrakeishUI_UpdateRaidFramePositions

-- Build occupied group lists; player always first within their group
local function BuildOccupiedGroups()
    local groups = {}
    for g = 1, 8 do
        groups[g] = {}
    end

    local count = GetNumRaidMembers() or 0
    for i = 1, count do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local subgroup = select(3, GetRaidRosterInfo(i)) or 1
            if subgroup < 1 then subgroup = 1 end
            if subgroup > 8 then subgroup = 8 end
            groups[subgroup][#groups[subgroup] + 1] = unit
        end
    end

    for g = 1, 8 do
        local list = groups[g]
        for i = 1, #list do
            if UnitIsUnit(list[i], "player") then
                if i > 1 then
                    local me = table.remove(list, i)
                    table.insert(list, 1, me)
                end
                break
            end
        end
    end

    local occupied = {}
    for g = 1, 8 do
        if #groups[g] > 0 then
            occupied[#occupied + 1] = groups[g]
        end
    end
    return occupied
end

local function BandHeight(occupied, band)
    local startIdx = band * GROUPS_PER_ROW + 1
    local endIdx = math.min(startIdx + GROUPS_PER_ROW - 1, #occupied)
    local maxN = 1
    for i = startIdx, endIdx do
        local n = #occupied[i]
        if n > maxN then maxN = n end
    end
    return maxN * (UnitHeight() + PAD)
end

function DrakeishUI_UpdateRaidFrames()
    EnsureRaidRoot()

    if not DrakeishUI_ShouldShowRaidFrames() then
        HideAllRaidUnits()
        raidRoot:Hide()
        if _G.RefreshBlizzardPetFrame then
            _G.RefreshBlizzardPetFrame()
        end
        if _G.UpdatePartyToggleButtonPosition then
            _G.UpdatePartyToggleButtonPosition()
        end
        if _G.DrakeishUI_RefreshPartyFrames then
            _G.DrakeishUI_RefreshPartyFrames()
        end
        return
    end

    raidRoot:Show()
    DrakeishUI_UpdateRaidFramePositions()

    if not (InCombatLockdown and InCombatLockdown()) then
        local h = UnitHeight()
        for i = 1, 40 do
            if raidUnits[i] then raidUnits[i]:SetHeight(h) end
        end
        if raidPet then raidPet:SetHeight(h) end
    end

    local showPet = DrakeishUI_ShouldShowRaidStylePet()
    local petOffset = 0
    local inCombat = InCombatLockdown and InCombatLockdown()

    if showPet and raidPet then
        if not inCombat then
            raidPet:ClearAllPoints()
            raidPet:SetPoint("TOPLEFT", raidRoot, "TOPLEFT", 0, 0)
        end
        UpdateRaidUnit(raidPet, "pet")
        petOffset = UnitHeight() + PAD
    elseif raidPet then
        raidPet:Hide()
        raidPet.unit = nil
    end

    local occupied = BuildOccupiedGroups()
    local frameIndex = 1

    for idx = 1, #occupied do
        local list = occupied[idx]
        local slot = idx - 1
        local col = slot % GROUPS_PER_ROW
        local band = math.floor(slot / GROUPS_PER_ROW)
        local bandY = petOffset
        for b = 0, band - 1 do
            bandY = bandY + BandHeight(occupied, b) + BAND_GAP
        end

        for row = 1, #list do
            local frame = raidUnits[frameIndex]
            if frame then
                if not inCombat then
                    frame:ClearAllPoints()
                    frame:SetPoint(
                        "TOPLEFT", raidRoot, "TOPLEFT",
                        col * (UNIT_W + GROUP_GAP),
                        -(bandY + (row - 1) * (UnitHeight() + PAD))
                    )
                end
                UpdateRaidUnit(frame, list[row])
                frameIndex = frameIndex + 1
            end
        end
    end

    for i = frameIndex, 40 do
        local f = raidUnits[i]
        if f then
            f:Hide()
            f.unit = nil
        end
    end

    if not inCombat then
        local cols = math.min(GROUPS_PER_ROW, math.max(1, #occupied))
        local bands = math.max(1, math.ceil(#occupied / GROUPS_PER_ROW))
        local totalH = petOffset
        for b = 0, bands - 1 do
            totalH = totalH + BandHeight(occupied, b)
            if b < bands - 1 then
                totalH = totalH + BAND_GAP
            end
        end
        raidRoot:SetWidth(cols * (UNIT_W + GROUP_GAP) - GROUP_GAP + PAD)
        raidRoot:SetHeight(math.max(UnitHeight(), totalH))
    end

    if _G.RefreshBlizzardPetFrame then
        _G.RefreshBlizzardPetFrame()
    end
    if _G.UpdatePartyToggleButtonPosition then
        _G.UpdatePartyToggleButtonPosition()
    end
    if _G.DrakeishUI_RefreshPartyFrames then
        _G.DrakeishUI_RefreshPartyFrames()
    end
end
_G.DrakeishUI_UpdateRaidFrames = DrakeishUI_UpdateRaidFrames

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_MANA")
eventFrame:RegisterEvent("UNIT_MAXMANA")
eventFrame:RegisterEvent("UNIT_RAGE")
eventFrame:RegisterEvent("UNIT_MAXRAGE")
eventFrame:RegisterEvent("UNIT_ENERGY")
eventFrame:RegisterEvent("UNIT_MAXENERGY")
eventFrame:RegisterEvent("UNIT_FOCUS")
eventFrame:RegisterEvent("UNIT_MAXFOCUS")
eventFrame:RegisterEvent("UNIT_RUNIC_POWER")
eventFrame:RegisterEvent("UNIT_MAXRUNIC_POWER")
eventFrame:RegisterEvent("UNIT_DISPLAYPOWER")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "UNIT_PET" then
        if arg1 == "player" then
            DrakeishUI_UpdateRaidFrames()
        end
        return
    end

    if string.find(event, "^UNIT_") then
        if not DrakeishUI_ShouldShowRaidFrames() then return end
        if arg1 == "pet" then
            if raidPet and DrakeishUI_ShouldShowRaidStylePet() then
                UpdateRaidUnit(raidPet, "pet")
            elseif DrakeishUI_ShouldShowRaidStylePet() or (raidPet and raidPet:IsShown()) then
                -- Pet dismissed / conditions changed → full refresh
                DrakeishUI_UpdateRaidFrames()
            end
            return
        end
        if not arg1 or not string.find(arg1, "^raid%d") then return end
        local frame = FindFrameByUnit(arg1)
        if frame then
            UpdateRaidUnit(frame, frame.unit or arg1)
        end
        return
    end

    DrakeishUI_UpdateRaidFrames()
    if _G.UpdateRaidFramesToggleAvailability then
        _G.UpdateRaidFramesToggleAvailability()
    end
end)

-- ---------------------------------------------------------------------------
-- Blizzard RaidUI guard for custom classes (DEMONHUNTER, GUARDIAN, etc.)
-- Stock RaidGroupFrame_Update does tinsert(RAID_SUBGROUP_LISTS[fileName], i)
-- only for classes in RAID_CLASS_BUTTONS. Unknown tokens → nil tinsert error.
-- Do NOT inject fake RAID_CLASS_BUTTONS entries (button=0 crashes RaidClassButton_Update).
-- Instead, while the update runs, ensure RAID_SUBGROUP_LISTS[fileName] exists.
-- ---------------------------------------------------------------------------
local EXTRA_RAID_CLASSES = {
    DEMONHUNTER = true,
    GUARDIAN = true,
    MONK = true,
    EVOKER = true,
    ENGINEER = true,
}

local function CleanupBadRaidClassButtons()
    if type(RAID_CLASS_BUTTONS) ~= "table" then
        return
    end
    for className, value in pairs(RAID_CLASS_BUTTONS) do
        if EXTRA_RAID_CLASSES[className] and type(value) == "table" then
            local b = value.button
            if not b or b < 1 or not _G["RaidClassButton" .. b] then
                RAID_CLASS_BUTTONS[className] = nil
            end
        end
    end
end

local function EnsureClassIconCoords()
    if type(CLASS_ICON_TCOORDS) ~= "table" then
        return
    end
    if not CLASS_ICON_TCOORDS["DEMONHUNTER"] then
        CLASS_ICON_TCOORDS["DEMONHUNTER"] = { 0.7421875, 0.98828125, 0.5, 0.75 }
    end
    if not CLASS_ICON_TCOORDS["GUARDIAN"] then
        CLASS_ICON_TCOORDS["GUARDIAN"] = { 0.49609375, 0.7421875, 0.5, 0.75 }
    end
end

local raidGroupFrameUpdatePatched = false

local function PatchBlizzardRaidGroupFrameUpdate()
    local orig = _G.RaidGroupFrame_Update
    if type(orig) ~= "function" or raidGroupFrameUpdatePatched then
        return
    end
    raidGroupFrameUpdatePatched = true

    _G.RaidGroupFrame_Update = function(...)
        CleanupBadRaidClassButtons()
        EnsureClassIconCoords()

        -- When GetRaidRosterInfo returns a custom class, seed its subgroup list
        -- before Blizzard's tinsert (RAID_SUBGROUP_LISTS was only filled for stock classes).
        local _GetRaidRosterInfo = _G.GetRaidRosterInfo
        _G.GetRaidRosterInfo = function(index)
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML =
                _GetRaidRosterInfo(index)
            if fileName and type(_G.RAID_SUBGROUP_LISTS) == "table" and _G.RAID_SUBGROUP_LISTS[fileName] == nil then
                _G.RAID_SUBGROUP_LISTS[fileName] = {}
            end
            return name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML
        end

        local ok, err = pcall(orig, ...)
        _G.GetRaidRosterInfo = _GetRaidRosterInfo
        if not ok then
            error(err)
        end
    end
end

PatchBlizzardRaidGroupFrameUpdate()

local raidUiPatchFrame = CreateFrame("Frame")
raidUiPatchFrame:RegisterEvent("ADDON_LOADED")
raidUiPatchFrame:SetScript("OnEvent", function(self, event, name)
    if name == "Blizzard_RaidUI" then
        CleanupBadRaidClassButtons()
        EnsureClassIconCoords()
        PatchBlizzardRaidGroupFrameUpdate()
    end
end)
