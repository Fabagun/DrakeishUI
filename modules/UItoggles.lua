local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;

-- Main toggle button to the left of CharacterMicroButton
local mainToggleButton = CreateFrame('Button', 'DrakeishUI_MainToggle', UIParent)
mainToggleButton:SetSize(28, 26) -- Reduced by 20% again (35 * 0.8 = 28)
mainToggleButton:SetPoint('RIGHT', CharacterMicroButton, 'LEFT', 2, 1.5)
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
        -- Move to HelpMicroButton position when micromenu is hidden
        mainToggleButton:ClearAllPoints()
        mainToggleButton:SetPoint('BOTTOMRIGHT', HelpMicroButton, 'BOTTOMRIGHT', 0, 0)
        -- Enable mouseover when micromenu is hidden
        enableMouseOver(mainToggleButton, true)
    else
        -- Move to original position when micromenu is visible
        mainToggleButton:ClearAllPoints()
        mainToggleButton:SetPoint('RIGHT', CharacterMicroButton, 'LEFT', 2, 1.5)
        -- Disable mouseover when micromenu is visible
        enableMouseOver(mainToggleButton, false)
    end
end

-- Button texture
mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
mainToggleButton:SetPushedTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-pushed.blp')
mainToggleButton:SetHighlightTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-highlight3.blp')

local normal = mainToggleButton:GetNormalTexture()
normal:SetAllPoints()
normal:SetTexCoord(0, 1, 0, 1) -- Full texture (1:1 coordinates)
-- Brighten the normal texture to reduce faded appearance
-- normal:SetVertexColor(2, 2, 2) -- Brighten by 20%

local pushed = mainToggleButton:GetPushedTexture()
pushed:SetAllPoints()
pushed:SetTexCoord(0, 1, 0, 1) -- Full texture (1:1 coordinates)

local highlight = mainToggleButton:GetHighlightTexture()
highlight:SetAllPoints()
highlight:SetTexCoord(0, 1, 0, 1) -- Full texture (1:1 coordinates)
highlight:SetAlpha(0.6)
-- highlight:SetVertexColor(0.7,0.7,0.7)
highlight:SetBlendMode('BLEND')

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
tooltipFrame:SetHeight(180) -- Reduced from 190 to 180 (-10 pixels)
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
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, -5)
titleText:SetText("DrakeishUI Settings")
titleText:SetTextColor(1, 0.82, 0) -- Blizzard's standard yellow color

-- Close button
local closeButton = CreateFrame("Button", "DrakeishUI_ToggleClose", tooltipFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", tooltipFrame, "TOPRIGHT", 2, 2)
closeButton:SetScript("OnClick", function() 
    tooltipFrame:Hide() 
end)

-- Use the titleText from title bar as reference for positioning
local tooltipTitle = titleText

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
        if checked then
            ChatFrame1:Hide()
            ChatFrame1EditBox:Hide()
            if _G.UnifiedInfoFrame then
                _G.UnifiedInfoFrame:Hide()
            end
            chat_state = 1
        else
            ChatFrame1:Show()
            ChatFrame1EditBox:Show()
            if _G.UnifiedInfoFrame then
                _G.UnifiedInfoFrame:Show()
            end
            chat_state = 0
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
    else
        -- Fallback to simple micromenu toggle
        local checked = self:GetChecked()
        if checked then
            MainMenuBarArtFrame:Hide()
        else
            MainMenuBarArtFrame:Show()
        end
    end
    -- Update button position after micromenu toggle
    local timer = CreateFrame("Frame")
    timer:SetScript("OnUpdate", function(self, delta)
        self.elapsed = (self.elapsed or 0) + delta
        if self.elapsed >= 0.1 then
            UpdateButtonPosition()
            self:SetScript("OnUpdate", nil)
        end
    end)
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
                if BuffFrame:IsShown() then
                    button9:SetChecked(false)  -- Visible = unchecked (inverted display)
                    buffs_state = 1
                else
                    button9:SetChecked(true)   -- Hidden = checked (inverted display)
                    buffs_state = 0
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
    
    -- Target castbar: below target frame
    if TargetFrameSpellBar then
        TargetFrameSpellBar:ClearAllPoints()
        TargetFrameSpellBar:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 0, -10)
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
local function ApplyGryphonStyle(style)
    if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return end
    if caps_state == 0 then
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
        return
    end
        if style == 1 then -- old
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -85, -22)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif style == 2 then -- new
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif style == 3 then -- flying
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
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
    -- Cycle through states: 1=old, 2=new, 3=flying
    gryphon_style_state = (gryphon_style_state or 1) + 1
    if gryphon_style_state > 3 then
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

-- Reload button positioned in middle column under Quest Frame
local reloadButton = CreateFrame('Button', 'DrakeishUI_ReloadButton', tooltipFrame, 'UIPanelButtonTemplate')
reloadButton:SetSize(80, 22)
reloadButton:SetPoint('TOPLEFT', tooltipTitle, 'BOTTOMLEFT', 10, -120)
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

-- Store buttons in table
toggleButtons = {button1, button2, button3, button4, button5, button6, button7, button8, button9, button10, button11}

-- Main button click handler
mainToggleButton:SetScript('OnClick', function(self)
    if tooltipFrame:IsShown() then
        tooltipFrame:Hide()
        -- Change to closed state (normal texture)
        normal:SetTexCoord(0, 1, 0, 1)
        pushed:SetTexCoord(0, 1, 0, 1)
        highlight:SetTexCoord(0, 1, 0, 1)
        -- Restore normal texture when window is closed
        mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
    else
        tooltipFrame:Show()
        -- Change to open state (pushed texture)
        normal:SetTexCoord(0, 1, 0, 1)
        pushed:SetTexCoord(0, 1, 0, 1)
        highlight:SetTexCoord(0, 1, 0, 1)
        -- Force the pushed texture to be visible when window is open
        mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-pushed.blp')
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
        -- Change to closed state (normal texture)
        local normal = mainToggleButton:GetNormalTexture()
        local pushed = mainToggleButton:GetPushedTexture()
        local highlight = mainToggleButton:GetHighlightTexture()
        
        normal:SetTexCoord(0, 1, 0, 1)
        pushed:SetTexCoord(0, 1, 0, 1)
        highlight:SetTexCoord(0, 1, 0, 1)
        -- Restore normal texture when window is closed
        mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
    end
end

-- Register for clicks on UIParent to hide tooltip
UIParent:SetScript('OnMouseDown', HideTooltipOnClick)

-- Escape key handling is now managed by UISpecialFrames - no custom code needed

-- Hook into tooltip show/hide events
tooltipFrame:HookScript('OnShow', function()
    -- Set pushed texture when tooltip is shown
    mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-pushed.blp')
end)
tooltipFrame:HookScript('OnHide', function()
    -- Reset to normal texture when tooltip is hidden
    mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
    local normal = mainToggleButton:GetNormalTexture()
    local pushed = mainToggleButton:GetPushedTexture()
    local highlight = mainToggleButton:GetHighlightTexture()
    
    normal:SetTexCoord(0, 1, 0, 1)
    pushed:SetTexCoord(0, 1, 0, 1)
    highlight:SetTexCoord(0, 1, 0, 1)
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
mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
mainToggleButton:SetPushedTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-pushed.blp')
mainToggleButton:SetHighlightTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI-highlight3.blp')

-- Reset texture coordinates to normal state
local normal = mainToggleButton:GetNormalTexture()
local pushed = mainToggleButton:GetPushedTexture()
local highlight = mainToggleButton:GetHighlightTexture()

normal:SetTexCoord(0, 1, 0, 1)
pushed:SetTexCoord(0, 1, 0, 1)
highlight:SetTexCoord(0, 1, 0, 1)

-- Ensure highlight texture is properly configured
highlight:SetAlpha(0.6)
highlight:SetBlendMode('BLEND')

-- Initialize button states on login
local initFrame = CreateFrame('Frame')
initFrame:RegisterEvent('PLAYER_LOGIN')
initFrame:SetScript('OnEvent', function(self, event)
    -- Reset main button to normal state after reload
    mainToggleButton:SetNormalTexture('Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUI3.blp')
    local normal = mainToggleButton:GetNormalTexture()
    local pushed = mainToggleButton:GetPushedTexture()
    local highlight = mainToggleButton:GetHighlightTexture()
    
    normal:SetTexCoord(0, 1, 0, 1)
    pushed:SetTexCoord(0, 1, 0, 1)
    highlight:SetTexCoord(0, 1, 0, 1)
    
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
    -- Always use the saved state variable for consistency (invert the logic)
    if not caps_state then caps_state = 0 end
    button4:SetChecked(caps_state == 0) -- Invert: when caps_state = 0 (visible), checkbox should be unchecked
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
        -- Check if buff frames are currently visible to set initial state
        if BuffFrame:IsShown() then
            buffs_state = 1  -- Visible = unchecked (inverted display)
        else
            buffs_state = 0  -- Hidden = checked (inverted display)
        end
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
    
    -- Apply the saved state on login
    if hide_toggle_buttons == 1 then
        -- Hide all main toggle buttons
        if _G.partytoggle then _G.partytoggle:Hide() end
        if _G.chattoggle then _G.chattoggle:Hide() end
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

-- Add PLAYER_LOGIN event to restore gryphon style state (same pattern as bottombarstoggle.lua)
local gryphonRestoreFrame = CreateFrame('Frame')
gryphonRestoreFrame:RegisterEvent('PLAYER_LOGIN')
gryphonRestoreFrame:SetScript('OnEvent', function(self, event)
    self:UnregisterEvent(event)
    if not gryphon_style_state then gryphon_style_state = 1 end
    
    -- Apply the restored state immediately
    ApplyGryphonStyle(gryphon_style_state)
    UpdateGryphonStyleDisplay()
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
