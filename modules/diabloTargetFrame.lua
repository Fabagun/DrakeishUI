-- Diablo Target Frame Module
-- Custom target frame that replaces the default TargetFrame when Diablo Orbs are active

local addon = select(2,...);
local _G = _G;

-- Saved variable for health bar color (true = class color, false = red/green)
if not _G.diablo_target_health_classcolor then
    _G.diablo_target_health_classcolor = true -- Default to class color
end

-- Saved variable for non-player health bar color (true = green, false = red)
if not _G.diablo_target_health_green then
    _G.diablo_target_health_green = true -- Default to green (standard WoW green)
end

-- Saved variable for boss/worldboss health bar color (true = red, false = use normal logic)
if not _G.diablo_target_health_boss_red then
    _G.diablo_target_health_boss_red = true -- Default to red for bosses
end

-- Create placeholder functions immediately so they're available when ToggleDiabloOrbs is called
local diabloTargetFrame = nil
local customFrameActive = false

-- Placeholder functions (will be replaced with real ones after frame is created)
local function ShowDiabloTargetFrame_Placeholder()
end

local function HideDiabloTargetFrame_Placeholder()
end

-- Make placeholder functions global immediately
_G.ShowDiabloTargetFrame = ShowDiabloTargetFrame_Placeholder
_G.HideDiabloTargetFrame = HideDiabloTargetFrame_Placeholder

-- Create custom target frame
diabloTargetFrame = CreateFrame("Frame", "DrakeishUI_DiabloTargetFrame", UIParent)
diabloTargetFrame:SetSize(300, 80) -- Adjust size as needed
diabloTargetFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 918) -- Centered horizontally, 900px from bottom
diabloTargetFrame:Hide()

-- Background texture (in BACKGROUND layer, lowest)
local bgBackgroundTexture = diabloTargetFrame:CreateTexture(nil, "BACKGROUND")
bgBackgroundTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\d3_targetframe_background.tga")
bgBackgroundTexture:SetAllPoints(diabloTargetFrame)
bgBackgroundTexture:SetDrawLayer("BACKGROUND", 0)
diabloTargetFrame.bgBackgroundTexture = bgBackgroundTexture

-- Main texture (in OVERLAY layer so it appears above the bars)
local bgTexture = diabloTargetFrame:CreateTexture(nil, "OVERLAY")
bgTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\d3_targetframe.tga")
bgTexture:SetAllPoints(diabloTargetFrame)
bgTexture:SetDrawLayer("OVERLAY", 0) -- Lower draw layer so classification can be above
diabloTargetFrame.bgTexture = bgTexture

-- Classification indicator frame (boss/rare/elite) - placed above the frame
-- Use a child frame with higher frame level to ensure it's above everything
local classificationFrame = CreateFrame("Frame", nil, diabloTargetFrame)
classificationFrame:SetFrameLevel(diabloTargetFrame:GetFrameLevel() + 10) -- Much higher frame level
classificationFrame:SetSize(100, 50) -- Adjust size as needed
classificationFrame:SetPoint("BOTTOM", diabloTargetFrame, "TOP", 0, -80) -- Positioned above the frame
classificationFrame:Hide() -- Hidden by default

local classificationTexture = classificationFrame:CreateTexture(nil, "OVERLAY")
classificationTexture:SetAllPoints(classificationFrame)
classificationTexture:SetDrawLayer("OVERLAY", 0)
diabloTargetFrame.classificationFrame = classificationFrame
diabloTargetFrame.classificationTexture = classificationTexture

-- Name text (positioned like party frames: to the right of where a portrait would be)
local nameText = diabloTargetFrame:CreateFontString(nil, "OVERLAY")
nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "") -- Match party frame font size
nameText:SetPoint("TOPLEFT", diabloTargetFrame, "TOPLEFT", 54, -20) -- Match party frame positioning (portrait width 40 + offset 10 + left margin 4 = 54)
nameText:SetTextColor(1, 1, 1, 1)
nameText:SetShadowColor(0, 0, 0, 0.7) -- Match party frame shadow
nameText:SetShadowOffset(1, -1)
nameText:SetJustifyH("LEFT") -- Match party frame
diabloTargetFrame.nameText = nameText

-- Level text (positioned like party frames: at the right edge)
local levelText = diabloTargetFrame:CreateFontString(nil, "OVERLAY")
levelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "") -- Match party frame font size
levelText:SetPoint("RIGHT", diabloTargetFrame, "RIGHT", -52, 15) -- Match party frame positioning exactly
levelText:SetJustifyH("RIGHT") -- Match party frame
levelText:SetTextColor(1, 1, 1, 1)
levelText:SetShadowColor(0, 0, 0, 0.7) -- Match party frame shadow
levelText:SetShadowOffset(1, -1)
diabloTargetFrame.levelText = levelText

-- Health bar
local healthBar = CreateFrame("StatusBar", nil, diabloTargetFrame)
healthBar:SetStatusBarTexture("Interface\\AddOns\\DrakeishUI\\assets\\DF-StatusBar")
healthBar:SetPoint("TOPLEFT", diabloTargetFrame, "TOPLEFT", 45, -32)
healthBar:SetPoint("TOPRIGHT", diabloTargetFrame, "TOPRIGHT", -45, -32)
healthBar:SetHeight(20)
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)
healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red for health
healthBar:SetFrameLevel(diabloTargetFrame:GetFrameLevel()) -- Same frame level as parent, texture is in ARTWORK layer above
diabloTargetFrame.healthBar = healthBar

-- Health bar text
local healthText = healthBar:CreateFontString(nil, "OVERLAY")
healthText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0.5)
healthText:SetTextColor(1, 1, 1, 1)
healthText:SetShadowColor(0, 0, 0, 0.8)
healthText:SetShadowOffset(1, -1)
diabloTargetFrame.healthText = healthText

-- Mana/Power bar
local powerBar = CreateFrame("StatusBar", nil, diabloTargetFrame)
powerBar:SetStatusBarTexture("Interface\\AddOns\\DrakeishUI\\assets\\DF-StatusBar")
powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, 0)
powerBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
powerBar:SetHeight(4)
powerBar:SetMinMaxValues(0, 100)
powerBar:SetValue(100)
powerBar:SetStatusBarColor(0, 0, 1, 1) -- Blue for mana (will be updated based on power type)
powerBar:SetFrameLevel(diabloTargetFrame:GetFrameLevel()) -- Same frame level as parent, texture is in ARTWORK layer above
diabloTargetFrame.powerBar = powerBar

-- Power bar text
local powerText = powerBar:CreateFontString(nil, "OVERLAY")
powerText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
powerText:SetTextColor(1, 1, 1, 1)
powerText:SetShadowColor(0, 0, 0, 0.8)
powerText:SetShadowOffset(1, -1)
powerText:Hide()
diabloTargetFrame.powerText = powerText

-- Target castbar: under Diablo health bar while orbs are active.
-- Parent to UIParent (TargetFrame is hidden) so the bar stays visible.
-- Never let Blizzard Target_Spellbar_AdjustPosition run against this parent
-- (it reads auraRows and crashes).
local TARGET_CASTBAR_Y_OFFSET = -15
local originalTargetSpellbarAdjust = Target_Spellbar_AdjustPosition

local function AttachTargetCastbarToDiablo()
    if not TargetFrameSpellBar or not diabloTargetFrame or not diabloTargetFrame.healthBar then return end
    TargetFrameSpellBar:SetParent(UIParent)
    TargetFrameSpellBar:ClearAllPoints()
    TargetFrameSpellBar:SetPoint('TOP', diabloTargetFrame.healthBar, 'BOTTOM', 0, TARGET_CASTBAR_Y_OFFSET)
    TargetFrameSpellBar:SetFrameStrata('HIGH')
    TargetFrameSpellBar:SetFrameLevel(diabloTargetFrame:GetFrameLevel() + 10)
    local hbWidth = diabloTargetFrame.healthBar:GetWidth()
    if hbWidth and hbWidth > 0 then
        TargetFrameSpellBar:SetWidth(hbWidth)
        TargetFrameSpellBar:SetHeight(8)
    end
    -- Border follows bar via edge anchors (set up in Castbar.lua)
    if TargetFrameSpellBar.drakeishBorder then
        TargetFrameSpellBar.drakeishBorder:ClearAllPoints()
        TargetFrameSpellBar.drakeishBorder:SetPoint('TOPLEFT', TargetFrameSpellBar, 'TOPLEFT', -2, 2)
        TargetFrameSpellBar.drakeishBorder:SetPoint('BOTTOMRIGHT', TargetFrameSpellBar, 'BOTTOMRIGHT', 2, -2)
        TargetFrameSpellBar.drakeishBorder:Show()
    end
    if TargetFrameSpellBar.casting or TargetFrameSpellBar.channeling then
        TargetFrameSpellBar:Show()
    end
end

local function RestoreTargetCastbar()
    if not TargetFrameSpellBar or not TargetFrame then return end
    TargetFrameSpellBar:SetParent(TargetFrame)
    TargetFrameSpellBar:ClearAllPoints()
    TargetFrameSpellBar:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 5, 22)
    TargetFrameSpellBar:SetSize(175, 8)
    TargetFrameSpellBar:SetFrameStrata(TargetFrame:GetFrameStrata())
    if TargetFrameSpellBar.drakeishBorder then
        TargetFrameSpellBar.drakeishBorder:ClearAllPoints()
        TargetFrameSpellBar.drakeishBorder:SetPoint('TOPLEFT', TargetFrameSpellBar, 'TOPLEFT', -2, 2)
        TargetFrameSpellBar.drakeishBorder:SetPoint('BOTTOMRIGHT', TargetFrameSpellBar, 'BOTTOMRIGHT', 2, -2)
    end
end

local spellbarAdjustOverridden = false

local function InstallSpellbarAdjustOverride()
    if type(Target_Spellbar_AdjustPosition) ~= 'function' then return end
    if spellbarAdjustOverridden then return end
    originalTargetSpellbarAdjust = Target_Spellbar_AdjustPosition
    Target_Spellbar_AdjustPosition = function(self)
        if customFrameActive and diabloTargetFrame and diabloTargetFrame.healthBar then
            AttachTargetCastbarToDiablo()
            return
        end
        local parent = self and self:GetParent()
        if not parent or parent.auraRows == nil then
            if TargetFrame then
                self:SetParent(TargetFrame)
                self:ClearAllPoints()
                self:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 5, 22)
            end
            return
        end
        if type(originalTargetSpellbarAdjust) == 'function' then
            return originalTargetSpellbarAdjust(self)
        end
    end
    spellbarAdjustOverridden = true
end

InstallSpellbarAdjustOverride()

-- Castbar.lua SetScript(OnShow) stores a direct Blizzard AdjustPosition ref;
-- wrap after login so that path never runs while Diablo owns the bar.
local castbarFixFrame = CreateFrame('Frame')
castbarFixFrame:RegisterEvent('PLAYER_LOGIN')
castbarFixFrame:SetScript('OnEvent', function(self)
    self:UnregisterEvent('PLAYER_LOGIN')
    InstallSpellbarAdjustOverride()
    if not TargetFrameSpellBar then return end
    local prevOnShow = TargetFrameSpellBar:GetScript('OnShow')
    TargetFrameSpellBar:SetScript('OnShow', function(bar)
        if customFrameActive and diabloTargetFrame and diabloTargetFrame.healthBar then
            AttachTargetCastbarToDiablo()
            return
        end
        if prevOnShow then
            if bar:GetParent() ~= TargetFrame and TargetFrame then
                bar:SetParent(TargetFrame)
            end
            -- Only call Blizzard adjust when parent has auraRows
            local parent = bar:GetParent()
            if parent and parent.auraRows ~= nil then
                prevOnShow(bar)
            end
        end
    end)
end)

-- Enable mouse interaction for tooltip + status-text hover
diabloTargetFrame:EnableMouse(true)
diabloTargetFrame.statusTextHover = false

local function ApplyDiabloTargetStatusTextVisibility()
    if not diabloTargetFrame.healthText or not diabloTargetFrame.powerText then return end
    local show = true
    if DrakeishUI_StatusTextVisible then
        show = DrakeishUI_StatusTextVisible("target", diabloTargetFrame.statusTextHover)
    elseif DrakeishUI_StatusTextIsShown then
        show = DrakeishUI_StatusTextIsShown("target") or diabloTargetFrame.statusTextHover
    else
        show = diabloTargetFrame.statusTextHover
    end
    if show then
        diabloTargetFrame.healthText:Show()
        diabloTargetFrame.powerText:Show()
    else
        diabloTargetFrame.healthText:Hide()
        diabloTargetFrame.powerText:Hide()
    end
end

local function SetDiabloTargetStatusTextHover(hovering)
    diabloTargetFrame.statusTextHover = hovering and true or false
    ApplyDiabloTargetStatusTextVisibility()
end

-- Tooltip + status text on mouseover (like Blizzard bars / Diablo orbs)
diabloTargetFrame:SetScript("OnEnter", function(self)
    SetDiabloTargetStatusTextHover(true)
    if UnitExists("target") then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetUnit("target")
        local nameLine = _G["GameTooltipTextLeft1"]
        if nameLine then
            local r, g, b = UnitSelectionColor("target")
            nameLine:SetTextColor(r, g, b, 1)
        end
        GameTooltip:Show()
    end
end)

diabloTargetFrame:SetScript("OnLeave", function(self)
    SetDiabloTargetStatusTextHover(false)
    GameTooltip:Hide()
end)

-- Bars may receive mouse; mirror hover so text still appears
if healthBar then
    healthBar:EnableMouse(true)
    healthBar:HookScript("OnEnter", function() SetDiabloTargetStatusTextHover(true) end)
    healthBar:HookScript("OnLeave", function() SetDiabloTargetStatusTextHover(false) end)
end
if powerBar then
    powerBar:EnableMouse(true)
    powerBar:HookScript("OnEnter", function() SetDiabloTargetStatusTextHover(true) end)
    powerBar:HookScript("OnLeave", function() SetDiabloTargetStatusTextHover(false) end)
end

-- Function to update target frame
local function UpdateDiabloTargetFrame()
    if not diabloTargetFrame:IsShown() then
        return
    end
    
    if not UnitExists("target") then
        diabloTargetFrame:Hide()
        return
    end
    
    -- Update name
    local name = UnitName("target") or "Unknown"
    diabloTargetFrame.nameText:SetText(name)
    
    -- Update name color based on reaction
    local r, g, b = UnitSelectionColor("target")
    diabloTargetFrame.nameText:SetTextColor(r, g, b, 1)
    
    -- Update level
    local level = UnitLevel("target")
    if level and level > 0 then
        diabloTargetFrame.levelText:SetText(level)
        
        -- Update level color based on difficulty
        local playerLevel = UnitLevel("player")
        if playerLevel then
            local difficultyColor = GetQuestDifficultyColor(level, playerLevel)
            diabloTargetFrame.levelText:SetTextColor(difficultyColor.r, difficultyColor.g, difficultyColor.b, 1)
        else
            diabloTargetFrame.levelText:SetTextColor(r, g, b, 1)
        end
    else
        diabloTargetFrame.levelText:SetText("??")
        diabloTargetFrame.levelText:SetTextColor(r, g, b, 1)
    end
    
    -- Update classification indicator (boss/rare/elite)
    local classification = UnitClassification("target")
    if classification == "worldboss" or classification == "boss" then
        diabloTargetFrame.classificationTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\d3_boss.tga")
        diabloTargetFrame.classificationFrame:Show()
    elseif classification == "rareelite" or classification == "rare" then
        diabloTargetFrame.classificationTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\d3_rareelite.tga")
        diabloTargetFrame.classificationFrame:Show()
    elseif classification == "elite" then
        diabloTargetFrame.classificationTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\d3_elite.tga")
        diabloTargetFrame.classificationFrame:Show()
    else
        -- Normal, trivial, or minus - hide the indicator
        diabloTargetFrame.classificationFrame:Hide()
    end
    
    -- Update health bar
    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    diabloTargetFrame.healthBar:SetMinMaxValues(0, maxHealth)
    diabloTargetFrame.healthBar:SetValue(health)
    
    -- Update health bar color
    -- First check if boss red option is enabled and target is a boss/worldboss
    -- (classification variable is already defined above for the classification indicator)
    if _G.diablo_target_health_boss_red and (classification == "worldboss" or classification == "boss") then
        -- Use red for bosses/worldbosses
        diabloTargetFrame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
    elseif _G.diablo_target_health_classcolor and UnitIsPlayer("target") then
        -- Use class color (like party frames)
        local _, class = UnitClass("target")
        local color = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
        -- Make colors 10% more vibrant (like party frames)
        local vibrantR = math.min(1, color.r * 1.1)
        local vibrantG = math.min(1, color.g * 1.1)
        local vibrantB = math.min(1, color.b * 1.1)
        diabloTargetFrame.healthBar:SetStatusBarColor(vibrantR, vibrantG, vibrantB)
    else
        -- Use red or green based on setting (for non-players or when class color mode is disabled)
        if _G.diablo_target_health_green then
            diabloTargetFrame.healthBar:SetStatusBarColor(0, 1, 0, 1) -- Green (standard WoW green)
        else
            diabloTargetFrame.healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
        end
    end
    
    -- Update power bar
    local power = UnitPower("target")
    local maxPower = UnitPowerMax("target")
    diabloTargetFrame.powerBar:SetMinMaxValues(0, maxPower)
    diabloTargetFrame.powerBar:SetValue(power)
    
    -- Update power bar color based on power type
    local powerType = UnitPowerType("target")
    local powerColor = PowerBarColor[powerType] or PowerBarColor["MANA"]
    diabloTargetFrame.powerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b, 1)

    -- Update health / power text from Interface > Status Text
    -- Always set values; visibility = CVar on, or mouseover (Blizzard TextStatusBar style)
    local usePercent = DrakeishUI_StatusTextUsePercent and DrakeishUI_StatusTextUsePercent()
    local fmt = DrakeishUI_FormatStatusText
    if fmt then
        diabloTargetFrame.healthText:SetText(fmt(health, maxHealth, usePercent))
        diabloTargetFrame.powerText:SetText(fmt(power, maxPower, usePercent))
    else
        diabloTargetFrame.healthText:SetText(health .. " / " .. maxHealth)
        local powerPercent = maxPower > 0 and math.floor((power / maxPower) * 100) or 0
        diabloTargetFrame.powerText:SetText(powerPercent .. "%")
    end
    ApplyDiabloTargetStatusTextVisibility()
end

-- Event frame for updating target frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_LEVEL")
eventFrame:RegisterEvent("UNIT_FACTION")
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if not customFrameActive then
        return -- Don't update if custom frame is not active
    end
    
    if event == "PLAYER_TARGET_CHANGED" then
        -- Ensure TargetFrame stays hidden
        if TargetFrame then
            TargetFrame:Hide()
        end
        
        if UnitExists("target") then
            diabloTargetFrame:Show()
            UpdateDiabloTargetFrame()
        else
            diabloTargetFrame:Hide()
        end
    elseif unit == "target" then
        UpdateDiabloTargetFrame()
        -- Ensure TargetFrame stays hidden
        if TargetFrame then
            TargetFrame:Hide()
        end
    end
end)

-- Hook TargetFrame's Show method to prevent it from showing when custom frame is active
-- (targetFrameHooked and customFrameActive are already declared at the top)

local function HookTargetFrame()
    if TargetFrame and not targetFrameHooked then
        local originalShow = TargetFrame.Show
        TargetFrame.Show = function(self, ...)
            if customFrameActive then
                -- Force hide even if something tries to show it
                TargetFrame:Hide()
                return -- Don't show default frame when custom frame is active
            end
            originalShow(self, ...)
        end
        
        targetFrameHooked = true
    end
end

-- Function to unhook TargetFrame (restore original behavior)
local function UnhookTargetFrame()
    if TargetFrame and targetFrameHooked then
        -- Note: We can't fully restore the original Show method easily,
        -- but when customFrameActive is false, it will work normally
        -- The hook will remain but won't interfere when customFrameActive is false
    end
end

-- Periodic check to ensure TargetFrame stays hidden
local hideCheckFrame = CreateFrame("Frame")
hideCheckFrame:SetScript("OnUpdate", function(self, delta)
    if customFrameActive and TargetFrame then
        if TargetFrame:IsShown() then
            TargetFrame:Hide()
        end
    else
        -- Stop checking when custom frame is not active
        self:SetScript("OnUpdate", nil)
    end
end)

-- Function to show custom target frame and hide default
function ShowDiabloTargetFrame()
    if not diabloTargetFrame then
        return -- Frame not created yet
    end
    
    customFrameActive = true
    HookTargetFrame() -- Ensure hook is in place
    
    if TargetFrame then
        TargetFrame:Hide()
        -- Also hide all regions of TargetFrame to be safe
        local regions = {TargetFrame:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.Hide then
                region:Hide()
            end
        end
        -- Also hide all children (like TargetFrameTextureFrame, health bar, mana bar, etc.)
        -- Keep TargetFrameSpellBar — it is reparented under the Diablo health bar
        local children = {TargetFrame:GetChildren()}
        for _, child in ipairs(children) do
            if child and child ~= TargetFrameSpellBar and type(child.Hide) == "function" then
                pcall(function() child:Hide() end)
            end
            -- Also hide regions of children
            if child and child ~= TargetFrameSpellBar then
                local childRegions = {child:GetRegions()}
                for _, childRegion in ipairs(childRegions) do
                    if childRegion and childRegion.Hide then
                        pcall(function() childRegion:Hide() end)
                    end
                end
            end
        end
    end

    AttachTargetCastbarToDiablo()
    
    -- Start periodic check to keep TargetFrame hidden
    hideCheckFrame:SetScript("OnUpdate", function(self, delta)
        if customFrameActive and TargetFrame then
            if TargetFrame:IsShown() then
                TargetFrame:Hide()
                -- Also hide all regions and children when it tries to show
                local regions = {TargetFrame:GetRegions()}
                for _, region in ipairs(regions) do
                    if region and region.Hide then
                        region:Hide()
                    end
                end
                local children = {TargetFrame:GetChildren()}
                for _, child in ipairs(children) do
                    if child and child ~= TargetFrameSpellBar and type(child.Hide) == "function" then
                        pcall(function() child:Hide() end)
                    end
                end
            end
            -- Keep castbar anchored under Diablo health bar
            if TargetFrameSpellBar and diabloTargetFrame.healthBar then
                local _, rel = TargetFrameSpellBar:GetPoint(1)
                if rel ~= diabloTargetFrame.healthBar then
                    AttachTargetCastbarToDiablo()
                end
            end
        end
    end)
    
    -- Show frame if there's a target, otherwise it will show when target is selected
    if UnitExists("target") then
        diabloTargetFrame:Show()
        UpdateDiabloTargetFrame()
    else
        -- Don't show yet, but frame is active and will show when target is selected
        diabloTargetFrame:Hide()
    end
end

-- Store original TargetFrame state
local targetFrameChildren = {}

-- Function to hide custom target frame and show default
function HideDiabloTargetFrame()
    -- CRITICAL: Set customFrameActive to false FIRST so the hook doesn't interfere
    customFrameActive = false
    diabloTargetFrame:Hide()
    
    -- Stop periodic check
    hideCheckFrame:SetScript("OnUpdate", nil)

    RestoreTargetCastbar()
    
    if TargetFrame then
        -- Recursive function to show all children and their children
        local function ShowAllChildren(frame)
            if not frame then return end
            
            -- Skip TargetFrameDropDown — castbar is restored separately
            if frame == TargetFrameDropDown then
                return
            end
            
            -- Show the frame itself
            if type(frame.Show) == "function" then
                pcall(function() frame:Show() end)
            end
            
            -- Show all regions of this frame
            local regions = {frame:GetRegions()}
            for _, region in ipairs(regions) do
                if region and type(region.Show) == "function" then
                    -- Skip the backgrounds that DragonflightUI hides
                    if region ~= TargetFrameTextureFrameTexture and region ~= TargetFrameBackground then
                        pcall(function() region:Show() end)
                    end
                end
            end
            
            -- Recursively show all children (but skip TargetFrameDropDown)
            local children = {frame:GetChildren()}
            for _, child in ipairs(children) do
                if child and child ~= TargetFrameDropDown then
                    ShowAllChildren(child)
                end
            end
        end
        
        -- CRITICAL: Reapply DragonflightUI FIRST before showing TargetFrame
        -- This ensures all textures and borders are created/restored
        if _G.DragonflightUI and _G.DragonflightUI.Modules and _G.DragonflightUI.Modules.Unitframe then
            local Module = _G.DragonflightUI.Modules.Unitframe
            if Module.ChangeTargetFrame then
                pcall(function() Module.ChangeTargetFrame() end)
            end
        end
        
        -- CRITICAL: Always restore TargetFrame structure, even if no target
        -- This ensures portrait and border are ready when a target is selected
        if UnitExists("target") then
            -- CRITICAL: Show TargetFrame - the hook won't interfere because customFrameActive is false
            TargetFrame:Show()
        end
        
        -- Show all children recursively (do this regardless of target)
        ShowAllChildren(TargetFrame)
        
        -- Explicitly show the portrait and texture frame and ALL their children
        if TargetFrameTextureFrame then
            TargetFrameTextureFrame:Show()
            -- Show all children of TextureFrame (including portrait)
            ShowAllChildren(TargetFrameTextureFrame)
        end
        if TargetFramePortrait then
            TargetFramePortrait:Show()
            TargetFramePortrait:SetAlpha(1.0)
        end
        
        -- Show portrait background if it exists
        if TargetFramePortraitBackground then
            TargetFramePortraitBackground:Show()
        end
        
        -- Show border explicitly
        if _G.DragonflightUITargetFrameBorder then
            _G.DragonflightUITargetFrameBorder:Show()
            _G.DragonflightUITargetFrameBorder:SetAlpha(1.0)
        end
        
        -- Only call TargetFrame_Update if there's a target
        if UnitExists("target") then
            -- CRITICAL: Call TargetFrame_Update to trigger Blizzard's update logic
            -- This will properly show the portrait and update all elements
            if TargetFrame_Update then
                pcall(function() TargetFrame_Update() end)
            end
            
            -- After TargetFrame_Update, explicitly show portrait and border again (they might get hidden)
            if TargetFramePortrait then
                TargetFramePortrait:Show()
                TargetFramePortrait:SetAlpha(1.0)
            end
            if TargetFrameTextureFrame then
                TargetFrameTextureFrame:Show()
            end
            if _G.DragonflightUITargetFrameBorder then
                _G.DragonflightUITargetFrameBorder:Show()
                _G.DragonflightUITargetFrameBorder:SetAlpha(1.0)
            end
            
            -- Hide elements that DragonflightUI hides (to prevent semitransparent backgrounds)
            -- These must be hidden to match DragonflightUI behavior
            if TargetFrameTextureFrameTexture then
                TargetFrameTextureFrameTexture:Hide()
            end
            if TargetFrameBackground then
                TargetFrameBackground:Hide()
            end
            
            -- Hide TargetFrameDropDown; castbar is restored separately via RestoreTargetCastbar
            if TargetFrameDropDown then
                TargetFrameDropDown:Hide()
            end
        else
            -- No target exists, ensure TargetFrame is hidden
            TargetFrame:Hide()
        end
        
        -- Fix TargetFrameNameBackground transparency (DragonflightUI sets it to transparent)
        if TargetFrameNameBackground then
            -- Set it to fully transparent to match DragonflightUI behavior
            TargetFrameNameBackground:SetVertexColor(1, 1, 1, 0)
            -- Hook SetVertexColor to prevent it from being changed (like DragonflightUI does)
            if not TargetFrameNameBackground.SetVertexColorHooked then
                local originalSetVertexColor = TargetFrameNameBackground.SetVertexColor
                TargetFrameNameBackground.SetVertexColor = function(self, r, g, b, a)
                    -- Keep it transparent
                    if originalSetVertexColor then
                        originalSetVertexColor(self, 1, 1, 1, 0)
                    end
                end
                TargetFrameNameBackground.SetVertexColorHooked = true
            end
        end
        
        -- Hide status bar backgrounds that show when bars are empty
        -- Hook the status bars to hide background textures
        local function HideStatusBarBackgrounds(bar)
            if not bar then return end
            
            -- Get all regions of the status bar
            local regions = {bar:GetRegions()}
            for _, region in ipairs(regions) do
                if region and region:GetObjectType() == "Texture" then
                    local texture = region:GetTexture()
                    -- Hide background textures (these show when the bar is empty)
                    -- Background textures typically have "Background", "Empty", or are not the status bar texture itself
                    if texture then
                        local isStatusBarTexture = (region == bar:GetStatusBarTexture())
                        if not isStatusBarTexture then
                            -- This is a background texture, hide it
                            region:Hide()
                        end
                    end
                end
            end
            
            -- Also hook the Show method to ensure backgrounds stay hidden
            if not bar.BackgroundHideHooked then
                local originalShow = bar.Show
                bar.Show = function(self, ...)
                    originalShow(self, ...)
                    -- Hide backgrounds after showing
                    local regions = {self:GetRegions()}
                    for _, region in ipairs(regions) do
                        if region and region:GetObjectType() == "Texture" then
                            local isStatusBarTexture = (region == self:GetStatusBarTexture())
                            if not isStatusBarTexture then
                                region:Hide()
                            end
                        end
                    end
                end
                bar.BackgroundHideHooked = true
            end
        end
        
        HideStatusBarBackgrounds(TargetFrameHealthBar)
        HideStatusBarBackgrounds(TargetFrameManaBar)
        
        -- Restore TargetFrame's event handler if it exists
        if TargetFrame_OnEvent then
            TargetFrame:SetScript("OnEvent", TargetFrame_OnEvent)
        end
        
        -- CRITICAL: Reapply DragonflightUI modifications to restore border textures and all elements
        -- This must be called to ensure borders and other textures become visible
        -- Use a helper function that will be called multiple times with delays
        local function ReapplyDragonflightUITargetFrame()
            if _G.DragonflightUI and _G.DragonflightUI.Modules and _G.DragonflightUI.Modules.Unitframe then
                local Module = _G.DragonflightUI.Modules.Unitframe
                
                -- Call ChangeTargetFrame to recreate/restore border textures
                -- This function checks if border exists, so it will create it if missing
                if Module.ChangeTargetFrame then
                    pcall(function() Module.ChangeTargetFrame() end)
                end
                
                -- Force show border texture if it exists (it might be hidden)
                if Module.frame and Module.frame.TargetFrameBorder then
                    Module.frame.TargetFrameBorder:Show()
                    Module.frame.TargetFrameBorder:SetAlpha(1.0)
                end
                -- Also check global name (DragonflightUI might store it globally)
                if _G.DragonflightUITargetFrameBorder then
                    _G.DragonflightUITargetFrameBorder:Show()
                    _G.DragonflightUITargetFrameBorder:SetAlpha(1.0)
                end
                
                -- Also check if it's stored in the frame table
                if Module.frame and Module.frame.TargetFrameBackground then
                    Module.frame.TargetFrameBackground:Show()
                end
                if _G.DragonflightUITargetFrameBackground then
                    _G.DragonflightUITargetFrameBackground:Show()
                end
                
                -- Explicitly show portrait and texture frame
                if TargetFrameTextureFrame then
                    TargetFrameTextureFrame:Show()
                    -- Show all children of TextureFrame
                    ShowAllChildren(TargetFrameTextureFrame)
                end
                if TargetFramePortrait then
                    TargetFramePortrait:Show()
                    TargetFramePortrait:SetAlpha(1.0)
                end
                if TargetFramePortraitBackground then
                    TargetFramePortraitBackground:Show()
                end
                
                -- Call ReApplyTargetFrame to restore bar textures and colors
                if Module.ReApplyTargetFrame then
                    pcall(function() Module.ReApplyTargetFrame() end)
                end
            end
        end
        
        -- Call immediately
        ReapplyDragonflightUITargetFrame()
        
        -- Trigger update events to refresh TargetFrame elements
        -- This is safer than calling TargetFrame_Update directly
        if UnitExists("target") then
            -- CRITICAL: Call TargetFrame_Update again to ensure everything is updated
            if TargetFrame_Update then
                pcall(function() TargetFrame_Update() end)
            end
            
            -- Trigger target update events if the script exists
            local onEvent = TargetFrame:GetScript("OnEvent")
            if onEvent then
                pcall(onEvent, TargetFrame, "PLAYER_TARGET_CHANGED")
                pcall(onEvent, TargetFrame, "UNIT_HEALTH", "target")
                pcall(onEvent, TargetFrame, "UNIT_POWER_UPDATE", "target")
            end
            
            -- Also trigger multiple delayed updates to ensure everything refreshes
            -- Use multiple attempts because DragonflightUI might need time to initialize
            local delayedUpdateFrame = CreateFrame("Frame")
            local attemptCount = 0
            delayedUpdateFrame:SetScript("OnUpdate", function(self, delta)
                self.elapsed = (self.elapsed or 0) + delta
                attemptCount = attemptCount + 1
                
                -- Try at 0.05s, 0.15s, 0.3s, and 0.5s
                if (self.elapsed >= 0.05 and attemptCount == 1) or
                   (self.elapsed >= 0.15 and attemptCount == 2) or
                   (self.elapsed >= 0.3 and attemptCount == 3) or
                   (self.elapsed >= 0.5 and attemptCount == 4) then
                    
                    if UnitExists("target") and TargetFrame then
                        -- Reapply DragonflightUI again after delay to ensure everything is restored
                        ReapplyDragonflightUITargetFrame()
                        
                        -- Explicitly show portrait and texture frame
                        if TargetFrameTextureFrame then
                            TargetFrameTextureFrame:Show()
                            ShowAllChildren(TargetFrameTextureFrame)
                        end
                        if TargetFramePortrait then
                            TargetFramePortrait:Show()
                            TargetFramePortrait:SetAlpha(1.0)
                        end
                        if TargetFramePortraitBackground then
                            TargetFramePortraitBackground:Show()
                        end
                        
                        -- Show border explicitly
                        if _G.DragonflightUITargetFrameBorder then
                            _G.DragonflightUITargetFrameBorder:Show()
                            _G.DragonflightUITargetFrameBorder:SetAlpha(1.0)
                        end
                        
                        -- CRITICAL: Call TargetFrame_Update to refresh everything
                        if TargetFrame_Update then
                            pcall(function() TargetFrame_Update() end)
                        end
                        
                        -- After update, show everything again
                        if TargetFramePortrait then
                            TargetFramePortrait:Show()
                            TargetFramePortrait:SetAlpha(1.0)
                        end
                        if TargetFrameTextureFrame then
                            TargetFrameTextureFrame:Show()
                        end
                        if _G.DragonflightUITargetFrameBorder then
                            _G.DragonflightUITargetFrameBorder:Show()
                            _G.DragonflightUITargetFrameBorder:SetAlpha(1.0)
                        end
                        
                        local onEvent = TargetFrame:GetScript("OnEvent")
                        if onEvent then
                            pcall(onEvent, TargetFrame, "PLAYER_TARGET_CHANGED")
                        end
                    end
                    
                    if attemptCount >= 4 then
                        self:SetScript("OnUpdate", nil)
                    end
                end
            end)
        else
            -- Even if no target exists, we should still reapply DragonflightUI to restore the frame structure
            -- This ensures borders are visible when a target is selected later
            ReapplyDragonflightUITargetFrame()
            
            -- Also try again after a delay in case DragonflightUI needs time
            local delayedUpdateFrame = CreateFrame("Frame")
            delayedUpdateFrame:SetScript("OnUpdate", function(self, delta)
                self.elapsed = (self.elapsed or 0) + delta
                if self.elapsed >= 0.2 then
                    self:SetScript("OnUpdate", nil)
                    ReapplyDragonflightUITargetFrame()
                end
            end)
        end
    end
end

-- Replace placeholder functions with real ones
-- This ensures the real functions are used when ToggleDiabloOrbs is called
_G.ShowDiabloTargetFrame = ShowDiabloTargetFrame
_G.HideDiabloTargetFrame = HideDiabloTargetFrame

-- Function to toggle health bar color between class color and red/green
function _G.ToggleDiabloTargetHealthColor(useClassColor)
    if useClassColor == nil then
        -- Toggle if no parameter provided
        _G.diablo_target_health_classcolor = not _G.diablo_target_health_classcolor
    else
        -- Set to specified value
        _G.diablo_target_health_classcolor = useClassColor
    end
    
    -- Update the health bar color if the frame exists and is shown
    if diabloTargetFrame and diabloTargetFrame:IsShown() and UnitExists("target") then
        UpdateDiabloTargetFrame()
    end
    
    return _G.diablo_target_health_classcolor
end

-- Function to toggle non-player health bar color between green and red
function _G.ToggleDiabloTargetHealthGreen(useGreen)
    if useGreen == nil then
        -- Toggle if no parameter provided
        _G.diablo_target_health_green = not _G.diablo_target_health_green
    else
        -- Set to specified value
        _G.diablo_target_health_green = useGreen
    end
    
    -- Update the health bar color if the frame exists and is shown
    if diabloTargetFrame and diabloTargetFrame:IsShown() and UnitExists("target") then
        UpdateDiabloTargetFrame()
    end
    
    return _G.diablo_target_health_green
end

-- Function to toggle boss/worldboss health bar color (true = red, false = use normal logic)
function _G.ToggleDiabloTargetHealthBossRed(useBossRed)
    if useBossRed == nil then
        -- Toggle if no parameter provided
        _G.diablo_target_health_boss_red = not _G.diablo_target_health_boss_red
    else
        -- Set to specified value
        _G.diablo_target_health_boss_red = useBossRed
    end
    
    -- Update the health bar color if the frame exists and is shown
    if diabloTargetFrame and diabloTargetFrame:IsShown() and UnitExists("target") then
        UpdateDiabloTargetFrame()
    end
    
    return _G.diablo_target_health_boss_red
end

-- Hook into ToggleDiabloOrbs to detect state changes
local toggleHooked = false
local function HookToggleDiabloOrbs()
    if toggleHooked then return end
    
    -- Try to hook immediately if ToggleDiabloOrbs is already defined
    if _G.ToggleDiabloOrbs then
        local originalToggle = _G.ToggleDiabloOrbs
        _G.ToggleDiabloOrbs = function(show)
            originalToggle(show)
            -- Update target frame based on state
            if show then
                ShowDiabloTargetFrame()
            else
                HideDiabloTargetFrame()
            end
        end
        toggleHooked = true
        return
    end
    
    -- If not defined yet, wait for it
    local checkFrame = CreateFrame("Frame")
    checkFrame:SetScript("OnUpdate", function(self, delta)
        self.elapsed = (self.elapsed or 0) + delta
        if self.elapsed >= 0.05 then -- Check very frequently
            if _G.ToggleDiabloOrbs then
                -- Hook the function
                local originalToggle = _G.ToggleDiabloOrbs
                _G.ToggleDiabloOrbs = function(show)
                    originalToggle(show)
                    -- Update target frame based on state
                    if show then
                        ShowDiabloTargetFrame()
                    else
                        HideDiabloTargetFrame()
                    end
                end
                toggleHooked = true
                self:SetScript("OnUpdate", nil)
            elseif self.elapsed >= 3.0 then
                -- Give up after 3 seconds
                self:SetScript("OnUpdate", nil)
            end
        end
    end)
end

-- Try to hook immediately when file loads (ToggleDiabloOrbs is global)
HookToggleDiabloOrbs()

-- Immediately hide TargetFrame if Diablo Orbs are active (to prevent it showing on reload)
-- This runs before PLAYER_LOGIN to catch early visibility
local immediateHideFrame = CreateFrame("Frame")
immediateHideFrame:RegisterEvent("ADDON_LOADED")
immediateHideFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DrakeishUI" then
        -- Check if Diablo Orbs are active
        if _G.diablo_orbs_state == 1 then
            -- Hide TargetFrame immediately
            if TargetFrame then
                TargetFrame:Hide()
                -- Hide all regions
                local regions = {TargetFrame:GetRegions()}
                for _, region in ipairs(regions) do
                    if region and region.Hide then
                        region:Hide()
                    end
                end
                -- Hide all children
                local children = {TargetFrame:GetChildren()}
                for _, child in ipairs(children) do
                    if child and type(child.Hide) == "function" then
                        pcall(function() child:Hide() end)
                    end
                end
            end
            -- Set customFrameActive early
            customFrameActive = true
            HookTargetFrame() -- Set up hook immediately
        end
    end
end)

-- Initialize on PLAYER_LOGIN to check if Diablo Orbs are active
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DrakeishUI" then
        -- Try to hook again in case it wasn't available yet
        HookToggleDiabloOrbs()
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)
        
        -- Try to hook immediately
        HookToggleDiabloOrbs()
        
        -- Check state directly after ToggleDiabloOrbs is called (which happens at 0.5s)
        -- Check at multiple intervals to ensure we catch it
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            
            -- Check at 0.6s (right after ToggleDiabloOrbs is called at 0.5s)
            if self.elapsed >= 0.6 and not self.checked06 then
                self.checked06 = true
                -- Check if orbs are active by looking at state and visibility
                local orbsActive = false
                if diablo_orbs_state == 1 then
                    orbsActive = true
                elseif _G.D32_HealthOrb and _G.D32_HealthOrb:IsShown() then
                    orbsActive = true
                end
                
                if orbsActive then
                    -- Force show the custom frame (same as ToggleDiabloOrbs does)
                    if _G.ShowDiabloTargetFrame then
                        _G.ShowDiabloTargetFrame()
                    end
                else
                    HideDiabloTargetFrame()
                end
            end
            
            -- Check again at 0.8s to catch any late updates
            if self.elapsed >= 0.8 and not self.checked08 then
                self.checked08 = true
                local orbsActive = false
                if diablo_orbs_state == 1 then
                    orbsActive = true
                elseif _G.D32_HealthOrb and _G.D32_HealthOrb:IsShown() then
                    orbsActive = true
                end
                
                if orbsActive and not customFrameActive then
                    -- Only call if not already active (avoid duplicate calls)
                    ShowDiabloTargetFrame()
                elseif not orbsActive and customFrameActive then
                    HideDiabloTargetFrame()
                end
            end
            
            -- Final check at 1.5s
            if self.elapsed >= 1.5 and not self.checked15 then
                self.checked15 = true
                local orbsActive = false
                if diablo_orbs_state == 1 then
                    orbsActive = true
                elseif _G.D32_HealthOrb and _G.D32_HealthOrb:IsShown() then
                    orbsActive = true
                end
                
                if orbsActive and not customFrameActive then
                    ShowDiabloTargetFrame()
                elseif not orbsActive and customFrameActive then
                    HideDiabloTargetFrame()
                end
            end
            
            -- Stop after 2 seconds
            if self.elapsed >= 2.0 then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Refresh Diablo target status text when Interface > Status Text CVars change
if DrakeishUI_RegisterStatusTextListener then
    DrakeishUI_RegisterStatusTextListener(function()
        if customFrameActive and UpdateDiabloTargetFrame then
            UpdateDiabloTargetFrame()
        end
    end)
end

