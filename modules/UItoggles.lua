local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;

-- Main toggle button to the left of CharacterMicroButton.
-- The micro menu is scaled, so match that on-screen size (14x19 at scale_menu)
-- and leave the same 1px gap the other buttons use.
local menuScale = (config.micromenu and config.micromenu.scale_menu) or 1.4
local microW, microH = 14 * menuScale, 19 * menuScale
local microGap = menuScale

local mainToggleButton = CreateFrame('Button', 'DrakeishUI_MainToggle', UIParent)
mainToggleButton:SetSize(microW, microH)
mainToggleButton:SetPoint('RIGHT', CharacterMicroButton, 'LEFT', -microGap, 0)
mainToggleButton:SetFrameStrata('TOOLTIP')
mainToggleButton:SetFrameLevel(1000)

-- enable mouseover

local enableMouseOver = function(frame, includeChildren)
	local show = function()
		frame:SetAlpha(1)
	end

	local hide = function()
		frame:SetAlpha(0)
	end

	-- Clear existing scripts first
	frame:SetScript("OnEnter", nil)
	frame:SetScript("OnLeave", nil)
	
	-- Clear children scripts if they exist
	for _, child in ipairs({frame:GetChildren()}) do
		child:SetScript("OnEnter", nil)
		child:SetScript("OnLeave", nil)
	end

	if includeChildren then
		frame:EnableMouse(true)
		frame:HookScript("OnEnter", show)
		frame:HookScript("OnLeave", hide)
		
		for _, child in ipairs({frame:GetChildren()}) do
			child:HookScript("OnEnter", show)
			child:HookScript("OnLeave", hide)
		end
		hide()
	else
		-- Disable mouseover functionality but keep button clickable
		frame:EnableMouse(true) -- Keep button clickable
		frame:SetAlpha(1) -- Keep button visible when mouseover is disabled
	end
end



-- Function to update button position based on micromenu visibility
local function UpdateButtonPosition()
    -- Check if micromenu is hidden (bags_state == 1 means micromenu is hidden)
    if bags_state == 1 then
        -- Sit on the game menu button, hidden until the cursor is over it.
        mainToggleButton:ClearAllPoints()
        mainToggleButton:SetPoint('CENTER', MainMenuMicroButton, 'CENTER', 0, 0)
        enableMouseOver(mainToggleButton, true)
    else
        -- Move to original position when micromenu is visible
        mainToggleButton:ClearAllPoints()
        mainToggleButton:SetPoint('RIGHT', CharacterMicroButton, 'LEFT', -microGap, 0)
        -- Disable mouseover when micromenu is visible
        enableMouseOver(mainToggleButton, false)
    end
end

-- uimicromenu2x_add, third row. Columns match the other micro icons:
-- 4 = normal, 3 = pushed, 2 = highlight.
local MICRO_ADD = 'Interface\\AddOns\\DrakeishUI\\assets\\uimicromenu2x_add'
local MICRO_ROW_TOP, MICRO_ROW_BOTTOM = 109/512, 161/512
local MICRO_COORDS = {
    normal    = { 121/256, 159/256, MICRO_ROW_TOP, MICRO_ROW_BOTTOM },
    pushed    = { 81/256,  119/256, MICRO_ROW_TOP, MICRO_ROW_BOTTOM },
    -- Highlight art is drawn 3px left of the normal art inside its cell.
    highlight = { 38/256,  76/256,  MICRO_ROW_TOP, MICRO_ROW_BOTTOM },
}

local function FitButtonTexture(region, coords)
    if not region then return end
    region:ClearAllPoints()
    region:SetAllPoints(mainToggleButton)
    region:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end

local function ApplyMainToggleAtlas()
    mainToggleButton:SetNormalTexture(MICRO_ADD)
    mainToggleButton:SetPushedTexture(MICRO_ADD)
    mainToggleButton:SetHighlightTexture(MICRO_ADD)
    FitButtonTexture(mainToggleButton:GetNormalTexture(), MICRO_COORDS.normal)
    FitButtonTexture(mainToggleButton:GetPushedTexture(), MICRO_COORDS.pushed)
    local highlightRegion = mainToggleButton:GetHighlightTexture()
    FitButtonTexture(highlightRegion, MICRO_COORDS.highlight)
    if highlightRegion then
        highlightRegion:SetAlpha(1)
        highlightRegion:SetBlendMode('BLEND')
    end
end

-- While the settings window is open the button stays on the pushed slice.
local function SetMainToggleState(state)
    mainToggleButton:SetNormalTexture(MICRO_ADD)
    FitButtonTexture(mainToggleButton:GetNormalTexture(), MICRO_COORDS[state])
end

ApplyMainToggleAtlas()

-- Main toggle window (using same style as chatcopy)
local tooltipFrame = CreateFrame('Frame', 'DrakeishUI_ToggleTooltip', UIParent)
tooltipFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, 
    tileSize = 16, 
    edgeSize = 16,
    insets = {left = 3, right = 3, top = 5, bottom = 3}
})
tooltipFrame:SetBackdropColor(0, 0, 0, 0.9)
tooltipFrame:SetWidth(500)
tooltipFrame:SetHeight(255) -- Extra row under the nameplate line for Reload
tooltipFrame:SetPoint("CENTER", UIParent, "CENTER")
tooltipFrame:Hide()
tooltipFrame:SetFrameStrata("DIALOG")

-- Add to UISpecialFrames for proper escape key handling
table.insert(UISpecialFrames, "DrakeishUI_ToggleTooltip")

-- Global Esc key handler
tooltipFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        tooltipFrame:Hide()
    end
end)
tooltipFrame:EnableKeyboard(true)

-- Title bar
local titleBar = CreateFrame("Frame", nil, tooltipFrame)
titleBar:SetHeight(25)
titleBar:SetPoint("TOPLEFT", tooltipFrame, "TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", tooltipFrame, "TOPRIGHT", 0, 0)

-- Title text
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 2)
titleText:SetText("DrakeishUI Settings")
titleText:SetTextColor(1, 0.82, 0) -- Blizzard's standard yellow color

-- Close button
local closeButton = CreateFrame("Button", "DrakeishUI_ToggleClose", tooltipFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", tooltipFrame, "TOPRIGHT", 2, 2)
closeButton:SetScript("OnClick", function() 
    tooltipFrame:Hide() 
end)

-- Same chrome as the other modern windows: metal outer frame, light stone, dark inner well.
local function SkinSettingsWindow(f)
    local NE = DrakeishUI_SocialNE
    local PC = NE and NE.panelchrome
    if not PC or not PC.Apply or f._neSettingsSkinned then return end
    if f.SetBackdrop then f:SetBackdrop(nil) end
    PC.Apply(f, {
        layout = "ButtonFrameTemplateNoPortrait",
        noPortrait = true,
        noCloseButton = true,
    })
    if f.Bg then
        f.Bg:SetVertexColor(1, 1, 1)
        f.Bg:ClearAllPoints()
        f.Bg:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -20)
        f.Bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 4)
    end
    local well = CreateFrame("Frame", nil, f)
    well:EnableMouse(false)
    well:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -32)
    well:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 8)
    local bg = well:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.06, 0.06, 0.07, 0.75)
    bg:SetAllPoints(well)
    if NE.nineslice and NE.nineslice.AttachInset then
        local border = NE.nineslice.AttachInset(well, 0, 0, 0, 0)
        local base = f:GetFrameLevel() or 1
        well:SetFrameLevel(base + 2)
        if border then border:SetFrameLevel(base + 3) end
    end
    titleBar:SetFrameLevel((f:GetFrameLevel() or 1) + 12)
    if PC.ModernizeCloseButton then
        PC.ModernizeCloseButton(closeButton, { frameLevelBump = 20 })
    end
    f._neSettingsSkinned = true
end
SkinSettingsWindow(tooltipFrame)

-- Checkbox rows sit 6px below the title so they land inside the dark well.
-- Title stays on the metal cap; every checkbox line and the Reload button
-- is anchored to this point.
local contentAnchor = CreateFrame("Frame", nil, tooltipFrame)
contentAnchor:SetSize(1, 1)
contentAnchor:SetPoint("BOTTOMLEFT", titleText, "BOTTOMLEFT", 0, -10)
local tooltipTitle = contentAnchor

-- Create 10 toggle buttons in 2 columns
local toggleButtons = {}

-- Helper function to create checkbox
local function CreateCheckbox(parent, name, text, x, y, onClick)
    local button = CreateFrame('CheckButton', name, parent)
    button:SetSize(20, 20)
    button:SetPoint('TOPLEFT', tooltipTitle, 'BOTTOMLEFT', x, y)
    button:SetFrameStrata('DIALOG')
    button:SetFrameLevel(parent:GetFrameLevel() + 10)
    
    -- Create checkbox textures
    local normal = button:CreateTexture(nil, 'ARTWORK')
    normal:SetAllPoints()
    normal:SetTexture('Interface\\Buttons\\UI-CheckBox-Up')
    button:SetNormalTexture(normal)
    
    local pushed = button:CreateTexture(nil, 'ARTWORK')
    pushed:SetAllPoints()
    pushed:SetTexture('Interface\\Buttons\\UI-CheckBox-Down')
    button:SetPushedTexture(pushed)
    
    local checked = button:CreateTexture(nil, 'ARTWORK')
    checked:SetAllPoints()
    checked:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
    button:SetCheckedTexture(checked)
    
    local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
    highlight:SetAllPoints()
    highlight:SetTexture('Interface\\Buttons\\UI-CheckBox-Highlight')
    button:SetHighlightTexture(highlight)
    
    -- Create text label
    local buttonText = button:CreateFontString(nil, 'OVERLAY')
    buttonText:SetFont('Interface\\AddOns\\DrakeishUI\\assets\\expressway.ttf', 12, 'OUTLINE')
    buttonText:SetTextColor(1, 1, 1, 1)
    buttonText:SetPoint('LEFT', button, 'RIGHT', 5, 0)
    buttonText:SetText(text)
    button.label = buttonText
    
    -- Set click handler
    button:SetScript('OnClick', onClick)
    
    return button
end

-- Column 1 (Left): Party Frames, Chat Frame, Stance Bar, Gryphons
local button1 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle1', 'Toggle Party Frames', -175, -15, function(self)
    -- Check if in combat
    if InCombatLockdown() then
        -- Reset checkbox state to prevent visual change
        self:SetChecked(not self:GetChecked())
        -- Show combat message
        UIErrorsFrame:AddMessage("Cannot toggle party frames while in combat!", 1.0, 1.0, 0.0, 1.0)
        return
    end
    
    -- Use the existing partyToggleButton by its global name
    if _G.partytoggle then
        _G.partytoggle:Click()
    else
        -- Fallback to simple party frame toggle
        local checked = self:GetChecked()
        if checked then
            -- Hide all custom party frames
            for i = 1, 4 do
                local frame = _G['CustomPartyFrame' .. i]
                if frame then
                    frame:Hide()
                end
            end
            party_state = 1
        else
            -- Show party frames if they have members
            for i = 1, 4 do
                local frame = _G['CustomPartyFrame' .. i]
                if frame then
                    local unit = "party"..i
                    if UnitExists(unit) then
                        frame:Show()
                    else
                        frame:Hide()
                    end
                end
            end
            party_state = 0
        end
    end
end)

local button2 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle2', 'Toggle Chat Frame', -175, -40, function(self)
    -- Use the existing chatToggleButton by its global name
    if _G.chattoggle then
        _G.chattoggle:Click()
    else
        -- Fallback to simple chat frame toggle
        local checked = self:GetChecked()
        chat_state = checked and 1 or 0
        if _G.DrakeishUI_ApplyChatView then
            _G.DrakeishUI_ApplyChatView()
        elseif checked then
            ChatFrame1:Hide()
            if ChatFrame2 then ChatFrame2:Hide() end
            ChatFrame1EditBox:Hide()
            if _G.UnifiedInfoFrame then _G.UnifiedInfoFrame:Hide() end
        else
            ChatFrame1:Show()
            if _G.UnifiedInfoFrame then _G.UnifiedInfoFrame:Show() end
        end
    end
end)

local button3 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle3', 'Toggle Stance Bar', -175, -65, function(self)
    -- Use the existing stanceToggleButton by its global name
    if _G.stancetoggle then
        _G.stancetoggle:Click()
    else
        -- Fallback to simple StanceBarFrame toggle
        local checked = self:GetChecked()
        if checked then
            StanceBarFrame:Hide()
        else
            StanceBarFrame:Show()
        end
    end
end)

local button4 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle4', 'Toggle Gryphons', -175, -90, function(self)
    -- Use the existing capsToggleButton by its global name
    if _G.gryphontoggle then
        _G.gryphontoggle:Click()
    else
        -- Fallback to simple gryphon toggle
        local checked = self:GetChecked()
        if checked then
            MainMenuBarLeftEndCap:Hide()
            MainMenuBarRightEndCap:Hide()
        else
            MainMenuBarLeftEndCap:Show()
            MainMenuBarRightEndCap:Show()
        end
    end
end)

-- Column 2 (Right): Bottom Bars, Side Bars, Micromenu, Quest Frame
local button5 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle5', 'Toggle Bottom Bars', -25, -15, function(self)
    -- Use the existing bottombarstoggle button by its global name
    if _G.bottombarstoggle then
        _G.bottombarstoggle:Click()
    else
        -- Fallback to simple bottom bars toggle
        local checked = self:GetChecked()
        if checked then
            MainMenuBar:Hide()
        else
            MainMenuBar:Show()
        end
    end
end)

-- Modify button5 to show state numbers instead of checkmark
local stateText = button5:CreateFontString(nil, 'OVERLAY')
stateText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
stateText:SetTextColor(1, 1, 0, 1) -- Yellow color to match checkmarks
stateText:SetPoint('CENTER', button5, 'CENTER', 0, 0)

-- Hide the checkmark texture and only show the number
button5:SetCheckedTexture(nil)

-- Update state display function
local function UpdateBottomBarsDisplay()
    if not bottombars_state then bottombars_state = 0 end
    stateText:SetText(tostring(bottombars_state + 1))
end

-- Override the original click handler to include state display update
local originalClick = button5:GetScript('OnClick')
button5:SetScript('OnClick', function(self)
    originalClick(self)
    -- Update display after a short delay
    local timer = CreateFrame("Frame")
    timer:SetScript("OnUpdate", function(self, delta)
        self.elapsed = (self.elapsed or 0) + delta
        if self.elapsed >= 0.1 then
            UpdateBottomBarsDisplay()
            self:SetScript("OnUpdate", nil)
        end
    end)
end)

local button6 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle6', 'Toggle Side Bars', -25, -40, function(self)
    -- Use the existing sidebarstoggle button by its global name
    if _G.sidebarstoggle then
        _G.sidebarstoggle:Click()
    else
        -- Fallback to simple side bars toggle
        local checked = self:GetChecked()
        if checked then
            MultiBarLeft:Hide()
            MultiBarRight:Hide()
        else
            MultiBarLeft:Show()
            MultiBarRight:Show()
        end
    end
end)

local button7 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle7', 'Toggle Micromenu', -25, -65, function(self)
    -- Use the existing bagsToggleButton by its global name
    if _G.bagstoggle then
        _G.bagstoggle:Click()
        -- Update button position immediately after clicking (bags_state is updated synchronously)
        UpdateButtonPosition()
    else
        -- Fallback to simple micromenu toggle
        local checked = self:GetChecked()
        if checked then
            MainMenuBarArtFrame:Hide()
            bags_state = 1
        else
            MainMenuBarArtFrame:Show()
            bags_state = 0
        end
        -- Update button position immediately
        UpdateButtonPosition()
    end
end)

local button8 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle8', 'Toggle Quest Frame', -25, -90, function(self)
    -- Use the existing questToggleButton by its global name
    if _G.watchframetoggle then
        _G.watchframetoggle:Click()
    else
        -- Fallback to simple quest frame toggle
        local checked = self:GetChecked()
        if checked then
            QuestWatchFrame:Hide()
        else
            QuestWatchFrame:Show()
        end
    end
end)

-- Column 3 (Right): Buff frame, Hide main toggle buttons, Move Unitframes
local button9 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle9', 'Toggle Buff Frame', 125, -15, function(self)
    -- Use the existing buffstoggle button by its global name
    if _G.buffstoggle then
        _G.buffstoggle:Click()
        -- Update checkbox state after a short delay to match the actual frame state
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.1 then
                -- Check the actual state of the buff frames and update checkbox accordingly
                -- Inverted display logic: visible = unchecked, hidden = checked
                -- Use button9 or fallback to global frame name
                local buffButton = button9 or _G.DrakeishUI_Toggle9
                if buffButton then
                    if BuffFrame:IsShown() then
                        buffButton:SetChecked(false)  -- Visible = unchecked (inverted display)
                        buffs_state = 1
                    else
                        buffButton:SetChecked(true)   -- Hidden = checked (inverted display)
                        buffs_state = 0
                    end
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    else
        -- Fallback to simple buff frame toggle with normal logic (matching existing buffstoggle)
        local checked = self:GetChecked()
        if checked then
            -- Show buff frames when checked
            BuffFrame:Show()
            TemporaryEnchantFrame:Show()
            buffs_state = 1
        else
            -- Hide buff frames when unchecked
            BuffFrame:Hide()
            TemporaryEnchantFrame:Hide()
            buffs_state = 0
        end
    end
end)

local button10 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle10', 'Hide UI Toggles', 125, -40, function(self)
    local checked = self:GetChecked()
    if checked then
        -- Hide all main toggle buttons
        if _G.partytoggle then _G.partytoggle:Hide() end
        if _G.chattoggle then _G.chattoggle:Hide() end
        if _G.DrakeishUI_ChatViewToggle then _G.DrakeishUI_ChatViewToggle:Hide() end
        if _G.stancetoggle then _G.stancetoggle:Hide() end
        if _G.gryphontoggle then _G.gryphontoggle:Hide() end
        if _G.bottombarstoggle then _G.bottombarstoggle:Hide() end
        if _G.sidebarstoggle then _G.sidebarstoggle:Hide() end
        if _G.bagstoggle then _G.bagstoggle:Hide() end
        if _G.watchframetoggle then _G.watchframetoggle:Hide() end
        if _G.buffstoggle then _G.buffstoggle:Hide() end
        if _G.maintoggle then _G.maintoggle:Hide() end
        if _G.pUiArrowManager then _G.pUiArrowManager:Hide() end
        hide_toggle_buttons = 1
    else
        -- Show all main toggle buttons
        if _G.partytoggle then _G.partytoggle:Show() end
        if _G.chattoggle then _G.chattoggle:Show() end
        if _G.DrakeishUI_ChatViewToggle then _G.DrakeishUI_ChatViewToggle:Show() end
        if _G.stancetoggle then _G.stancetoggle:Show() end
        if _G.gryphontoggle then _G.gryphontoggle:Show() end
        if _G.bottombarstoggle then _G.bottombarstoggle:Show() end
        if _G.sidebarstoggle then _G.sidebarstoggle:Show() end
        if _G.bagstoggle then _G.bagstoggle:Show() end
        if _G.watchframetoggle then _G.watchframetoggle:Show() end
        if _G.buffstoggle then _G.buffstoggle:Show() end
        if _G.maintoggle then _G.maintoggle:Show() end
        if _G.pUiArrowManager then _G.pUiArrowManager:Show() end
        hide_toggle_buttons = 0
    end
	hide_toggle_buttons = checked and 1 or 0
end)

-- Store original positions for unitframes and castbars
local originalPositions = {}

local function StoreOriginalPositions()
    -- Store PlayerFrame position
    local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint(1)
    originalPositions.player = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
    
    -- Store TargetFrame position
    local point, relativeTo, relativePoint, xOfs, yOfs = TargetFrame:GetPoint(1)
    originalPositions.target = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
    
    -- Store FocusFrame position (if it exists)
    if FocusFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = FocusFrame:GetPoint(1)
        originalPositions.focus = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }
    end
    
    -- Store CastingBarFrame position
    local point, relativeTo, relativePoint, xOfs, yOfs = CastingBarFrame:GetPoint(1)
    originalPositions.castbar = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
    
    -- Store TargetFrameSpellBar position (if it exists)
    if TargetFrameSpellBar then
        local point, relativeTo, relativePoint, xOfs, yOfs = TargetFrameSpellBar:GetPoint(1)
        originalPositions.targetCastbar = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }
    end
end

local function MoveToDragonflightPositions()
    -- DragonflightUI positions above action bars
    -- Player frame: left side above action bar
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 320, 200)
    
    -- Target frame: right side above action bar
    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -320, 200)
    
    -- Focus frame: center above action bar
    if FocusFrame then
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 22, 740)
    end
    
    -- Player castbar: center above action bar
    CastingBarFrame:ClearAllPoints()
    CastingBarFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 250)
    
    -- Target castbar: below target frame (use same position as Castbar.lua)
    if TargetFrameSpellBar then
        TargetFrameSpellBar:ClearAllPoints()
        TargetFrameSpellBar:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 25 - 20, 22)
    end
end

local function RestoreOriginalPositions()
    -- Restore PlayerFrame position
    if originalPositions.player then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint(originalPositions.player.point, originalPositions.player.relativeTo, originalPositions.player.relativePoint, originalPositions.player.x, originalPositions.player.y)
    end
    
    -- Restore TargetFrame position
    if originalPositions.target then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint(originalPositions.target.point, originalPositions.target.relativeTo, originalPositions.target.relativePoint, originalPositions.target.x, originalPositions.target.y)
    end
    
    -- Restore FocusFrame position
    if originalPositions.focus and FocusFrame then
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint(originalPositions.focus.point, originalPositions.focus.relativeTo, originalPositions.focus.relativePoint, originalPositions.focus.x, originalPositions.focus.y)
    end
    
    -- Restore CastingBarFrame position
    if originalPositions.castbar then
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame:SetPoint(originalPositions.castbar.point, originalPositions.castbar.relativeTo, originalPositions.castbar.relativePoint, originalPositions.castbar.x, originalPositions.castbar.y)
    end
    
    -- Restore TargetFrameSpellBar position
    if originalPositions.targetCastbar and TargetFrameSpellBar then
        TargetFrameSpellBar:ClearAllPoints()
        TargetFrameSpellBar:SetPoint(originalPositions.targetCastbar.point, originalPositions.targetCastbar.relativeTo, originalPositions.targetCastbar.relativePoint, originalPositions.targetCastbar.x, originalPositions.targetCastbar.y)
    end
end

local button11 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle11', 'Reposition Unitframes', 125, -65, function(self)
    local checked = self:GetChecked()
    
    if checked then
        -- Disable Diablo Orbs checkbox to prevent conflicts
        local diabloButton = _G.DrakeishUI_Toggle13
        if diabloButton then
            diabloButton:Disable()
            diabloButton:SetAlpha(0.5)
        end
        
        -- Move to DragonflightUI positions above action bars
        MoveToDragonflightPositions()
        unitframes_state = 1
        
        -- Move party frames up to avoid overlap
        if _G.UpdatePartyFramePositions then
            _G.UpdatePartyFramePositions()
        end
        
        -- Re-apply positions after a short delay to ensure they stick
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.1 then
                MoveToDragonflightPositions()
                if _G.UpdatePartyFramePositions then
                    _G.UpdatePartyFramePositions()
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
    else
        -- Re-enable Diablo Orbs checkbox
        local diabloButton = _G.DrakeishUI_Toggle13
        if diabloButton then
            diabloButton:Enable()
            diabloButton:EnableMouse(true)
            diabloButton:SetAlpha(1.0)
        end
        
        -- Restore original positions
        RestoreOriginalPositions()
        unitframes_state = 0
        
        -- Move party frames back to normal position
        if _G.UpdatePartyFramePositions then
            _G.UpdatePartyFramePositions()
        end
    end
    unitframes_state = checked and 1 or 0
end)

-- Gryphon style functions
-- Orbs sit on screen edge (Y=0); keep angel/demon at their pre-move height (+15 vs old offset 5)
local ANGEL_DEMON_Y = 20
local GRYPHON_STYLE_MAX = 13 -- 1-3 gryphons, 4 angel/demon, 5-13 End_caps pairs
local ENDCAP_MEDIA = "Interface\\AddOns\\DrakeishUI\\assets\\End_caps\\"
local ENDCAP_SIZE = 160
local ENDCAP_LEFT_X = -64
local ENDCAP_RIGHT_X = 44

local function EnsureCustomEndCaps()
    if _G.DrakeishUI_EndCapLeft and _G.DrakeishUI_EndCapRight then
        return _G.DrakeishUI_EndCapLeft, _G.DrakeishUI_EndCapRight
    end

    local left = CreateFrame("Frame", "DrakeishUI_EndCapLeft", UIParent)
    left:SetWidth(ENDCAP_SIZE)
    left:SetHeight(ENDCAP_SIZE)
    left:SetFrameStrata("MEDIUM")
    left:SetFrameLevel(3)
    left.texture = left:CreateTexture(nil, "OVERLAY")
    left.texture:SetAllPoints(left)
    left:Hide()

    local right = CreateFrame("Frame", "DrakeishUI_EndCapRight", UIParent)
    right:SetWidth(ENDCAP_SIZE)
    right:SetHeight(ENDCAP_SIZE)
    right:SetFrameStrata("MEDIUM")
    right:SetFrameLevel(3)
    right.texture = right:CreateTexture(nil, "OVERLAY")
    right.texture:SetAllPoints(right)
    right:Hide()

    return left, right
end

local function HideCustomEndCaps()
    if _G.DrakeishUI_EndCapLeft then _G.DrakeishUI_EndCapLeft:Hide() end
    if _G.DrakeishUI_EndCapRight then _G.DrakeishUI_EndCapRight:Hide() end
end

-- Place left/right artwork the same way as angel/demon (orb-anchored)
local function PlaceOrbSideArtwork(leftFrame, rightFrame)
    if not leftFrame or not rightFrame then return end

    local orbsShown = _G.D32_HealthOrb and _G.D32_HealthOrb:IsShown()
        and _G.D32_ManaOrb and _G.D32_ManaOrb:IsShown()

    if orbsShown then
        if _G.manaOrb then
            leftFrame:SetParent(_G.manaOrb)
            leftFrame:ClearAllPoints()
            leftFrame:SetPoint("CENTER", _G.manaOrb, "CENTER", ENDCAP_LEFT_X, ANGEL_DEMON_Y)
            leftFrame:SetFrameStrata("MEDIUM")
            leftFrame:SetFrameLevel(3)
            leftFrame:Show()
        end
        if _G.healthOrb then
            rightFrame:SetParent(_G.healthOrb)
            rightFrame:ClearAllPoints()
            rightFrame:SetPoint("CENTER", _G.healthOrb, "CENTER", ENDCAP_RIGHT_X, ANGEL_DEMON_Y)
            rightFrame:SetFrameStrata("MEDIUM")
            rightFrame:SetFrameLevel(3)
            rightFrame:Show()
        end
    else
        if _G.manaOrb then
            leftFrame:SetParent(UIParent)
            leftFrame:ClearAllPoints()
            leftFrame:SetFrameStrata("MEDIUM")
            leftFrame:SetFrameLevel(3)
            local absX, absY = _G.manaOrb:GetCenter()
            if absX and absY then
                leftFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absX + ENDCAP_LEFT_X, absY + ANGEL_DEMON_Y)
            else
                leftFrame:SetPoint("CENTER", UIParent, "CENTER", ENDCAP_LEFT_X, ANGEL_DEMON_Y)
            end
            leftFrame:Show()
        end
        if _G.healthOrb then
            rightFrame:SetParent(UIParent)
            rightFrame:ClearAllPoints()
            rightFrame:SetFrameStrata("MEDIUM")
            rightFrame:SetFrameLevel(3)
            local absX, absY = _G.healthOrb:GetCenter()
            if absX and absY then
                rightFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absX + ENDCAP_RIGHT_X, absY + ANGEL_DEMON_Y)
            else
                rightFrame:SetPoint("CENTER", UIParent, "CENTER", ENDCAP_RIGHT_X + 6, ANGEL_DEMON_Y)
            end
            rightFrame:Show()
        end
    end
end

function ApplyGryphonStyle(style)
    if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return end
    style = style or 1

    -- Always clear custom end caps first; angel/demon handled per-style
    HideCustomEndCaps()

    -- Styles 5-13: End_caps pairs (ecl_N / ecr_N), same size/pos as angel & demon
    if style >= 5 and style <= 13 then
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
        if _G.D32AngelFrame then _G.D32AngelFrame:Hide() end
        if _G.D32DemonFrame then _G.D32DemonFrame:Hide() end

        if caps_state == 0 then
            if D32CharacterData then D32CharacterData.artwork.show = false end
            return
        end

        local pair = style - 4 -- 1..9
        local left, right = EnsureCustomEndCaps()
        left.texture:SetTexture(ENDCAP_MEDIA .. "ecl_" .. pair)
        right.texture:SetTexture(ENDCAP_MEDIA .. "ecr_" .. pair)
        PlaceOrbSideArtwork(left, right)
        if D32CharacterData then D32CharacterData.artwork.show = true end
        return
    end

    -- Handle angel/demon state (4)
    if style == 4 then -- angel and demon together
        -- Hide gryphons
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
        
        -- Check if toggle is off - if so, hide angel/demon and return
        if caps_state == 0 then
            if _G.D32AngelFrame then _G.D32AngelFrame:Hide() end
            if _G.D32DemonFrame then _G.D32DemonFrame:Hide() end
            -- Update saved state
            if D32CharacterData then D32CharacterData.artwork.show = false end
            return
        end
        
        PlaceOrbSideArtwork(_G.D32AngelFrame, _G.D32DemonFrame)
        -- Update saved state
        if D32CharacterData then D32CharacterData.artwork.show = true end
        return
    else
        -- Hide angel/demon for gryphon styles
        if _G.D32AngelFrame then _G.D32AngelFrame:Hide() end
        if _G.D32DemonFrame then _G.D32DemonFrame:Hide() end
        -- Update saved state
        if D32CharacterData then D32CharacterData.artwork.show = false end
    end
    
    if caps_state == 0 then
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
        return
    end
        if style == 1 then -- old
        if addon.SetEndCapBasePoints then
            addon.SetEndCapBasePoints(-82, 84, -22)
        else
            MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -82, -22)
            MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
        end
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif style == 2 then -- new
        if addon.SetEndCapBasePoints then
            addon.SetEndCapBasePoints(-95, 95, -23)
        else
            MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
            MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
        end
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif style == 3 then -- flying
        if addon.SetEndCapBasePoints then
            addon.SetEndCapBasePoints(-80, 80, -21)
        else
            MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
            MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
        end
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    else -- hide
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end
    
end

-- Gryphon style checkbox with number states
local button12 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle12', 'Choose Gryphon Style', 125, -90, function(self)
    -- Cycle: 1-3 gryphons, 4 angel+demon, 5-13 End_caps pairs
    gryphon_style_state = (gryphon_style_state or 1) + 1
    if gryphon_style_state > GRYPHON_STYLE_MAX then
        gryphon_style_state = 1
    end
    
    -- Apply the new style
    ApplyGryphonStyle(gryphon_style_state)
end)

-- Modify button12 to show state numbers instead of checkmark
local gryphonStyleStateText = button12:CreateFontString(nil, 'OVERLAY')
gryphonStyleStateText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
gryphonStyleStateText:SetTextColor(1, 1, 0, 1) -- Yellow color to match checkmarks
gryphonStyleStateText:SetPoint('CENTER', button12, 'CENTER', 0, 0)

-- Hide the checkmark texture and only show the number
button12:SetCheckedTexture(nil)

-- Update state display function
local function UpdateGryphonStyleDisplay()
    if not gryphon_style_state then gryphon_style_state = 1 end
    gryphonStyleStateText:SetText(tostring(gryphon_style_state))
end

-- Override the original click handler to include state display update (same pattern as bottom bars)
local originalGryphonClick = button12:GetScript('OnClick')
button12:SetScript('OnClick', function(self)
    originalGryphonClick(self)
    -- Update display after a short delay
    local timer = CreateFrame("Frame")
    timer:SetScript("OnUpdate", function(self, delta)
        self.elapsed = (self.elapsed or 0) + delta
        if self.elapsed >= 0.1 then
            UpdateGryphonStyleDisplay()
            self:SetScript("OnUpdate", nil)
        end
    end)
end)

-- Function to toggle Diablo Orbs visibility
function ToggleDiabloOrbs(show)
    if show then
        -- Show custom Diablo target frame and hide default
        if _G.ShowDiabloTargetFrame then
            _G.ShowDiabloTargetFrame()
        else
            -- If function not available yet, try again after a short delay
            local delayFrame = CreateFrame("Frame")
            delayFrame:SetScript("OnUpdate", function(self, delta)
                self.elapsed = (self.elapsed or 0) + delta
                if self.elapsed >= 0.1 then
                    if _G.ShowDiabloTargetFrame then
                        _G.ShowDiabloTargetFrame()
                    end
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
        -- Show orbs - use original Show method to bypass hook if needed
        if _G.D32_HealthOrb then
            if _G.D32_HealthOrb.hookedByDrakeishUI and _G.D32_HealthOrb.originalShow then
                _G.D32_HealthOrb.originalShow(_G.D32_HealthOrb)
            else
                _G.D32_HealthOrb:Show()
            end
        end
        if _G.D32_ManaOrb then
            if _G.D32_ManaOrb.hookedByDrakeishUI and _G.D32_ManaOrb.originalShow then
                _G.D32_ManaOrb.originalShow(_G.D32_ManaOrb)
            else
                _G.D32_ManaOrb:Show()
            end
        end
        -- Only show pet orb if it's enabled and a pet exists
        -- RegisterUnitWatch will handle automatic showing/hiding when pet is summoned/dismissed
        if _G.D32_PetOrb then
            -- Check if pet orb is enabled and a pet exists before showing
            if _G.D32CharacterData and _G.D32CharacterData.petOrb and _G.D32CharacterData.petOrb.enabled then
                if UnitExists("pet") then
                    -- Pet exists, show the orb
                    if _G.D32_PetOrb.hookedByDrakeishUI and _G.D32_PetOrb.originalShow then
                        _G.D32_PetOrb.originalShow(_G.D32_PetOrb)
                    else
                        _G.D32_PetOrb:Show()
                    end
                else
                    -- No pet exists, don't show it (RegisterUnitWatch will show it automatically when pet is summoned)
                    -- Ensure RegisterUnitWatch is active so it will show when pet is summoned
                    if _G.petOrb then
                        RegisterUnitWatch(_G.petOrb)
                    end
                end
            else
                -- Pet orb is disabled, ensure it's hidden and unregistered
                if _G.D32_PetOrb then
                    _G.D32_PetOrb:Hide()
                end
                if _G.petOrb then
                    UnregisterUnitWatch(_G.petOrb)
                end
            end
        end
        -- Re-enable update scripts if they exist (healthOrb and manaOrb are global in MistrasDiabloOrbs)
        -- CRITICAL: These scripts set the font text values, which may be needed for fonts to render
        if _G.healthOrb and _G.monitorHealth then
            _G.healthOrb:SetScript("OnUpdate", _G.monitorHealth)
            -- Force an immediate update to set font text values
            _G.monitorHealth(_G.healthOrb)
        end
        if _G.manaOrb and _G.monitorPower then
            _G.manaOrb:SetScript("OnUpdate", _G.monitorPower)
            -- Force an immediate update to set font text values
            _G.monitorPower(_G.manaOrb)
        end
        -- Initialize everything like on ADDON_LOADED
        -- CRITICAL: We must ensure orb frames are visible BEFORE calling updateColorsFromMemory
        -- because fonts can't be shown if their parent is hidden
        -- Use a small delay to ensure frames are fully shown before initializing fonts
        local fontInitTimer = CreateFrame("Frame")
        fontInitTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.05 then -- Wait for one frame update cycle
                if _G.D32CharacterData and _G.healthOrb and _G.manaOrb then
                    -- Step 1: Ensure orb frames are actually visible FIRST
                    if _G.D32_HealthOrb and not _G.D32_HealthOrb:IsShown() then
                        _G.D32_HealthOrb:Show()
                    end
                    if _G.D32_ManaOrb and not _G.D32_ManaOrb:IsShown() then
                        _G.D32_ManaOrb:Show()
                    end
                    
                    -- Step 2: Call checkDefaultsFromMemory FIRST (like on ADDON_LOADED)
                    -- This ensures all defaults are set up before we try to use them
                    if _G.checkDefaultsFromMemory then
                        _G.checkDefaultsFromMemory()
                    end
                    
                    -- Step 3: Ensure fontHolder is visible (fonts are children of fontHolder)
                    if _G.healthOrb.fontHolder then
                        _G.healthOrb.fontHolder:Show()
                    end
                    if _G.manaOrb.fontHolder then
                        _G.manaOrb.fontHolder:Show()
                    end
                    
                    -- Step 4: Force fonts to be hidden first, then shown (resets their state)
                    -- This is critical because fonts might have been shown while parent was hidden
                    if _G.healthOrb.font1 then _G.healthOrb.font1:Hide() end
                    if _G.healthOrb.font2 then _G.healthOrb.font2:Hide() end
                    if _G.manaOrb.font1 then _G.manaOrb.font1:Hide() end
                    if _G.manaOrb.font2 then _G.manaOrb.font2:Hide() end
                    
                    -- Step 5: Call the full updateColorsFromMemory function (like on ADDON_LOADED)
                    -- This includes setOrbFontPlacement which properly shows/hides fonts
                    if _G.updateColorsFromMemory then
                        _G.updateColorsFromMemory()
                    end
                    
                    -- Step 5: Call UpdateOrbTextures (like on ADDON_LOADED)
                    if _G.UpdateOrbTextures then
                        _G.UpdateOrbTextures()
                    end
                    
                    -- Step 6: Call D32UpdateOrbColor like in ADDON_LOADED (after updateColorsFromMemory and UpdateOrbTextures)
                    if _G.D32UpdateOrbColor then
                        _G.D32UpdateOrbColor(_G.healthOrb, _G.D32CharacterData.healthOrb.orbColor, _G.D32CharacterData.healthOrb.galaxy, _G.D32CharacterData.healthOrb.font1, _G.D32CharacterData.healthOrb.font2)
                        if _G.D32className == "Druid" then
                            -- Druid has special handling, but we'll just update mana orb normally for now
                            -- The actual checkShapeShiftInfo would be called in the real ADDON_LOADED
                        else
                            _G.D32UpdateOrbColor(_G.manaOrb, _G.D32CharacterData.manaOrb.orbColor, _G.D32CharacterData.manaOrb.galaxy, _G.D32CharacterData.manaOrb.font1, _G.D32CharacterData.manaOrb.font2)
                        end
                    end
                    
                    
                    -- Step 7: Explicitly show fonts that should be visible (in case setOrbFontPlacement didn't work)
                    if _G.healthOrb.font1 and _G.D32CharacterData.healthOrb.font1.show then
                        _G.healthOrb.font1:Show()
                    end
                    if _G.healthOrb.font2 and _G.D32CharacterData.healthOrb.font2.show then
                        _G.healthOrb.font2:Show()
                    end
                    if _G.manaOrb.font1 and _G.D32CharacterData.manaOrb.font1.show then
                        _G.manaOrb.font1:Show()
                    end
                    if _G.manaOrb.font2 and _G.D32CharacterData.manaOrb.font2.show then
                        _G.manaOrb.font2:Show()
                    end
                end
                self:SetScript("OnUpdate", nil)
            end
        end)
        -- Restore font visibility for pet orb - replicate checkDefaultsFromMemory() pet font handling
        if _G.petOrb and _G.D32CharacterData then
            -- Hide fonts that shouldn't be shown (like in checkDefaultsFromMemory)
            if not _G.D32CharacterData.petOrb.showValue then
                if _G.petOrb.font3 then _G.petOrb.font3:Hide() end
                if _G.petOrb.font4 then _G.petOrb.font4:Hide() end
            end
            if not _G.D32CharacterData.petOrb.showPercentage then
                if _G.petOrb.font1 then _G.petOrb.font1:Hide() end
                if _G.petOrb.font2 then _G.petOrb.font2:Hide() end
            end
            -- Then call checkPetFontPlacement to show the ones that should be visible
            if _G.checkPetFontPlacement then
                _G.checkPetFontPlacement()
            end
        end
        -- When orbs are shown, re-apply gryphon/endcap artwork parenting
        if gryphon_style_state then
            ApplyGryphonStyle(gryphon_style_state)
        end
        -- Move party frames to the same position as when "Reposition Unitframes" is active
        -- This is done by temporarily setting unitframes_state to 1, updating positions, then restoring
        local saved_unitframes_state = unitframes_state
        unitframes_state = 1
        if _G.UpdatePartyFramePositions then
            _G.UpdatePartyFramePositions()
        end
        unitframes_state = saved_unitframes_state
        -- Target frame stays in its normal position when orbs are shown
        -- Hide player frame when orbs are shown
        if _G.handlePlayerFrame then
            _G.handlePlayerFrame(false)
        elseif PlayerFrame then
            PlayerFrame:SetScript("OnEvent", nil)
            PlayerFrame:Hide()
        end
    else
        -- Hide orbs
        if _G.D32_HealthOrb then _G.D32_HealthOrb:Hide() end
        if _G.D32_ManaOrb then _G.D32_ManaOrb:Hide() end
        if _G.D32_PetOrb then _G.D32_PetOrb:Hide() end
        -- Disable update scripts
        if _G.healthOrb then
            _G.healthOrb:SetScript("OnUpdate", nil)
        end
        if _G.manaOrb then
            _G.manaOrb:SetScript("OnUpdate", nil)
        end
        -- Re-apply gryphon/endcap artwork (reparents angel/demon/endcaps when orbs hide)
        if gryphon_style_state then
            ApplyGryphonStyle(gryphon_style_state)
        end
        -- Target frame stays in its normal position when orbs are hidden
        -- Restore party frames to normal position when orbs are hidden
        -- Only restore if "Reposition Unitframes" is not active
        if unitframes_state ~= 1 then
            if _G.UpdatePartyFramePositions then
                _G.UpdatePartyFramePositions()
            end
        end
        -- Show player frame when orbs are hidden
        if _G.handlePlayerFrame then
            _G.handlePlayerFrame(true)
        elseif PlayerFrame then
            if PlayerFrame_OnEvent then
                PlayerFrame:SetScript("OnEvent", PlayerFrame_OnEvent)
            end
            PlayerFrame:Show()
        end
        -- Hide custom Diablo target frame and show default
        if _G.HideDiabloTargetFrame then
            _G.HideDiabloTargetFrame()
        end
    end

    -- Push sidebars out when orbs are active; restore when deactivated
    if addon.RefreshSidebarPositions then
        addon.RefreshSidebarPositions(show and true or false)
    end
    if _G.RefreshBlizzardPetFrame then
        _G.RefreshBlizzardPetFrame()
    end
    if _G.PlacePlayerClassBars then
        _G.PlacePlayerClassBars()
    end
end

-- Diablo Orbs toggle checkbox - bottom row, under Toggle Gryphons
local button13 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle13', 'Toggle Diablo Orbs', -175, -140, function(self)
    local checked = self:GetChecked()
    
    if checked then
        -- Disable Reposition Unitframes checkbox to prevent conflicts
        if button11 then
            button11:Disable()
            button11:SetAlpha(0.5)
        end
    else
        -- Re-enable Reposition Unitframes checkbox
        if button11 then
            button11:Enable()
            button11:SetAlpha(1.0)
            -- Force the button to be clickable again
            button11:EnableMouse(true)
        end
    end
    
    diablo_orbs_state = checked and 1 or 0
    -- print("diablo_orbs_state saved as:", diablo_orbs_state) -- Debug line
    ToggleDiabloOrbs(checked)
    if UpdatePetOrbPetFrameExclusion then
        UpdatePetOrbPetFrameExclusion()
    end
end)

-- Change Orbs animation sits where Reload was. Click cycles the swirl.
local ORB_ANIMATIONS = {
    'orb_rotation_galaxy',
    'orb_rotation_bubbles',
    'orb_rotation_iris',
    'orb_rotation_new_',
    'orb_rotation_new1_',
    'orb_rotation_new2_',
    'orb_rotation_new3_',
    'orb_rotation_new4_',
    'orb_rotation_new5_',
}

local function CurrentOrbAnimation()
    local data = _G.D32CharacterData
    local rot = data and data.healthOrb and data.healthOrb.textures and data.healthOrb.textures.rotation
    for i, name in ipairs(ORB_ANIMATIONS) do
        if rot == name then return i end
    end
    return 2
end

local function ApplyOrbAnimation(index)
    local name = ORB_ANIMATIONS[index]
    if not name then return end
    local data = _G.D32CharacterData
    if data and data.healthOrb and data.healthOrb.textures then
        data.healthOrb.textures.rotation = name
    end
    if data and data.manaOrb and data.manaOrb.textures then
        data.manaOrb.textures.rotation = name
    end
    if _G.UpdateOrbTextures then
        _G.UpdateOrbTextures()
    end
end

local button21 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle21', 'Change Orbs animation', -25, -165, function()
    local index = CurrentOrbAnimation() + 1
    if index > #ORB_ANIMATIONS then index = 1 end
    ApplyOrbAnimation(index)
end)

local orbAnimationText = button21:CreateFontString(nil, 'OVERLAY')
orbAnimationText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
orbAnimationText:SetTextColor(1, 1, 0, 1)
orbAnimationText:SetPoint('CENTER', button21, 'CENTER', 0, 0)
button21:SetCheckedTexture(nil)

local function UpdateOrbAnimationDisplay()
    orbAnimationText:SetText(tostring(CurrentOrbAnimation()))
end

local originalOrbAnimationClick = button21:GetScript('OnClick')
button21:SetScript('OnClick', function(self)
    originalOrbAnimationClick(self)
    UpdateOrbAnimationDisplay()
end)
UpdateOrbAnimationDisplay()

-- Reload button, middle of the row under the nameplates
local reloadButton = CreateFrame('Button', 'DrakeishUI_ReloadButton', tooltipFrame, 'UIPanelButtonTemplate')
reloadButton:SetSize(80, 22)
reloadButton:SetPoint('TOPLEFT', tooltipTitle, 'BOTTOMLEFT', 10, -190)
reloadButton:SetFrameStrata('DIALOG')
reloadButton:SetFrameLevel(tooltipFrame:GetFrameLevel() + 20)
reloadButton:SetText('Reload')
reloadButton:Show()
reloadButton:SetScript('OnClick', function(self)
    ReloadUI()
end)

-- Add mouseover effects to match other buttons
reloadButton:SetScript('OnEnter', function(self)
    self:SetAlpha(1.0)
end)
reloadButton:SetScript('OnLeave', function(self)
    self:SetAlpha(0.8)
end)
reloadButton:SetAlpha(0.8)

-- Toggle Pet Orb checkbox - bottom row, aligned under Choose Gryphon Style
local button14 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle14', 'Toggle Pet Orb', 125, -140, function(self)
    local checked = self:GetChecked()
    
    if checked then
        -- Pet Orb on → clear / disable Toggle Pet Frame
        hide_pet_frame_state = 0
        if button17 then
            button17:SetChecked(false)
        end
        if _G.petOrb then
            RegisterUnitWatch(_G.petOrb)
            if _G.D32CharacterData then
                _G.D32CharacterData.petOrb.enabled = true
            end
        end
    else
        if _G.petOrb then
            UnregisterUnitWatch(_G.petOrb)
            _G.petOrb:Hide()
            if _G.D32CharacterData then
                _G.D32CharacterData.petOrb.enabled = false
            end
        end
    end
    if UpdatePetOrbPetFrameExclusion then
        UpdatePetOrbPetFrameExclusion()
    end
    if _G.DrakeishUI_UpdateRaidFrames then
        _G.DrakeishUI_UpdateRaidFrames()
    end
    if _G.RefreshBlizzardPetFrame then
        _G.RefreshBlizzardPetFrame()
    end
end)

-- Raid frames preference helpers.
-- darken_ui_state is an unused legacy SavedVariable already in the TOC; dual-write
-- so the preference persists even if raid_frames_state is not yet in the client's SV list.
function DrakeishUI_GetRaidFramesState()
    if raid_frames_state == 1 or darken_ui_state == 1 then
        return 1
    end
    if raid_frames_state == 0 or darken_ui_state == 0 then
        return 0
    end
    return 0
end
_G.DrakeishUI_GetRaidFramesState = DrakeishUI_GetRaidFramesState

function DrakeishUI_SetRaidFramesState(value)
    local v = (value == 1 or value == true) and 1 or 0
    raid_frames_state = v
    darken_ui_state = v
    _G.raid_frames_state = v
    _G.darken_ui_state = v
end
_G.DrakeishUI_SetRaidFramesState = DrakeishUI_SetRaidFramesState

-- raid_frame_style_state is new in the TOC, so this client will not write it
-- until a full restart. DrakeishUI_SocialDB is already saved; keep the style there.
function DrakeishUI_GetRaidFrameStyle()
    DrakeishUI_SocialDB = DrakeishUI_SocialDB or {}
    local style = tonumber(DrakeishUI_SocialDB.raidFrameStyle)
    if style ~= 1 and style ~= 2 then
        style = tonumber(raid_frame_style_state) or 1
    end
    if style ~= 2 then style = 1 end
    return style
end
_G.DrakeishUI_GetRaidFrameStyle = DrakeishUI_GetRaidFrameStyle

function DrakeishUI_SetRaidFrameStyle(style)
    style = (tonumber(style) == 2) and 2 or 1
    raid_frame_style_state = style
    _G.raid_frame_style_state = style
    DrakeishUI_SocialDB = DrakeishUI_SocialDB or {}
    DrakeishUI_SocialDB.raidFrameStyle = style
end
_G.DrakeishUI_SetRaidFrameStyle = DrakeishUI_SetRaidFrameStyle

function UpdateRaidFramesToggleAvailability()
    local btn = _G.DrakeishUI_Toggle15
    if not btn then return end

    local state = DrakeishUI_GetRaidFramesState()
    btn:SetChecked(state == 1)

    local inRaid = (GetNumRaidMembers() or 0) > 0
    if inRaid then
        btn:Enable()
        btn:SetAlpha(1.0)
        btn:EnableMouse(true)
        if btn.label then
            btn.label:SetTextColor(1, 1, 1, 1)
        end
    else
        btn:Disable()
        btn:SetAlpha(0.5)
        btn:EnableMouse(false)
        if btn.label then
            btn.label:SetTextColor(0.5, 0.5, 0.5, 1)
        end
    end
end
_G.UpdateRaidFramesToggleAvailability = UpdateRaidFramesToggleAvailability

-- New row above the last line (3 columns): Raid Frames + Placeholder + Toggle Pet Frame
local button15 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle15', 'Toggle Raid Frames', -175, -115, function(self)
    if InCombatLockdown and InCombatLockdown() then
        self:SetChecked(not self:GetChecked())
        UIErrorsFrame:AddMessage("Cannot toggle raid frames while in combat!", 1.0, 1.0, 0.0, 1.0)
        return
    end
    -- Only usable while actually in a raid
    if (GetNumRaidMembers() or 0) == 0 then
        self:SetChecked(not self:GetChecked())
        return
    end
    local checked = self:GetChecked()
    if DrakeishUI_SetRaidFramesState then
        DrakeishUI_SetRaidFramesState(checked and 1 or 0)
    else
        raid_frames_state = checked and 1 or 0
        darken_ui_state = raid_frames_state -- legacy unused SV slot (guaranteed to persist)
    end
    if _G.DrakeishUI_UpdateRaidFrames then
        _G.DrakeishUI_UpdateRaidFrames()
    end
    if _G.DrakeishUI_RefreshPartyFrames then
        _G.DrakeishUI_RefreshPartyFrames()
    end
    if UpdateRaidFramesToggleAvailability then
        UpdateRaidFramesToggleAvailability()
    end
end)
local button16 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle16', 'Choose Raid Frames', -25, -115, function(self)
    if InCombatLockdown and InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot change raid frames while in combat!", 1.0, 1.0, 0.0, 1.0)
        return
    end
    -- 1 = current frames, 2 = half height, names only, thin border
    local style = DrakeishUI_GetRaidFrameStyle() + 1
    if style > 2 then style = 1 end
    DrakeishUI_SetRaidFrameStyle(style)
    if _G.DrakeishUI_UpdateRaidFrames then
        _G.DrakeishUI_UpdateRaidFrames()
    end
end)

local raidFrameStyleText = button16:CreateFontString(nil, 'OVERLAY')
raidFrameStyleText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
raidFrameStyleText:SetTextColor(1, 1, 0, 1)
raidFrameStyleText:SetPoint('CENTER', button16, 'CENTER', 0, 0)
button16:SetCheckedTexture(nil)

local function UpdateRaidFrameStyleDisplay()
    local style = DrakeishUI_GetRaidFrameStyle()
    DrakeishUI_SetRaidFrameStyle(style)
    raidFrameStyleText:SetText(tostring(style))
end

local originalRaidStyleClick = button16:GetScript('OnClick')
button16:SetScript('OnClick', function(self)
    originalRaidStyleClick(self)
    UpdateRaidFrameStyleDisplay()
end)

local button17 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle17', 'Toggle Pet Frame', 125, -115, function(self)
    local checked = self:GetChecked()
    hide_pet_frame_state = checked and 1 or 0

    if checked then
        -- Hide standard pet frame → turn off pet orb and grey it out
        if _G.petOrb then
            UnregisterUnitWatch(_G.petOrb)
            _G.petOrb:Hide()
        end
        if _G.D32CharacterData and _G.D32CharacterData.petOrb then
            _G.D32CharacterData.petOrb.enabled = false
        end
        if button14 then
            button14:SetChecked(false)
        end
    end

    if UpdatePetOrbPetFrameExclusion then
        UpdatePetOrbPetFrameExclusion()
    end
    if _G.DrakeishUI_UpdateRaidFrames then
        _G.DrakeishUI_UpdateRaidFrames()
    end
    if _G.RefreshBlizzardPetFrame then
        _G.RefreshBlizzardPetFrame()
    end
end)

-- Enemy is Ctrl+V, friendly is Shift+V. Neutral is its own CVar when the
-- client has one; otherwise neutrals follow the enemy toggle.
-- A plain set to 1 does not create plates. The value has to change 0 -> 1.
local NAMEPLATE_CVARS = { "nameplateShowEnemies", "nameplateShowFriends", "nameplateShowNeutral" }

local function NameplateCVarExists(cvar)
    return GetCVar(cvar) ~= nil
end

local function NameplatesShown()
    local any = false
    for i = 1, #NAMEPLATE_CVARS do
        local cvar = NAMEPLATE_CVARS[i]
        if NameplateCVarExists(cvar) then
            any = true
            if GetCVar(cvar) ~= "1" then
                return false
            end
        end
    end
    return any
end

local function SyncNameplatesCheckbox()
    local box = _G.DrakeishUI_Toggle18
    if box then
        box:SetChecked(NameplatesShown())
    end
end

local function PulseNameplateCVar(cvar, shown)
    if not NameplateCVarExists(cvar) then
        return
    end
    if not shown then
        SetCVar(cvar, 0)
        return
    end
    SetCVar(cvar, 0)
    SetCVar(cvar, abs(GetCVar(cvar) - 1))
end

local function ApplyNameplateCVars(shown)
    for i = 1, #NAMEPLATE_CVARS do
        PulseNameplateCVar(NAMEPLATE_CVARS[i], shown)
    end
end

local function SetNameplatesShown(shown)
    if tooltipFrame then
        tooltipFrame:SetScript("OnUpdate", nil)
    end
    ApplyNameplateCVars(shown)
    if not shown or not tooltipFrame then
        return
    end
    -- Apply again next frame. The client drops the enable if it lands in the
    -- same update as the disable.
    tooltipFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        ApplyNameplateCVars(true)
    end)
end

-- 1 = selected unit only, 2 = that layout on every unit, 3 = Blizzard plates.
local NAMEPLATE_MODE_MAX = 3

local function DrakeishUI_GetNameplateMode()
    DrakeishUI_SocialDB = DrakeishUI_SocialDB or {}
    local mode = tonumber(DrakeishUI_SocialDB.nameplateMode) or 1
    if mode < 1 or mode > NAMEPLATE_MODE_MAX then
        mode = 1
    end
    return mode
end

local function DrakeishUI_SetNameplateMode(mode)
    mode = tonumber(mode) or 1
    if mode < 1 or mode > NAMEPLATE_MODE_MAX then
        mode = 1
    end
    DrakeishUI_SocialDB = DrakeishUI_SocialDB or {}
    DrakeishUI_SocialDB.nameplateMode = mode
    _G.DrakeishUI_NameplateMode = mode
    if _G.KuiNameplates and _G.KuiNameplates.ApplyDrakeishNameplateMode then
        _G.KuiNameplates:ApplyDrakeishNameplateMode()
    end
end

_G.DrakeishUI_GetNameplateMode = DrakeishUI_GetNameplateMode
_G.DrakeishUI_SetNameplateMode = DrakeishUI_SetNameplateMode

local button19

local function MinimapRotationEnabled()
    return GetCVar("rotateMinimap") == "1"
end

local function HideStockNorthTag()
    if MinimapNorthTag then
        MinimapNorthTag:Hide()
        MinimapNorthTag:SetAlpha(0)
    end
end

local function SyncRotateMinimapCheckbox()
    button19:SetChecked(MinimapRotationEnabled())
end

local function ApplyMinimapRotation(enabled)
    SetCVar("rotateMinimap", enabled and "1" or "0")
    if type(Minimap_UpdateRotationSetting) == "function" then
        Minimap_UpdateRotationSetting()
    end
    HideStockNorthTag()
    local blizz = _G.InterfaceOptionsDisplayPanelRotateMinimap
    if blizz then
        blizz:SetChecked(enabled and true or false)
    end
    SyncRotateMinimapCheckbox()
end

local function HookBlizzardRotateMinimap()
    if type(Minimap_UpdateRotationSetting) == "function" and not _G.DrakeishUI_RotateMinimapWrapped then
        local original = Minimap_UpdateRotationSetting
        Minimap_UpdateRotationSetting = function(...)
            original(...)
            HideStockNorthTag()
        end
        _G.DrakeishUI_RotateMinimapWrapped = true
    end
    local blizz = _G.InterfaceOptionsDisplayPanelRotateMinimap
    if not blizz or blizz._drakeishRotateHook then
        return
    end
    blizz._drakeishRotateHook = true
    blizz:HookScript("OnClick", function()
        SyncRotateMinimapCheckbox()
    end)
end

local button18 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle18', 'Show Nameplates', -175, -165, function(self)
    SetNameplatesShown(self:GetChecked())
end)
button19 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle19', 'Rotate minimap', -25, -140, function(self)
    ApplyMinimapRotation(self:GetChecked())
end)
HookBlizzardRotateMinimap()
local button20 = CreateCheckbox(tooltipFrame, 'DrakeishUI_Toggle20', 'Choose nameplates', 125, -165, function()
    local mode = DrakeishUI_GetNameplateMode() + 1
    if mode > NAMEPLATE_MODE_MAX then
        mode = 1
    end
    DrakeishUI_SetNameplateMode(mode)
end)

local nameplateModeText = button20:CreateFontString(nil, 'OVERLAY')
nameplateModeText:SetFont('Fonts\\FRIZQT__.TTF', 10, 'OUTLINE')
nameplateModeText:SetTextColor(1, 1, 0, 1)
nameplateModeText:SetPoint('CENTER', button20, 'CENTER', 0, 0)
button20:SetCheckedTexture(nil)

local function UpdateNameplateModeDisplay()
    local mode = DrakeishUI_GetNameplateMode()
    DrakeishUI_SetNameplateMode(mode)
    nameplateModeText:SetText(tostring(mode))
end

local originalNameplateModeClick = button20:GetScript('OnClick')
button20:SetScript('OnClick', function(self)
    originalNameplateModeClick(self)
    UpdateNameplateModeDisplay()
end)

-- Mutual exclusion: Pet Orb <-> Toggle Pet Frame (grey out the other)
function UpdatePetOrbPetFrameExclusion()
    local petOrbBtn = button14 or _G.DrakeishUI_Toggle14
    local petFrameBtn = button17 or _G.DrakeishUI_Toggle17
    if not petOrbBtn or not petFrameBtn then return end

    local orbsActive = (diablo_orbs_state == 1)
    local petOrbOn = orbsActive
        and _G.D32CharacterData
        and _G.D32CharacterData.petOrb
        and _G.D32CharacterData.petOrb.enabled
    local hidePet = (hide_pet_frame_state or 0) == 1

    -- Pet Frame checkbox
    if petOrbOn then
        petFrameBtn:SetChecked(false)
        hide_pet_frame_state = 0
        petFrameBtn:Disable()
        petFrameBtn:SetAlpha(0.5)
        petFrameBtn:EnableMouse(false)
    else
        petFrameBtn:Enable()
        petFrameBtn:SetAlpha(1.0)
        petFrameBtn:EnableMouse(true)
        petFrameBtn:SetChecked(hidePet)
    end

    -- Pet Orb checkbox (also requires Diablo Orbs)
    if hidePet or not orbsActive then
        petOrbBtn:Disable()
        petOrbBtn:SetAlpha(0.5)
        petOrbBtn:EnableMouse(false)
        if hidePet then
            petOrbBtn:SetChecked(false)
        end
    else
        petOrbBtn:Enable()
        petOrbBtn:SetAlpha(1.0)
        petOrbBtn:EnableMouse(true)
    end
end
_G.UpdatePetOrbPetFrameExclusion = UpdatePetOrbPetFrameExclusion

-- Apply initial raid-toggle availability (greyed when not in a raid)
if UpdateRaidFramesToggleAvailability then
    UpdateRaidFramesToggleAvailability()
end

-- Keep raid checkbox enabled/greyed in sync with roster
local raidToggleEventFrame = CreateFrame("Frame")
raidToggleEventFrame:RegisterEvent("PLAYER_LOGIN")
raidToggleEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
raidToggleEventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
raidToggleEventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
raidToggleEventFrame:SetScript("OnEvent", function()
    if UpdateRaidFramesToggleAvailability then
        UpdateRaidFramesToggleAvailability()
    end
end)

-- Store buttons in table
toggleButtons = {button1, button2, button3, button4, button5, button6, button7, button8, button9, button10, button11, button13, button15, button16, button17, button18, button19, button20, button21}

-- Main button click handler
mainToggleButton:SetScript('OnClick', function(self)
    if tooltipFrame:IsShown() then
        tooltipFrame:Hide()
        SetMainToggleState('normal')
    else
        SyncNameplatesCheckbox()
        SyncRotateMinimapCheckbox()
        UpdateNameplateModeDisplay()
        UpdateOrbAnimationDisplay()
        tooltipFrame:Show()
        SetMainToggleState('pushed')
    end
end)

-- Mouseover effects for main button
mainToggleButton:SetScript('OnEnter', function(self)
    self:SetAlpha(1.0)
    -- Show tooltip
    GameTooltip:SetOwner(self, 'ANCHOR_TOP')
    GameTooltip:SetText('DrakeishUI', 1, 1, 1, 1, true)
    GameTooltip:Show()
end)

mainToggleButton:SetScript('OnLeave', function(self)
    self:SetAlpha(0.7)
    -- Hide tooltip
    GameTooltip:Hide()
end)

-- Hide tooltip when clicking outside
local function HideTooltipOnClick()
    if tooltipFrame:IsShown() then
        tooltipFrame:Hide()
        SetMainToggleState('normal')
    end
end

-- Register for clicks on UIParent to hide tooltip
UIParent:SetScript('OnMouseDown', HideTooltipOnClick)

-- Escape key handling is now managed by UISpecialFrames - no custom code needed

-- Hook into tooltip show/hide events
tooltipFrame:HookScript('OnShow', function()
    SetMainToggleState('pushed')
end)
tooltipFrame:HookScript('OnHide', function()
    SetMainToggleState('normal')
end)

-- Make tooltip movable but don't capture keyboard events
tooltipFrame:SetMovable(true)
tooltipFrame:EnableMouse(true)
tooltipFrame:EnableKeyboard(false)  -- Don't capture keyboard events to allow character movement
tooltipFrame:RegisterForDrag('LeftButton')

tooltipFrame:SetScript('OnDragStart', function(self)
    self:StartMoving()
end)

tooltipFrame:SetScript('OnDragStop', function(self)
    self:StopMovingOrSizing()
end)

-- Set initial alpha for main button
mainToggleButton:SetAlpha(0.7)

-- Ensure main button is in proper initial state after reload
ApplyMainToggleAtlas()

-- Initialize button states on login
local initFrame = CreateFrame('Frame')
initFrame:RegisterEvent('PLAYER_LOGIN')
initFrame:SetScript('OnEvent', function(self, event)
    -- Reset main button to normal state after reload
    ApplyMainToggleAtlas()

    -- Ensure tooltip is hidden on login
    tooltipFrame:Hide()
    
    -- Set initial states based on current visibility
    -- Always use the saved state variables for consistency
    if not party_state then party_state = 0 end
    button1:SetChecked(party_state == 1)
    
    if not chat_state then chat_state = 0 end
    button2:SetChecked(chat_state == 1)
    
    if _G.stancetoggle then
        button3:SetChecked(not _G.stancetoggle:GetChecked()) -- Invert the logic
    else
        button3:SetChecked(false) -- Stance bars should be visible by default
    end
    -- Always use the saved state variable for consistency
    -- caps_state = 1 means gryphons visible, caps_state = 0 means gryphons hidden
    if not caps_state then caps_state = 1 end  -- Default to visible (1) when no variables saved
    button4:SetChecked(caps_state == 1) -- When caps_state = 1 (visible), checkbox should be checked
    -- Initialize Diablo Orbs state
    if not diablo_orbs_state then diablo_orbs_state = 0 end
    button13:SetChecked(diablo_orbs_state == 1)
    -- Initialize bottom bars state display
    if not bottombars_state then bottombars_state = 0 end
    UpdateBottomBarsDisplay()
    -- Always use the saved state variable for consistency
    if not sidebars_state then sidebars_state = 0 end
    button6:SetChecked(sidebars_state == 1)
    -- Always use the saved state variable for consistency
    if not bags_state then bags_state = 0 end
    button7:SetChecked(bags_state == 1)
    -- Always use the saved state variable for consistency
    if not quest_state then quest_state = 0 end
    button8:SetChecked(quest_state == 1)
    
    -- Initialize buff frame state (inverted display logic: visible = unchecked, hidden = checked)
    if not buffs_state then 
        buffs_state = 1  -- Default to visible (1) when no variables saved
    end
    
    -- Inverted display logic: when buffs_state = 1 (visible), checkbox should be unchecked (false)
    -- when buffs_state = 0 (hidden), checkbox should be checked (true)
    button9:SetChecked(buffs_state == 0)
    
    -- Apply the initial state to the buff frames
    if buffs_state == 1 then
        BuffFrame:Show()
        TemporaryEnchantFrame:Show()
    else
        BuffFrame:Hide()
        TemporaryEnchantFrame:Hide()
    end
    
    -- Initialize hide toggle buttons state
    if not hide_toggle_buttons then hide_toggle_buttons = 0 end
    button10:SetChecked(hide_toggle_buttons == 1)
    
    -- Initialize unitframe toggle state
    if not unitframes_state then unitframes_state = 0 end
    button11:SetChecked(unitframes_state == 1)
    
    SyncNameplatesCheckbox()
    HookBlizzardRotateMinimap()
    SyncRotateMinimapCheckbox()
    UpdateNameplateModeDisplay()
    UpdateOrbAnimationDisplay()

    -- Initialize Toggle Pet Frame / Pet Orb row
    if not hide_pet_frame_state then hide_pet_frame_state = 0 end
    if button17 then
        button17:SetChecked(hide_pet_frame_state == 1)
    end

    -- Initialize Toggle Raid Frames
    DrakeishUI_SetRaidFramesState(DrakeishUI_GetRaidFramesState())
    if UpdateRaidFramesToggleAvailability then
        UpdateRaidFramesToggleAvailability()
    end
    if _G.DrakeishUI_UpdateRaidFrames then
        _G.DrakeishUI_UpdateRaidFrames()
    end

    -- Initialize Toggle Pet Orb state
    if button14 then
        if _G.D32CharacterData and _G.D32CharacterData.petOrb then
            button14:SetChecked(_G.D32CharacterData.petOrb.enabled == true)
            -- Apply pet orb state
            if _G.petOrb then
                if _G.D32CharacterData.petOrb.enabled and hide_pet_frame_state ~= 1 then
                    RegisterUnitWatch(_G.petOrb)
                else
                    UnregisterUnitWatch(_G.petOrb)
                    _G.petOrb:Hide()
                    if hide_pet_frame_state == 1 then
                        _G.D32CharacterData.petOrb.enabled = false
                        button14:SetChecked(false)
                    end
                end
            end
        else
            -- Default to checked if D32CharacterData not available yet
            button14:SetChecked(true)
        end
    end

    if UpdatePetOrbPetFrameExclusion then
        UpdatePetOrbPetFrameExclusion()
    end
    if _G.RefreshBlizzardPetFrame then
        _G.RefreshBlizzardPetFrame()
    end
    
    -- Handle mutual exclusion between Reposition Unitframes and Diablo Orbs
    if unitframes_state == 1 and button13 then
        -- Disable Diablo Orbs if Reposition Unitframes is active
        button13:Disable()
        button13:SetAlpha(0.5)
    elseif diablo_orbs_state == 1 and button11 then
        -- Disable Reposition Unitframes if Diablo Orbs is active
        button11:Disable()
        button11:SetAlpha(0.5)
    end
    
    -- Store original positions on first login (before any modifications)
    if not originalPositions.player then
        StoreOriginalPositions()
    end
    
    -- Apply unitframe positions if they were previously moved
    if unitframes_state == 1 then
        -- Move to DragonflightUI positions
        MoveToDragonflightPositions()
        
        -- Move party frames up to avoid overlap
        if _G.UpdatePartyFramePositions then
            _G.UpdatePartyFramePositions()
        end
    end
    
    -- Hook into PLAYER_ENTERING_WORLD to re-apply our positions after DragonflightUI
    local unitframeOverrideFrame = CreateFrame("Frame")
    unitframeOverrideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    unitframeOverrideFrame:SetScript("OnEvent", function(self, event)
        if unitframes_state == 1 then
            -- Re-apply our positions after DragonflightUI has finished
            local timer = CreateFrame("Frame")
            timer:SetScript("OnUpdate", function(self, delta)
                self.elapsed = (self.elapsed or 0) + delta
                if self.elapsed >= 1.0 then -- Wait 1 second for DragonflightUI to finish
                    MoveToDragonflightPositions()
                    if _G.UpdatePartyFramePositions then
                        _G.UpdatePartyFramePositions()
                    end
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    end)
    
    -- Update button position based on initial micromenu state
    UpdateButtonPosition()
    
    -- Keep panel checkboxes in sync when on-screen toggle arrows are used
    local function SyncToggleCheckboxes()
        if button1 then button1:SetChecked((party_state or 0) == 1) end
        if button2 then button2:SetChecked((chat_state or 0) == 1) end
        if button3 then
            -- Panel checked = stance bars hidden (inverted vs stancetoggle)
            if _G.stancetoggle then
                button3:SetChecked(not _G.stancetoggle:GetChecked())
            else
                button3:SetChecked((stance_state or 1) == 0)
            end
        end
        if button4 then button4:SetChecked((caps_state or 1) == 1) end
        if button5 and UpdateBottomBarsDisplay then UpdateBottomBarsDisplay() end
        if button6 then button6:SetChecked((sidebars_state or 0) == 1) end
        if button7 then button7:SetChecked((bags_state or 0) == 1) end
        if button8 then button8:SetChecked((quest_state or 0) == 1) end
        -- Buff checkbox is inverted: checked = hidden
        if button9 then button9:SetChecked((buffs_state or 1) == 0) end
        if button15 then
            if UpdateRaidFramesToggleAvailability then
                UpdateRaidFramesToggleAvailability()
            else
                button15:SetChecked(DrakeishUI_GetRaidFramesState() == 1)
            end
        end
        if button17 then button17:SetChecked((hide_pet_frame_state or 0) == 1) end
    end

    local function HookUIToggleSync(toggleName, afterClick)
        local toggle = _G[toggleName]
        if not toggle or toggle.drakeishCheckboxSynced then return end
        toggle.drakeishCheckboxSynced = true
        local original = toggle:GetScript('OnClick')
        toggle:SetScript('OnClick', function(self, ...)
            if original then original(self, ...) end
            SyncToggleCheckboxes()
            if afterClick then afterClick(self) end
        end)
    end

    HookUIToggleSync('partytoggle')
    HookUIToggleSync('chattoggle')
    HookUIToggleSync('stancetoggle')
    HookUIToggleSync('gryphontoggle')
    HookUIToggleSync('bottombarstoggle')
    HookUIToggleSync('sidebarstoggle')
    HookUIToggleSync('bagstoggle', function()
        UpdateButtonPosition()
    end)
    HookUIToggleSync('watchframetoggle')
    HookUIToggleSync('buffstoggle')
    
    -- Apply the saved state on login
    if hide_toggle_buttons == 1 then
        -- Hide all main toggle buttons
        if _G.partytoggle then _G.partytoggle:Hide() end
        if _G.chattoggle then _G.chattoggle:Hide() end
        if _G.DrakeishUI_ChatViewToggle then _G.DrakeishUI_ChatViewToggle:Hide() end
        if _G.stancetoggle then _G.stancetoggle:Hide() end
        if _G.gryphontoggle then _G.gryphontoggle:Hide() end
        if _G.bottombarstoggle then _G.bottombarstoggle:Hide() end
        if _G.sidebarstoggle then _G.sidebarstoggle:Hide() end
        if _G.bagstoggle then _G.bagstoggle:Hide() end
        if _G.watchframetoggle then _G.watchframetoggle:Hide() end
        if _G.buffstoggle then _G.buffstoggle:Hide() end
        if _G.maintoggle then _G.maintoggle:Hide() end
        if _G.pUiArrowManager then _G.pUiArrowManager:Hide() end
    else
        -- Show all main toggle buttons
        if _G.partytoggle then _G.partytoggle:Show() end
        if _G.chattoggle then _G.chattoggle:Show() end
        if _G.DrakeishUI_ChatViewToggle then _G.DrakeishUI_ChatViewToggle:Show() end
        if _G.stancetoggle then _G.stancetoggle:Show() end
        if _G.gryphontoggle then _G.gryphontoggle:Show() end
        if _G.bottombarstoggle then _G.bottombarstoggle:Show() end
        if _G.sidebarstoggle then _G.sidebarstoggle:Show() end
        if _G.bagstoggle then _G.bagstoggle:Show() end
        if _G.watchframetoggle then _G.watchframetoggle:Show() end
        if _G.buffstoggle then _G.buffstoggle:Show() end
        if _G.maintoggle then _G.maintoggle:Show() end
        if _G.pUiArrowManager then _G.pUiArrowManager:Show() end
    end
end)

-- Function to immediately hide orbs if they should be hidden (called before timer)
local function HideOrbsImmediatelyIfNeeded()
    if not diablo_orbs_state then diablo_orbs_state = 0 end
    if diablo_orbs_state == 0 then
        -- Hide immediately if state says they should be hidden
        if _G.D32_HealthOrb then _G.D32_HealthOrb:Hide() end
        if _G.D32_ManaOrb then _G.D32_ManaOrb:Hide() end
        if _G.D32_PetOrb then _G.D32_PetOrb:Hide() end
        if _G.healthOrb then
            _G.healthOrb:SetScript("OnUpdate", nil)
        end
        if _G.manaOrb then
            _G.manaOrb:SetScript("OnUpdate", nil)
        end
        return true -- Return true if we hid them
    end
    return false
end

-- Hook into orb Show methods to prevent showing if they should be hidden
local function HookOrbShowMethods()
    if _G.D32_HealthOrb and not _G.D32_HealthOrb.hookedByDrakeishUI then
        local originalShow = _G.D32_HealthOrb.Show
        _G.D32_HealthOrb.originalShow = originalShow -- Store for bypass
        _G.D32_HealthOrb.Show = function(self, ...)
            if not diablo_orbs_state or diablo_orbs_state == 0 then
                return -- Don't show if state says hidden
            end
            originalShow(self, ...)
        end
        _G.D32_HealthOrb.hookedByDrakeishUI = true
    end
    if _G.D32_ManaOrb and not _G.D32_ManaOrb.hookedByDrakeishUI then
        local originalShow = _G.D32_ManaOrb.Show
        _G.D32_ManaOrb.originalShow = originalShow -- Store for bypass
        _G.D32_ManaOrb.Show = function(self, ...)
            if not diablo_orbs_state or diablo_orbs_state == 0 then
                return -- Don't show if state says hidden
            end
            originalShow(self, ...)
        end
        _G.D32_ManaOrb.hookedByDrakeishUI = true
    end
    if _G.D32_PetOrb and not _G.D32_PetOrb.hookedByDrakeishUI then
        local originalShow = _G.D32_PetOrb.Show
        _G.D32_PetOrb.originalShow = originalShow -- Store for bypass
        _G.D32_PetOrb.Show = function(self, ...)
            if not diablo_orbs_state or diablo_orbs_state == 0 then
                return -- Don't show if state says hidden
            end
            originalShow(self, ...)
        end
        _G.D32_PetOrb.hookedByDrakeishUI = true
    end
end

-- Hook into orb creation to hide immediately if needed
local orbHideFrame = CreateFrame("Frame")
orbHideFrame:RegisterEvent("ADDON_LOADED")
orbHideFrame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == "DrakeishUI" or arg1 == "MistrasDiabloOrbs" then
        -- Try to hide immediately, then keep checking
        local checkTimer = CreateFrame("Frame")
        local checkCount = 0
        checkTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.01 then -- Check every 0.01 seconds
                checkCount = checkCount + 1
                HookOrbShowMethods() -- Hook Show methods to prevent showing
                HideOrbsImmediatelyIfNeeded() -- Hide if visible
                -- Stop checking after 1 second (100 checks) or if orbs are found and handled
                if checkCount >= 100 or (_G.D32_HealthOrb and diablo_orbs_state == 0 and not _G.D32_HealthOrb:IsShown()) then
                    self:SetScript("OnUpdate", nil)
                end
                self.elapsed = 0
            end
        end)
    end
end)

-- Add PLAYER_LOGIN event to restore gryphon style state (same pattern as bottombarstoggle.lua)
local gryphonRestoreFrame = CreateFrame('Frame')
gryphonRestoreFrame:RegisterEvent('PLAYER_LOGIN')
gryphonRestoreFrame:RegisterEvent('ADDON_LOADED')
gryphonRestoreFrame:SetScript('OnEvent', function(self, event, arg1)
    if event == 'ADDON_LOADED' and arg1 == 'DrakeishUI' then
        -- Wait a bit for MistrasDiabloOrbs to initialize
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.5 then
                if not gryphon_style_state then gryphon_style_state = 1 end
                ApplyGryphonStyle(gryphon_style_state)
                UpdateGryphonStyleDisplay()
                UpdateRaidFrameStyleDisplay()
                
                -- Restore Diablo Orbs state
                if not diablo_orbs_state then diablo_orbs_state = 0 end
                if button13 then
                    button13:SetChecked(diablo_orbs_state == 1)
                end
                ToggleDiabloOrbs(diablo_orbs_state == 1)

                -- Restore Toggle Pet Frame
                if not hide_pet_frame_state then hide_pet_frame_state = 0 end
                if button17 then
                    button17:SetChecked(hide_pet_frame_state == 1)
                end

                -- Restore Toggle Raid Frames and the chosen frame style
                DrakeishUI_SetRaidFramesState(DrakeishUI_GetRaidFramesState())
                DrakeishUI_SetRaidFrameStyle(DrakeishUI_GetRaidFrameStyle())
                UpdateRaidFrameStyleDisplay()
                if UpdateRaidFramesToggleAvailability then
                    UpdateRaidFramesToggleAvailability()
                end
                if _G.DrakeishUI_UpdateRaidFrames then
                    _G.DrakeishUI_UpdateRaidFrames()
                end
                
                -- Restore Toggle Pet Orb state
                if button14 then
                    if _G.D32CharacterData and _G.D32CharacterData.petOrb then
                        if hide_pet_frame_state == 1 then
                            _G.D32CharacterData.petOrb.enabled = false
                        end
                        button14:SetChecked(_G.D32CharacterData.petOrb.enabled == true)
                        if _G.petOrb then
                            if _G.D32CharacterData.petOrb.enabled then
                                RegisterUnitWatch(_G.petOrb)
                            else
                                UnregisterUnitWatch(_G.petOrb)
                                _G.petOrb:Hide()
                            end
                        end
                    else
                        button14:SetChecked(hide_pet_frame_state ~= 1)
                    end
                end

                if UpdatePetOrbPetFrameExclusion then
                    UpdatePetOrbPetFrameExclusion()
                end
                if _G.RefreshBlizzardPetFrame then
                    _G.RefreshBlizzardPetFrame()
                end
                
                self:SetScript("OnUpdate", nil)
            end
        end)
    elseif event == 'PLAYER_LOGIN' then
        self:UnregisterEvent(event)
        if not gryphon_style_state then gryphon_style_state = 1 end
        
        -- Apply the restored state immediately
        ApplyGryphonStyle(gryphon_style_state)
        UpdateGryphonStyleDisplay()
        UpdateRaidFrameStyleDisplay()
        
        -- Restore Diablo Orbs state
        if not diablo_orbs_state then diablo_orbs_state = 0 end
        if button13 then
            button13:SetChecked(diablo_orbs_state == 1)
        end
        -- Hide immediately if needed, then wait for full initialization
        HideOrbsImmediatelyIfNeeded()
        -- Wait a bit for orbs to be fully initialized before showing
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.5 then
                ToggleDiabloOrbs(diablo_orbs_state == 1)
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        -- Restore Toggle Pet Frame / Pet Orb mutual exclusion
        if not hide_pet_frame_state then hide_pet_frame_state = 0 end
        if button17 then
            button17:SetChecked(hide_pet_frame_state == 1)
        end
        if button14 then
            if _G.D32CharacterData and _G.D32CharacterData.petOrb then
                if hide_pet_frame_state == 1 then
                    _G.D32CharacterData.petOrb.enabled = false
                end
                button14:SetChecked(_G.D32CharacterData.petOrb.enabled == true)
                if _G.petOrb then
                    if _G.D32CharacterData.petOrb.enabled then
                        RegisterUnitWatch(_G.petOrb)
                    else
                        UnregisterUnitWatch(_G.petOrb)
                        _G.petOrb:Hide()
                    end
                end
            else
                button14:SetChecked(hide_pet_frame_state ~= 1)
            end
        end
        if UpdatePetOrbPetFrameExclusion then
            UpdatePetOrbPetFrameExclusion()
        end
        if _G.RefreshBlizzardPetFrame then
            _G.RefreshBlizzardPetFrame()
        end
    end
end)

-- Add PLAYER_ENTERING_WORLD event to reapply gryphon style after reloads
local worldFrame = CreateFrame('Frame')
worldFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
worldFrame:SetScript('OnEvent', function(self, event)
    -- Reapply gryphon style after world loads
    if gryphon_style_state then
        ApplyGryphonStyle(gryphon_style_state)
    end
end)
