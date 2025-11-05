local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


local CUSTOM_BORDER_PATH = "Interface\\AddOns\\DrakeishUI\\assets\\uiactionbariconframe.tga"
local BORDER_SCALE = 1.1


local function StyleAuraIcon(button)
    if not button or button.styled then return end
    local width = button:GetWidth() * BORDER_SCALE
    local height = button:GetHeight() * BORDER_SCALE
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(CUSTOM_BORDER_PATH)
    border:SetSize(width, height)
    border:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.border = border
    button.styled = true
end

-- Hook Blizzard buff/debuff update functions to style buttons with your border
hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    for i = 1, BUFF_ACTUAL_DISPLAY do
        local buff = _G["BuffButton"..i]
		local te = _G["TempEnchant"..i]
        StyleAuraIcon(buff)
		StyleAuraIcon(te)
    end
end)

hooksecurefunc("DebuffButton_UpdateAnchors", function()
    for i = 1, 16 do
        local debuff = _G["DebuffButton"..i]
        StyleAuraIcon(debuff)
    end
end)

local function AdjustBuffTimers()
    for i = 1, BUFF_ACTUAL_DISPLAY do
        local buff = _G["BuffButton"..i]
		local te = _G["TempEnchant"..i]
        if buff and buff.duration then
            buff.duration:ClearAllPoints()
            buff.duration:SetPoint("BOTTOM", buff, "BOTTOM", 0, -14)
        end
		if te and te.duration then
            te.duration:ClearAllPoints()
            te.duration:SetPoint("BOTTOM", te, "BOTTOM", 0, -14)
        end
    end

    for i = 1, 16 do
        local debuff = _G["DebuffButton"..i]
        if debuff and debuff.duration then
            debuff.duration:ClearAllPoints()
            debuff.duration:SetPoint("BOTTOM", debuff, "BOTTOM", 0, -14)
        end
    end
end

local OFFSET_X = -20 -- move left by 10 pixels

local function ShiftBuffsLeft()
    -- Collect all visible buffs and temp enchants in order
    local visibleAuras = {}
    
    -- First, add visible temporary enchants (they appear first in WoW)
    for i = 1, 3 do -- TempEnchant1, TempEnchant2, TempEnchant3 (mainhand, offhand, ranged)
        local te = _G["TempEnchant"..i]
        if te and te:IsShown() then
            table.insert(visibleAuras, te)
        end
    end
    
    -- Then add visible buff buttons
    for i = 1, BUFF_ACTUAL_DISPLAY do
        local buff = _G["BuffButton"..i]
        if buff and buff:IsShown() then
            table.insert(visibleAuras, buff)
        end
    end
    
    -- Position all visible auras in a grid (10 per row)
    local numRows = 0
    for index, aura in ipairs(visibleAuras) do
        aura:ClearAllPoints()
        if index == 1 then
            -- First aura: anchor to BuffFrame
            aura:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", OFFSET_X, 0)
            numRows = 1
        elseif (index - 1) % 10 == 0 then
            -- First aura of a new row: anchor below the aura 10 buttons before
            aura:SetPoint("TOPRIGHT", visibleAuras[index - 10], "BOTTOMRIGHT", 0, -18)
            numRows = numRows + 1
        else
            -- Other auras: anchor to left of previous aura
            aura:SetPoint("RIGHT", visibleAuras[index - 1], "LEFT", -5, 0)
        end
    end

    -- Calculate dynamic debuff position based on number of buff rows
    -- Each buff row is ~32 pixels tall + spacing
    local debuffYOffset = -60 -- Default offset for 0 or 1 row of buffs (gives ~28 pixels clearance)
    if numRows > 1 then
        -- Dynamic offset: base spacing (10) + (rows * 50 pixels per row)
        debuffYOffset = -(10 + (numRows * 50))
    end

    -- Debuffs (max 16) - dynamic positioning to avoid overlap
    for i = 1, 16 do
        local debuff = _G["DebuffButton"..i]
        if debuff then
            debuff:ClearAllPoints()
            if i == 1 then
                -- Position debuffs dynamically based on number of buff rows
                debuff:SetPoint("TOPRIGHT", DebuffFrame, "TOPRIGHT", OFFSET_X-205, debuffYOffset)
            else
                -- Anchor to left of previous debuff with Blizzard spacing (-5)
                debuff:SetPoint("RIGHT", _G["DebuffButton"..(i - 1)], "LEFT", -5, 0)
            end
        end
    end
    
    -- Position TemporaryEnchantFrame and respect toggle state
    if TemporaryEnchantFrame then
        TemporaryEnchantFrame:SetAlpha(1)
        TemporaryEnchantFrame:EnableMouse(true)
        -- The individual TempEnchant buttons will be positioned by the code above
        -- Just make sure the frame itself doesn't interfere
        TemporaryEnchantFrame:ClearAllPoints()
        TemporaryEnchantFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", OFFSET_X, 0)
        
        -- Respect buffs_state toggle
        if buffs_state == 0 then
            -- Hide temp enchants when buffs are hidden
            TemporaryEnchantFrame:Hide()
            for i = 1, 3 do
                local te = _G["TempEnchant"..i]
                if te then te:Hide() end
            end
        else
            -- Ensure temp enchants are visible when buffs are shown (but only if they have enchants)
            TemporaryEnchantFrame:Show()
            -- Let Blizzard's code control individual TempEnchant visibility based on actual enchants
            -- We just need to ensure the parent frame is shown
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("UNIT_INVENTORY_CHANGED") -- Fires when weapon enchants change
f:RegisterEvent("UNIT_AURA") -- Fires when buffs/debuffs change
-- Remove duplicate event handler - will be replaced by the one below

-- Also hook Blizzard's update functions to keep positioning consistent
hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    ShiftBuffsLeft()
    AdjustBuffTimers()
end)
hooksecurefunc("DebuffButton_UpdateAnchors", function()
    ShiftBuffsLeft()
    AdjustBuffTimers()
end)

-- Hook DebuffFrame's SetPoint to detect when Blizzard repositions it
-- Do this after login to ensure DebuffFrame exists
local function HookDebuffFrame()
    if DebuffFrame and not DebuffFrame.hookedByDrakeishUI then
        local originalSetPoint = DebuffFrame.SetPoint
        DebuffFrame.SetPoint = function(self, ...)
            originalSetPoint(self, ...)
            -- Reposition debuffs after DebuffFrame moves
            local repositionTimer = CreateFrame("Frame")
            repositionTimer:SetScript("OnUpdate", function(timerFrame, delta)
                timerFrame.elapsed = (timerFrame.elapsed or 0) + delta
                if timerFrame.elapsed >= 0.05 then
                    ShiftBuffsLeft()
                    AdjustBuffTimers()
                    timerFrame:SetScript("OnUpdate", nil)
                end
            end)
        end
        DebuffFrame.hookedByDrakeishUI = true
    end
end

-- Hook temporary enchant updates to reposition when enchants are added/removed
if TemporaryEnchantFrame_Update then
    hooksecurefunc("TemporaryEnchantFrame_Update", function()
        ShiftBuffsLeft()
        AdjustBuffTimers()
    end)
end

-- Additional hook to catch buff updates that might happen after initial load
hooksecurefunc("AuraButton_Update", function(self)
    if self and self.GetName and self:GetName() and (string.find(self:GetName(), "BuffButton") or string.find(self:GetName(), "DebuffButton")) then
        -- Use WoTLK-compatible delayed execution
        local timer = CreateFrame("Frame")
        timer:SetScript("OnUpdate", function(timerFrame, delta)
            timerFrame.elapsed = (timerFrame.elapsed or 0) + delta
            if timerFrame.elapsed >= 0.1 then
                ShiftBuffsLeft()
                AdjustBuffTimers()
                timerFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Periodic check to ensure positioning stays correct (runs every 2 seconds for first 10 seconds after login)
local checkFrame = CreateFrame("Frame")
local checkCount = 0
checkFrame:SetScript("OnUpdate", function(self, elapsed)
    checkCount = checkCount + elapsed
    if checkCount >= 2 then
        checkCount = 0
        ShiftBuffsLeft()
        AdjustBuffTimers()
    end
end)

-- Main event handler with combat state support
f:SetScript("OnEvent", function(self, event, unit)
    -- Hook DebuffFrame on login events
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookDebuffFrame()
    end
    
    -- Handle unit-specific events (UNIT_AURA, UNIT_INVENTORY_CHANGED)
    if event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        -- Only reposition if it's the player's auras/inventory
        if unit and unit ~= "player" then
            return
        end
        -- Add small delay to allow Blizzard frames to update first
        local updateTimer = CreateFrame("Frame")
        updateTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.05 then
                ShiftBuffsLeft()
                AdjustBuffTimers()
                self:SetScript("OnUpdate", nil)
            end
        end)
        return
    end
    
    ShiftBuffsLeft()
    AdjustBuffTimers()
    
    -- Handle combat state changes
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        -- Combat state changed, reposition timers after a short delay
        local combatTimer = CreateFrame("Frame")
        combatTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.2 then
                ShiftBuffsLeft()
                AdjustBuffTimers()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
    
    -- Add delayed positioning to handle buffs that load after initial events
    if event == "PLAYER_ENTERING_WORLD" then
        -- Start periodic check for 10 seconds
        checkFrame:Show()
        -- Use WoTLK-compatible timer instead of C_Timer.After
        local hideTimer = CreateFrame("Frame")
        local elapsed = 0
        hideTimer:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 10 then
                checkFrame:Hide()
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        -- Use WoTLK-compatible delayed execution
        local delayTimer1 = CreateFrame("Frame")
        delayTimer1:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.5 then
                ShiftBuffsLeft()
                AdjustBuffTimers()
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        local delayTimer2 = CreateFrame("Frame")
        delayTimer2:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 1.0 then
                ShiftBuffsLeft()
                AdjustBuffTimers()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)


local buffToggleButton
do
	buffToggleButton = CreateFrame('CheckButton', 'buffstoggle', UIParent)
	buffToggleButton:SetSize(10, 14)
	buffToggleButton:SetPoint("LEFT", BuffFrame, "RIGHT", -16, 9)
	buffToggleButton:SetAlpha(0.3)
	buffToggleButton:SetNormalTexture''
	buffToggleButton:SetPushedTexture''
	buffToggleButton:SetHighlightTexture''
	buffToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = buffToggleButton:GetNormalTexture()
	normal:set_atlas('bag-arrow-2x')

	local pushed = buffToggleButton:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = buffToggleButton:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	buffToggleButton:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		if checked then
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			BuffFrame:Show()
			-- Show TemporaryEnchantFrame (let Blizzard manage individual TempEnchant buttons)
			if TemporaryEnchantFrame then
				TemporaryEnchantFrame:Show()
			end
			-- Add small delay to ensure frames are fully shown before repositioning
			local showTimer = CreateFrame("Frame")
			showTimer:SetScript("OnUpdate", function(self, delta)
				self.elapsed = (self.elapsed or 0) + delta
				if self.elapsed >= 0.05 then
					ShiftBuffsLeft()
					AdjustBuffTimers()
					self:SetScript("OnUpdate", nil)
				end
			end)
		else
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			BuffFrame:Hide()
			-- Hide TemporaryEnchantFrame (parent) - this should hide children too
			if TemporaryEnchantFrame then
				TemporaryEnchantFrame:Hide()
			end
			-- Also explicitly hide individual TempEnchant buttons to be safe
			for i = 1, 3 do
				local te = _G["TempEnchant"..i]
				if te then te:Hide() end
			end
		end
		buffs_state = checked and 1 or 0
		-- print("buffs_state saved as:", buffs_state) -- Debug line
	end)
	
	-- Add mouseover effects to match other toggle button
	buffToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	buffToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not buffs_state then buffs_state = 0 end
		if buffs_state == 1 then
			BuffFrame:Show()
			-- Show TemporaryEnchantFrame (let Blizzard manage individual TempEnchant buttons)
			if TemporaryEnchantFrame then
				TemporaryEnchantFrame:Show()
			end
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			buffToggleButton:SetChecked(1)
			-- Add small delay to ensure frames are fully shown before repositioning
			local loginTimer = CreateFrame("Frame")
			loginTimer:SetScript("OnUpdate", function(self, delta)
				self.elapsed = (self.elapsed or 0) + delta
				if self.elapsed >= 0.1 then
					ShiftBuffsLeft()
					AdjustBuffTimers()
					self:SetScript("OnUpdate", nil)
				end
			end)
		else
			BuffFrame:Hide()
			-- Hide TemporaryEnchantFrame (parent) - this should hide children too
			if TemporaryEnchantFrame then
				TemporaryEnchantFrame:Hide()
			end
			-- Also explicitly hide individual TempEnchant buttons to be safe
			for i = 1, 3 do
				local te = _G["TempEnchant"..i]
				if te then te:Hide() end
			end
			buffToggleButton:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end

