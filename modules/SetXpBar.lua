-- Function to set the XP rate
local function SetXpRate(rate)
    -- Sends a chat message to mod-individual-xp to set the XP rate
    SendChatMessage(".xp " .. rate, "SAY")
end

-- List of XP rates with corresponding functions
local xpRates = {
    { text = "Experience:", isTitle = true },
    { text = "x0.5", func = function() SetXpRate(0.5) end },
    { text = "x1 (Blizzlike)", func = function() SetXpRate(1) end },
    { text = "x3", func = function() SetXpRate(3) end },
    { text = "x5", func = function() SetXpRate(5) end },
    { text = "x7", func = function() SetXpRate(7) end },
    { text = "x10", func = function() SetXpRate(10) end },
    { text = "Custom", func = function() StaticPopup_Show("SET_XP_RATE") end }, -- Open custom XP rate dialog
}

-- Function to initialize the dropdown menu
local function InitializeMenu(self, level)
    if not level then return end
    for _, rate in pairs(xpRates) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = rate.text
        info.func = rate.func
        info.isTitle = rate.isTitle
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Create the dropdown menu frame
local xpBarMenu = CreateFrame("Frame", "SetXpBarMenu", UIParent, "UIDropDownMenuTemplate")
xpBarMenu.initialize = InitializeMenu

-- Function to enable mouse interaction with the XP bar
local function EnableXpBarMenuInteraction(bar)
    local function OnExperienceBarClick(self, button)
        if button == "RightButton" then
            EasyMenu(xpRates, xpBarMenu, "cursor", 3, -3, "MENU")
        end
    end

    bar:EnableMouse(true)
    bar:SetScript("OnMouseDown", OnExperienceBarClick)
end

-- Hook into ElvUI's initialization to enable interaction with the XP bar
local function HookElvUI()
    local E = unpack(ElvUI)
    local mod = E:GetModule("DataBars")

    -- Add a custom function to be called when the experience bar is initialized
    hooksecurefunc(mod, "ExperienceBar_Load", function()
        EnableXpBarMenuInteraction(mod.expBar)
    end)
end

-- Enable interaction with the default UI XP bar
local function EnableDefaultUiXpBarMenuInteraction()
    -- EnableXpBarMenuInteraction(CharacterFrameTab1)
	EnableXpBarMenuInteraction(MainMenuExpBar)
end

-- Register the custom XP rate popup dialog
StaticPopupDialogs["SET_XP_RATE"] = {
    text = "Enter custom XP rate:",
    button1 = "Set Rate",
    button2 = "Cancel",
    hasEditBox = true, -- Dialog has an edit box for user input
    -- Function to execute when the "Set Rate" button is clicked
    OnAccept = function(self)
        local rate = self.editBox:GetText()
        SetXpRate(rate)
    end,
    timeout = 0,
    whileDead = true, -- Dialog persists even when other windows are open
    hideOnEscape = true, -- Dialog closes when the escape key is pressed
    preferredIndex = 3, -- Index to avoid taint from UIParent
}

-- Ensure ElvUI is loaded before hooking into it
if IsAddOnLoaded("ElvUI") then
    HookElvUI()
else
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, addon)
        if addon == "ElvUI" then
            HookElvUI()
            self:UnregisterEvent("ADDON_LOADED")
        elseif addon == "Blizzard_UI" then
            EnableDefaultUiXpBarMenuInteraction()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

-- Ensure the default UI is handled even if ElvUI is not present
if not IsAddOnLoaded("ElvUI") then
    EnableDefaultUiXpBarMenuInteraction()
end
