-- OutOfRangeSquare.lua
-- Simple addon: draws a red square overlay on action buttons when the action is out of range.

local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


local UPDATE_INTERVAL = 0.20  -- seconds between checks

local f = CreateFrame("Frame")
f.elapsed = 0
f.buttons = {}

-- Create overlay on a given button if not already present
local function EnsureOverlay(btn)
    if not btn or not btn:IsObjectType("Button") then return end
    if btn.__rangeOverlayCreated then return end
	
	

    local sq = btn:CreateTexture(nil, "ARTWORK")
    -- small white texture recolored to red
    sq:SetTexture("Interface\\Buttons\\WHITE8x8")
    sq:SetVertexColor(1, 0, 0, 0.7)          -- red, 60% alpha
    sq:SetSize(37, 37)                       -- size to match button texture (37x37 pixels)
    sq:SetPoint("CENTER", btn, "CENTER", 0, 0)  -- center the overlay on the button
    sq:SetDrawLayer("ARTWORK", 0)           -- place above button texture but under border
    
    -- BLEND MODE OPTIONS (choose one):
    -- sq:SetBlendMode("ADD")                -- additive blend (brightens)
    -- sq:SetBlendMode("DISABLE")           -- no blending
    sq:SetBlendMode("MOD")               -- modulation blend
    -- sq:SetBlendMode("BLEND")             -- normal alpha blending (default)
    
    -- COLOR MANIPULATION OPTIONS:
    -- sq:SetVertexColor(1, 0, 0, 0.8)      -- solid red with high alpha
    -- sq:SetVertexColor(0.8, 0.2, 0.2, 0.6) -- darker red for multiply effect
    -- sq:SetVertexColor(1, 0.3, 0.3, 0.4)  -- lighter red with lower alpha
    
    sq:Hide()

    btn.__rangeOverlay = sq
	btn.__rangeOverlayCreated = true

end

-- Try to collect standard action buttons present in the default UI.
-- We attempt a reasonably-large range to catch mainbar, multi-bars, etc.
local function GatherActionButtons()
    wipe(f.buttons)
    for i = 1, 120 do
        local name = "ActionButton"..i
        local btn = _G[name]
        if btn and btn:IsObjectType("Button") then
            EnsureOverlay(btn)
            tinsert(f.buttons, btn)
        end
    end

    -- also try common bar button names (others may exist on some UIs)
    local extraNames = {
        "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton"
    }
    for _, base in ipairs(extraNames) do
        for i = 1, 12 do
            local btn = _G[base..i]
            if btn and btn:IsObjectType("Button") then
                EnsureOverlay(btn)
                tinsert(f.buttons, btn)
            end
        end
    end
end

-- Update a single button's overlay depending on range
local function UpdateButtonRange(btn)
    if not btn or not btn.__rangeOverlay then return end

    -- many default ActionButtons have an `action` numeric field
    local action = btn.action
    if not action then
        -- some custom buttons may hold action via GetActionInfo when secure templates used;
        -- try to infer using GetActionInfo from the button's action slot if possible
        -- (if not available, hide overlay)
        btn.__rangeOverlay:Hide()
        return
    end

    -- no target -> hide overlay
    if not UnitExists("target") then
        btn.__rangeOverlay:Hide()
        return
    end

    local inRange = IsActionInRange(action)
    -- IsActionInRange returns:
    -- 1 if in range, 0 if out of range, nil if action has no range check (e.g. macro/item without range)
    if inRange == 0 then
        btn.__rangeOverlay:Show()
    else
        btn.__rangeOverlay:Hide()
    end
end

-- Throttled OnUpdate to refresh range overlays
f:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < UPDATE_INTERVAL then return end
    self.elapsed = 0

    -- update all collected buttons
    for _, btn in ipairs(self.buttons) do
        UpdateButtonRange(btn)
    end
end)

-- Events: gather buttons on login and re-check when target or actionbar changes
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")      -- fired when an action changes in a slot
f:RegisterEvent("PLAYER_TARGET_CHANGED")       -- new target -> re-check
f:RegisterEvent("UNIT_AURA")                   -- in case buffs change range-affecting states (optional)
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")       -- helpful for when spells become usable/unusable

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        GatherActionButtons()

        -- initial pass
        for _, btn in ipairs(self.buttons) do
            UpdateButtonRange(btn)
        end
        return
    end

    -- for slot changes or target change, do a quick immediate update of all buttons
    if event == "ACTIONBAR_SLOT_CHANGED" or event == "PLAYER_TARGET_CHANGED"
       or event == "SPELL_UPDATE_COOLDOWN" or event == "UNIT_AURA" then
        for _, btn in ipairs(self.buttons) do
            UpdateButtonRange(btn)
        end
    end
end)
