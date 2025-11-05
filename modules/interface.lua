--[[
    DrakeishUI Interface Module
    Greys out action bar checkboxes in Interface/Actionbars menu
    since DrakeishUI now manages the main action bars
]]--

local addon = select(2,...);
local _G = _G;

-- Action bar checkboxes to disable - comprehensive list for WoTLK 3.3.5a
local actionBarCheckboxes = {
    -- Main action bar options
    "InterfaceOptionsActionBarsPanelAlwaysShowActionBars",
    "InterfaceOptionsActionBarsPanelLockActionBars", 
    "InterfaceOptionsActionBarsPanelPickupActionKeyDropDown",
    "InterfaceOptionsActionBarsPanelPickupActionKeyDropDownButton",
    
    -- MultiBar options (these might have different names in WoTLK)
    "InterfaceOptionsActionBarsPanelRightTwoActionBars",
    "InterfaceOptionsActionBarsPanelRightTwoActionBarsButton",
    "InterfaceOptionsActionBarsPanelBottomLeftActionBar",
    "InterfaceOptionsActionBarsPanelBottomLeftActionBarButton",
    "InterfaceOptionsActionBarsPanelBottomRightActionBar", 
    "InterfaceOptionsActionBarsPanelBottomRightActionBarButton",
    "InterfaceOptionsActionBarsPanelRightActionBars",
    "InterfaceOptionsActionBarsPanelRightActionBarsButton",
    "InterfaceOptionsActionBarsPanelLeftActionBars",
    "InterfaceOptionsActionBarsPanelLeftActionBarsButton",
    
    -- Alternative names that might exist in WoTLK
    "InterfaceOptionsActionBarsPanelMultiBarRight",
    "InterfaceOptionsActionBarsPanelMultiBarRightButton",
    "InterfaceOptionsActionBarsPanelMultiBarLeft", 
    "InterfaceOptionsActionBarsPanelMultiBarLeftButton",
    "InterfaceOptionsActionBarsPanelMultiBarBottomLeft",
    "InterfaceOptionsActionBarsPanelMultiBarBottomLeftButton",
    "InterfaceOptionsActionBarsPanelMultiBarBottomRight",
    "InterfaceOptionsActionBarsPanelMultiBarBottomRightButton",
    
    -- Additional possible names
    "InterfaceOptionsActionBarsPanelShowActionBar1",
    "InterfaceOptionsActionBarsPanelShowActionBar2", 
    "InterfaceOptionsActionBarsPanelShowActionBar3",
    "InterfaceOptionsActionBarsPanelShowActionBar4",
    "InterfaceOptionsActionBarsPanelShowActionBar5",
    "InterfaceOptionsActionBarsPanelShowActionBar6"
}

-- Action bars list
local actionBars = {
    "ActionBar1",
    "MultiBarBottomLeft",
    "MultiBarBottomRight", 
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7"
}

-- Function to ensure all action bars are visible
local function ShowAllActionBars()
    for _, barName in ipairs(actionBars) do
        local bar = _G[barName]
        if bar then
            bar:Show()
        end
    end
end

-- Function to show all action bars and check checkboxes, then disable them
local function DisableActionBarCheckboxes()
    -- First, show all action bars
    ShowAllActionBars()
    
    -- Second, check all checkboxes in the predefined list
    for _, checkboxName in ipairs(actionBarCheckboxes) do
        local checkbox = _G[checkboxName]
        if checkbox then
            -- Set checkbox to checked
            checkbox:SetChecked(true)
        end
    end
    
    -- Third, disable and grey out the checkboxes
    for _, checkboxName in ipairs(actionBarCheckboxes) do
        local checkbox = _G[checkboxName]
        if checkbox then
            checkbox:Disable()
            checkbox:SetAlpha(0.5) -- Grey out the checkbox
            
            -- Also disable the text label if it exists
            local text = checkbox:GetFontString()
            if text then
                text:SetTextColor(0.5, 0.5, 0.5) -- Grey text
            end
            
            -- Disable tooltip functionality
            checkbox:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine("Action Bar Management", 1, 1, 1)
                GameTooltip:AddLine(" - managed by DrakeishUI", 1, 0.7, 0)
                GameTooltip:Show()
            end)
        end
    end
    
    -- Fourth, dynamically search for checkboxes in the Action Bars panel and check them first
    local actionBarsPanel = _G["InterfaceOptionsActionBarsPanel"]
    if actionBarsPanel then
        -- First pass: check all action bar checkboxes
        local function CheckCheckboxes(frame)
            if frame and frame:GetObjectType() == "CheckButton" then
                local frameName = frame:GetName()
                
                -- Check if this looks like an action bar checkbox
                if frameName and (
                    frameName:find("ActionBar") or 
                    frameName:find("MultiBar") or
                    frameName:find("AlwaysShow") or
                    frameName:find("LockAction") or
                    frameName:find("Right") or
                    frameName:find("Left") or
                    frameName:find("Bottom")
                ) then
                    frame:SetChecked(true)
                end
            end
            
            -- Process children
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                if child then
                    CheckCheckboxes(child)
                end
            end
        end
        
        -- Second pass: disable and grey out checkboxes
        local function DisableCheckboxes(frame)
            if frame and frame:GetObjectType() == "CheckButton" then
                local frameName = frame:GetName()
                
                -- Check if this looks like an action bar checkbox
                if frameName and (
                    frameName:find("ActionBar") or 
                    frameName:find("MultiBar") or
                    frameName:find("AlwaysShow") or
                    frameName:find("LockAction") or
                    frameName:find("Right") or
                    frameName:find("Left") or
                    frameName:find("Bottom")
                ) then
                    frame:Disable()
                    frame:SetAlpha(0.5)
                    
                    local text = frame:GetFontString()
                    if text then
                        text:SetTextColor(0.5, 0.5, 0.5)
                    end
                    
                    frame:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_TOP")
                        GameTooltip:AddLine("Action Bar Management", 1, 1, 1)
                        GameTooltip:AddLine(" - managed by DrakeishUI", 1, 0.7, 0)
                        GameTooltip:Show()
                    end)
                end
            end
            
            -- Process children
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                if child then
                    DisableCheckboxes(child)
                end
            end
        end
        
        -- Execute both passes
        CheckCheckboxes(actionBarsPanel)
        DisableCheckboxes(actionBarsPanel)
    end
end

-- Function to add explanatory text
local function AddExplanatoryText()
    -- Find the action bars panel
    local actionBarsPanel = _G["InterfaceOptionsActionBarsPanel"]
    if not actionBarsPanel then return end
    
    -- Create explanatory text
    local explanationText = actionBarsPanel:CreateFontString("DrakeishUI_ActionBarExplanation", "OVERLAY", "GameFontHighlightSmall")
    explanationText:SetPoint("TOPLEFT", actionBarsPanel, "TOPLEFT", 90, -16)
    explanationText:SetText(" -  managed by DrakeishUI")
    explanationText:SetTextColor(1, 0.7, 0) -- Orange color
    explanationText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE") -- Explicit font size 12 with outline
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")

-- Timer function for WoTLK compatibility
local function CreateTimer(delay, callback)
    local timer = CreateFrame("Frame")
    timer:SetScript("OnUpdate", function(self, elapsed)
        self.timeLeft = (self.timeLeft or delay) - elapsed
        if self.timeLeft <= 0 then
            callback()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" then
        -- Show all action bars immediately
        ShowAllActionBars()
        -- Wait a bit for interface options to load
        CreateTimer(2, function()
            DisableActionBarCheckboxes()
            AddExplanatoryText()
        end)
    elseif event == "ADDON_LOADED" and addonName == "DrakeishUI" then
        -- Show all action bars
        ShowAllActionBars()
        -- Also try when DrakeishUI loads
        CreateTimer(3, function()
            DisableActionBarCheckboxes()
            AddExplanatoryText()
        end)
    elseif event == "UPDATE_BINDINGS" then
        -- Ensure action bars stay visible after binding updates
        ShowAllActionBars()
    end
end)

-- Flag to track when Interface Options is closing
local interfaceOptionsClosing = false

-- Hook action bar Hide methods to prevent hiding when Interface Options closes
local function HookActionBarHides()
    for _, barName in ipairs(actionBars) do
        local bar = _G[barName]
        if bar and bar.Hide then
            local originalHide = bar.Hide
            bar.Hide = function(self)
                -- If Interface Options is closing, prevent hiding the bar
                if interfaceOptionsClosing then
                    return
                end
                -- Otherwise, allow normal hiding
                return originalHide(self)
            end
        end
    end
end

-- Hook into Interface Options frame to ensure it works when opened and closed
local function HookInterfaceOptions()
    local interfaceOptionsFrame = _G["InterfaceOptionsFrame"]
    if interfaceOptionsFrame then
        -- When Interface Options opens, disable checkboxes
        interfaceOptionsFrame:HookScript("OnShow", function()
            CreateTimer(0.1, function()
                DisableActionBarCheckboxes()
                AddExplanatoryText()
            end)
        end)
        
        -- Hook the close button to set flag and show action bars immediately
        local closeButton = _G["InterfaceOptionsFrameCloseButton"]
        if closeButton then
            closeButton:HookScript("OnClick", function()
                interfaceOptionsClosing = true
                ShowAllActionBars()
                -- Reset flag after a short delay
                CreateTimer(0.5, function()
                    interfaceOptionsClosing = false
                end)
            end)
        end
        
        -- When Interface Options closes, set flag and show action bars immediately
        interfaceOptionsFrame:HookScript("OnHide", function()
            interfaceOptionsClosing = true
            ShowAllActionBars()
            -- Reset flag after a short delay
            CreateTimer(0.5, function()
                interfaceOptionsClosing = false
            end)
        end)
        
        -- Hook the Hide function to set flag and show bars before frame actually hides
        if interfaceOptionsFrame.Hide then
            local originalHide = interfaceOptionsFrame.Hide
            interfaceOptionsFrame.Hide = function(self)
                interfaceOptionsClosing = true
                ShowAllActionBars()
                local result = originalHide(self)
                -- Reset flag after a short delay
                CreateTimer(0.5, function()
                    interfaceOptionsClosing = false
                end)
                return result
            end
        end
    end
end

-- Initialize the hooks
CreateTimer(5, function()
    HookActionBarHides()
    HookInterfaceOptions()
end)
