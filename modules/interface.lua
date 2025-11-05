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

-- Function to disable and grey out checkboxes
local function DisableActionBarCheckboxes()
    -- First, try the predefined list
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
    
    -- Second, dynamically search for checkboxes in the Action Bars panel
    local actionBarsPanel = _G["InterfaceOptionsActionBarsPanel"]
    if actionBarsPanel then
        -- Search through all children recursively
        local function ProcessFrame(frame)
            if frame and frame:GetObjectType() == "CheckButton" then
                local frameName = frame:GetName()
                -- Debug: Print all checkbox names to help identify the correct ones
                if frameName then
                    -- print("Found checkbox:", frameName)
                end
                
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
                    -- print("Disabling checkbox:", frameName)
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
                    ProcessFrame(child)
                end
            end
        end
        
        ProcessFrame(actionBarsPanel)
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
        -- Wait a bit for interface options to load
        CreateTimer(2, function()
            DisableActionBarCheckboxes()
            AddExplanatoryText()
        end)
    elseif event == "ADDON_LOADED" and addonName == "DrakeishUI" then
        -- Also try when DrakeishUI loads
        CreateTimer(3, function()
            DisableActionBarCheckboxes()
            AddExplanatoryText()
        end)
    end
end)

-- Hook into Interface Options frame to ensure it works when opened
local function HookInterfaceOptions()
    local interfaceOptionsFrame = _G["InterfaceOptionsFrame"]
    if interfaceOptionsFrame then
        interfaceOptionsFrame:HookScript("OnShow", function()
            CreateTimer(0.1, function()
                DisableActionBarCheckboxes()
                AddExplanatoryText()
            end)
        end)
    end
end

-- Initialize the hook
CreateTimer(5, HookInterfaceOptions)
