local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;

local right_actionbars = true
local sidebarsManuallyHidden = false

local function ConfigureMultiBars()
    -- Constants
    local BUTTON_SIZE = 36
    local BUTTON_SPACING = 6
    local ROWS = 3
    local COLUMNS = 4
    local OFFSET_X_LEFT = -480
    local OFFSET_X_RIGHT = 477
    local OFFSET_Y = 6
    local SCALE = 0.8

    local function MoveBar(barName, offsetX)
        local barFrame = _G[barName]
        if not barFrame then return end

        -- Set scale
        barFrame:SetScale(SCALE)

        -- Set parent & position
        barFrame:SetParent(UIParent)
        barFrame:ClearAllPoints()
        barFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", offsetX, OFFSET_Y)

        -- Resize the frame to cover the whole 4x3 grid (including spacing)
        local width = (BUTTON_SIZE * COLUMNS) + (BUTTON_SPACING * (COLUMNS - 1))
        local height = (BUTTON_SIZE * ROWS) + (BUTTON_SPACING * (ROWS - 1))
        barFrame:SetSize(width, height)

        -- Position buttons in 4x3 grid
        for i = 1, 12 do
            local button = _G[barName.."Button"..i]
            if button then
                local row = math.floor((i - 1) / COLUMNS)
                local col = (i - 1) % COLUMNS
                local x = col * (BUTTON_SIZE + BUTTON_SPACING)
                local y = -row * (BUTTON_SIZE + BUTTON_SPACING)

                button:ClearAllPoints()
                button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
                button:SetPoint("TOPLEFT", barFrame, "TOPLEFT", x, y)
            end
        end
    end

    MoveBar("MultiBarLeft", OFFSET_X_LEFT)
    MoveBar("MultiBarRight", OFFSET_X_RIGHT)
end

ConfigureMultiBars()

-- Re-run configuration on events that might change bar positions
local positionFrame = CreateFrame("Frame")
positionFrame:RegisterEvent("PLAYER_LOGIN")
positionFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
positionFrame:SetScript("OnEvent", function(self, event)
    -- Small delay to ensure other UI elements have loaded (WoTLK-compatible timer)
    local timer = CreateFrame("Frame")
    timer.elapsed = 0
    timer:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.1 then
            ConfigureMultiBars()
            self:SetScript("OnUpdate", nil)
        end
    end)
end)

-- Your original mouseover function unchanged

local function IsInVehicle()
    return UnitHasVehicleUI and UnitHasVehicleUI('player')
end

local enableMouseOver = function(frame, includeChildren)
    local show = function()
        if not sidebarsManuallyHidden and not IsInVehicle() then
            frame:SetAlpha(1)
        end
    end

    local hide = function()
        if not sidebarsManuallyHidden and not IsInVehicle() then
            frame:SetAlpha(0)
        end
    end

    if includeChildren then
        for _, child in ipairs({frame:GetChildren()}) do
            child:HookScript("OnEnter", show)
            child:HookScript("OnLeave", hide)
        end
    end

    frame:EnableMouse(true)
    frame:HookScript("OnEnter", show)
    frame:HookScript("OnLeave", hide)
    hide()
end

if right_actionbars then
    enableMouseOver(MultiBarLeft, true)
    enableMouseOver(MultiBarRight, true)
end

local sidebarsToggleButton
do
	sidebarsToggleButton = CreateFrame('CheckButton', 'sidebarstoggle', UIParent)
	sidebarsToggleButton:SetSize(16, 16)  -- Square size for better texture display
	sidebarsToggleButton:SetPoint("RIGHT", MainMenuBar, "RIGHT", -231, -16)
	sidebarsToggleButton:SetAlpha(0.3)
	sidebarsToggleButton:SetNormalTexture''
	sidebarsToggleButton:SetPushedTexture''
	sidebarsToggleButton:SetHighlightTexture''
	sidebarsToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = sidebarsToggleButton:GetNormalTexture()
	normal:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	normal:SetAllPoints()  -- Make texture fill the entire button
	normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)

	local pushed = sidebarsToggleButton:GetPushedTexture()
	pushed:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	pushed:SetAllPoints()
	pushed:SetTexCoord(0.5, 1, 0, 1)

	local highlight = sidebarsToggleButton:GetHighlightTexture()
	highlight:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	highlight:SetAllPoints()
	highlight:SetTexCoord(0.5, 1, 0, 1)
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	sidebarsToggleButton:SetScript('OnClick',function(self)
		-- Don't allow toggling when in vehicle
		if IsInVehicle() then
			return
		end
		
		local checked = self:GetChecked();
		if checked then
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - bars are hidden)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
            MultiBarRight:Hide()
            MultiBarLeft:Hide()
            -- Disable all action buttons to prevent tooltips
            for i = 1, 12 do
                local leftButton = _G["MultiBarLeftButton" .. i]
                local rightButton = _G["MultiBarRightButton" .. i]
                if leftButton then leftButton:Disable() end
                if rightButton then rightButton:Disable() end
            end
            sidebarsManuallyHidden = true
		else
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - bars are visible)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
            MultiBarRight:Show()
            MultiBarLeft:Show()
            -- Re-enable all action buttons
            for i = 1, 12 do
                local leftButton = _G["MultiBarLeftButton" .. i]
                local rightButton = _G["MultiBarRightButton" .. i]
                if leftButton then leftButton:Enable() end
                if rightButton then rightButton:Enable() end
            end
            sidebarsManuallyHidden = false
		end
		sidebars_state = checked and 1 or 0
		-- print("sidebars_state saved as:", sidebars_state) -- Debug line
	end)
	
	-- Add mouseover effects to match other toggle button
	sidebarsToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	sidebarsToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	-- Handle vehicle enter/exit events to hide sidebars
	local vehicleFrame = CreateFrame("Frame")
	vehicleFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	vehicleFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	vehicleFrame:SetScript("OnEvent", function(self, event, unit)
		if unit ~= "player" then return end
		
		if event == "UNIT_ENTERED_VEHICLE" then
			-- Hide sidebars when entering vehicle
			MultiBarLeft:Hide()
			MultiBarRight:Hide()
			sidebarsToggleButton:Hide()
			-- Disable all action buttons to prevent tooltips
			for i = 1, 12 do
				local leftButton = _G["MultiBarLeftButton" .. i]
				local rightButton = _G["MultiBarRightButton" .. i]
				if leftButton then leftButton:Disable() end
				if rightButton then rightButton:Disable() end
			end
		elseif event == "UNIT_EXITED_VEHICLE" then
			-- Restore sidebars state when exiting vehicle
			sidebarsToggleButton:Show()
			if not sidebarsManuallyHidden then
				MultiBarLeft:Show()
				MultiBarRight:Show()
				-- Re-enable all action buttons
				for i = 1, 12 do
					local leftButton = _G["MultiBarLeftButton" .. i]
					local rightButton = _G["MultiBarRightButton" .. i]
					if leftButton then leftButton:Enable() end
					if rightButton then rightButton:Enable() end
				end
			end
		end
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not sidebars_state then sidebars_state = 0 end
		if sidebars_state == 1 then
            MultiBarRight:Hide()
            MultiBarLeft:Hide()
            -- Disable all action buttons to prevent tooltips
            for i = 1, 12 do
                local leftButton = _G["MultiBarLeftButton" .. i]
                local rightButton = _G["MultiBarRightButton" .. i]
                if leftButton then leftButton:Disable() end
                if rightButton then rightButton:Disable() end
            end
            sidebarsManuallyHidden = true
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - bars are hidden)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			sidebarsToggleButton:SetChecked(1)
		else
            MultiBarRight:Show()
            MultiBarLeft:Show()
            -- Re-enable all action buttons
            for i = 1, 12 do
                local leftButton = _G["MultiBarLeftButton" .. i]
                local rightButton = _G["MultiBarRightButton" .. i]
                if leftButton then leftButton:Enable() end
                if rightButton then rightButton:Enable() end
            end
            sidebarsManuallyHidden = false
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - bars are visible)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
			sidebarsToggleButton:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end
