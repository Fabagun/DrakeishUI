
local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


-- MINIMAP ----------------------------------------
---------------------------------------------------

MinimapCluster:SetScale(1.1)
MiniMapWorldMapButton:Hide()
MinimapZoneTextButton:Hide() -- Hide default zone text above minimap
MinimapZoneText:Hide()
MinimapBorderTop:Hide()
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
GameTimeFrame:Hide()
MiniMapTrackingButton:Hide()
MiniMapTracking:Hide()
-- CustomRacialRadialButton:Hide() -- heritage horizons

-- Enable mouse wheel zoom on the minimap
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)

-- Enable right-click to open tracking menu
Minimap:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, Minimap, 0, 0)
    end
end)

-- Replace default textures
MinimapBorder:Hide()
MinimapNorthTag:Hide()
MinimapNorthTag:SetAlpha(0)

-- Create a new custom border texture
local customBorder = Minimap:CreateTexture(nil, "OVERLAY")
customBorder:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uiminimapborder.blp")
customBorder:SetPoint("CENTER", Minimap, "CENTER", 0, 1)
customBorder:SetSize(160, 160)

-- Move minimap to desired position
Minimap:ClearAllPoints()
Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -30)

-- Unified display: Zone | Time | Coords | FPS
local infoFrame = CreateFrame("Frame", "UnifiedInfoFrame", UIParent)
infoFrame:SetSize(600, 20)

-- Function to set the anchor point safely
local function SetInfoFrameAnchor()
    if _G.MinimalChatAnchor and _G.MinimalChatAnchor:IsShown() then
        -- Link to chatAnchor if it exists and is shown
        infoFrame:SetPoint("BOTTOMLEFT", _G.MinimalChatAnchor, "BOTTOMLEFT", -12, -20)
    else
        -- Fallback to ChatFrame1 if chatAnchor is not available
        infoFrame:SetPoint("BOTTOMLEFT", ChatFrame1, "BOTTOMLEFT", -12, -20)
    end
end

-- Set initial anchor
SetInfoFrameAnchor()

-- Update anchor when chatAnchor becomes available
local function CheckChatAnchor()
    if _G.MinimalChatAnchor then
        SetInfoFrameAnchor()
        -- Hook the chatAnchor's show/hide events to update positioning
        _G.MinimalChatAnchor:HookScript("OnShow", SetInfoFrameAnchor)
        _G.MinimalChatAnchor:HookScript("OnHide", SetInfoFrameAnchor)
    else
        -- Keep checking until chatAnchor is available using WoTLK-compatible timer
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.1 then
                CheckChatAnchor()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- Start checking for chatAnchor
CheckChatAnchor()

-- Helper to create label + value text elements
local function CreateInfoText(parent, labelText)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    label:SetTextColor(1, 1, 1) -- white
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 0.7)
    label:SetText(labelText)

    local value = parent:CreateFontString(nil, "OVERLAY")
    value:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    value:SetTextColor(1, 0.85, 0) -- yellow
    value:SetShadowOffset(1, -1)
    value:SetShadowColor(0, 0, 0, 0.7)
    value:SetText("")

    return label, value
end

-- Create label-value pairs for zone, time, coords, and FPS
local zoneLabel, zoneValue = CreateInfoText(infoFrame, "Zone:")
local timeLabel, timeValue = CreateInfoText(infoFrame, "Time:")
local coordLabel, coordValue = CreateInfoText(infoFrame, "Coords:")
local fpsLabel, fpsValue = CreateInfoText(infoFrame, "FPS:")

-- Positioning label-value pairs in a row
zoneLabel:SetPoint("LEFT", infoFrame, "LEFT", 15, 0)
zoneValue:SetPoint("LEFT", zoneLabel, "RIGHT", 0, 0)

timeLabel:SetPoint("LEFT", zoneValue, "RIGHT", 4, 0)
timeValue:SetPoint("LEFT", timeLabel, "RIGHT", 0, 0)

coordLabel:SetPoint("LEFT", timeValue, "RIGHT", 4, 0)
coordValue:SetPoint("LEFT", coordLabel, "RIGHT", 0, 0)

fpsLabel:SetPoint("LEFT", coordValue, "RIGHT", 10, 0)
fpsValue:SetPoint("LEFT", fpsLabel, "RIGHT", 0, 0)

-- PvP Zone Type to color mapping
local zoneColors = {
    ["friendly"] = {r = 0.1, g = 1.0, b = 0.1},
    ["hostile"] = {r = 1.0, g = 0.1, b = 0.1},
    ["contested"] = {r = 1.0, g = 0.7, b = 0.0},
    ["sanctuary"] = {r = 0.4, g = 0.8, b = 0.94},
    ["arena"] = {r = 1.0, g = 0.1, b = 0.1},
    ["combat"] = {r = 1.0, g = 0.1, b = 0.1},
    ["neutral"] = {r = 1.0, g = 1.0, b = 1.0},
}

-- Update data every second
local updater = CreateFrame("Frame", nil, infoFrame)
local elapsed = 0
updater:SetScript("OnUpdate", function(self, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        -- Update zone
        local zoneName = GetRealZoneText()
        local pvpType = GetZonePVPInfo() or "neutral"
        local color = zoneColors[string.lower(pvpType)] or zoneColors["neutral"]
        zoneValue:SetText(zoneName)
        zoneValue:SetTextColor(color.r, color.g, color.b)

        -- Update time
        local hour, minute = GetGameTime()
        timeValue:SetText(string.format("%02d:%02d", hour, minute))

        -- Update coordinates
        if not WorldMapFrame:IsShown() or not WorldMapFrame:IsMinimized() then
        SetMapToCurrentZone()
        end
        local x, y = GetPlayerMapPosition("player")
        if x and y and (x > 0 or y > 0) then
            coordValue:SetText(string.format("%.1f, %.1f", x * 100, y * 100))
        else
            coordValue:SetText("--, --")
        end

        -- Update FPS
        local fps = GetFramerate()
        fpsValue:SetText(string.format("%.1f", fps))

        elapsed = 0
    end
end)

-- Hide default clock on login
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    if TimeManagerClockButton then
        TimeManagerClockButton:Hide()
        TimeManagerClockButton.Show = function() end
    end

    if MinimapZoneText then
        MinimapZoneText:Hide()
        MinimapZoneText.Show = function() end
    end
end)

-- ===========================
-- Mail Button Movement
-- ===========================

-- Function to make mail button movable
local function MakeMailButtonMovable()
    -- Wait for mail button to be created
    local mailFrame = CreateFrame("Frame")
    mailFrame:RegisterEvent("ADDON_LOADED")
    mailFrame:RegisterEvent("PLAYER_LOGIN")
    mailFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "Blizzard_Mail" then
            self:UnregisterEvent("ADDON_LOADED")
        end
        
        -- Check for mail button
        local mailButton = MiniMapMailFrame or MiniMapMailButton
        if mailButton and not mailButton.isDrakeishUIMovable then
            -- Hide all default frames and textures
            mailButton:Hide()
            
            -- Hide related mail elements
            if MiniMapMailIcon then MiniMapMailIcon:Hide() end
            if MiniMapMailBorder then MiniMapMailBorder:Hide() end
            if MiniMapMailFrame then MiniMapMailFrame:Hide() end
            
            -- Create custom mail button
            local customMailButton = CreateFrame("Button", "DrakeishUIMailButton", UIParent)
            customMailButton:SetSize(16, 16)
            customMailButton:SetFrameStrata("HIGH")
            customMailButton:SetFrameLevel(10)
            
            -- Set custom texture
            local mailTexture = customMailButton:CreateTexture(nil, "OVERLAY")
            mailTexture:SetAllPoints()
            mailTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uiminimapmail.blp")
            
            -- Position the custom button
            customMailButton:ClearAllPoints()
            customMailButton:SetPoint("TOP", Minimap, "TOP", 71, 10)
            
            -- Make it movable
            customMailButton:SetMovable(true)
            customMailButton:EnableMouse(true)
            customMailButton:RegisterForDrag("LeftButton")
            
            -- Add drag functionality
            customMailButton:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            
            customMailButton:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                -- Save position
                local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
                -- You can save this to saved variables if needed
            end)
            
            -- Set mail button to be 50% transparent by default, 100% visible on hover
            customMailButton:SetAlpha(0.5)
            
            -- Add visual feedback on mouseover
            customMailButton:SetScript("OnEnter", function(self)
                self:SetAlpha(1.0)
            end)
            
            customMailButton:SetScript("OnLeave", function(self)
                self:SetAlpha(0.5)
            end)
            
            -- Copy mail functionality from original button
            customMailButton:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    -- Open mail
                    if MiniMapMailFrame and MiniMapMailFrame:IsShown() then
                        MiniMapMailFrame:Hide()
                    else
                        ToggleFrame(MailFrame)
                    end
                end
            end)
            
            -- Show/hide based on mail status
            local function UpdateMailButton()
                if HasNewMail() then
                    customMailButton:Show()
                else
                    customMailButton:Hide()
                end
            end
            
            -- Register for mail events
            customMailButton:RegisterEvent("UPDATE_PENDING_MAIL")
            customMailButton:RegisterEvent("MAIL_INBOX_UPDATE")
            customMailButton:RegisterEvent("MAIL_SHOW")
            customMailButton:RegisterEvent("MAIL_CLOSED")
            customMailButton:SetScript("OnEvent", UpdateMailButton)
            
            -- Initial update
            UpdateMailButton()
            
            -- Mark as processed
            mailButton.isDrakeishUIMovable = true
            
            -- Unregister events once done
            if event == "PLAYER_LOGIN" then
                self:UnregisterEvent("PLAYER_LOGIN")
            end
        end
    end)
end

-- Initialize mail button movement
MakeMailButtonMovable()

-- ===========================
-- Toggle Button for Labels
-- ==========================

-- -- Create minimal toggle button function
-- local function CreateMinimalToggleButton(name, parent, size, anchorTo, anchorPoint, xOffset, yOffset)
--     local button = CreateFrame("Button", name, UIParent) -- Use UIParent for proper layering
--     button:SetSize(size, size)
--     button:SetFrameStrata("HIGH")
--     button:SetAlpha(0.3)
-- 
--     -- Create horizontal texture instead of text - using uicollapsebuttonh.tga for up/down arrows
--     button.texture = button:CreateTexture(nil, "OVERLAY")
--     button.texture:SetSize(16, 16)
--     button.texture:SetPoint("CENTER", button, "CENTER", 0, 0)
--     button.texture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebutton.tga")
--     button.texture:SetTexCoord(0, 1, 0, 0.5)  -- Top half initially (left arrow - info is visible)
-- 
--     -- Position relative to parent label
--     button:SetPoint(anchorPoint or "LEFT", anchorTo or UIParent, anchorPoint or "LEFT", xOffset or 0, yOffset or 0)
-- 
--     return button
-- end
-- 
-- -- Create the toggle button
-- local chatToggleButton = CreateMinimalToggleButton("ChatToggle", zoneLabel, 24, zoneLabel, "LEFT", -24, 0)
-- 
-- -- Mouseover alpha effect, no tooltip
-- chatToggleButton:SetScript("OnEnter", function(self)
--     self:SetAlpha(1.0)
-- end)
-- chatToggleButton:SetScript("OnLeave", function(self)
--     self:SetAlpha(0.3)
-- end)
-- 
-- -- Toggle visibility of the labels and values
-- chatToggleButton:SetScript("OnClick", function(self)
--     if zoneLabel:IsShown() then
--         zoneLabel:Hide()
--         zoneValue:Hide()
--         timeLabel:Hide()
--         timeValue:Hide()
--         coordLabel:Hide()
--         coordValue:Hide()
--         fpsLabel:Hide()
--         fpsValue:Hide()
--         self.texture:SetTexCoord(0, 1, 0.5, 1)  -- Bottom half of texture (right arrow - info is hidden)
--     else
--         zoneLabel:Show()
--         zoneValue:Show()
--         timeLabel:Show()
--         timeValue:Show()
--         coordLabel:Show()
--         coordValue:Show()
--         fpsLabel:Show()
--         fpsValue:Show()
--         self.texture:SetTexCoord(0, 1, 0, 0.5)  -- Top half of texture (left arrow - info is visible)
--     end
-- end)
