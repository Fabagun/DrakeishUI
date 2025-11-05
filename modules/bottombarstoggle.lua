local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;

-- Create single toggle button for both MultiBarBottomLeft and MultiBarBottomRight
local toggleBars
do
	toggleBars = CreateFrame('Button', 'bottombarstoggle', UIParent)
	toggleBars:SetSize(16, 16)  -- Square size for better texture display
	toggleBars:SetPoint("CENTER", pUiMainBar, "CENTER", 253, -44)
	toggleBars:SetAlpha(0.3)
	toggleBars:EnableMouse(true)
	toggleBars:RegisterForClicks('LeftButtonUp')

	-- Create texture for the button
	toggleBars.texture = toggleBars:CreateTexture(nil, "OVERLAY")
	toggleBars.texture:SetSize(16, 16)
	toggleBars.texture:SetPoint("CENTER", toggleBars, "CENTER", 0, 0)
	toggleBars.texture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	toggleBars.texture:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - both bars visible)
	
	-- State tracking: 0 = both visible, 1 = right hidden, 2 = both hidden, 3 = left hidden
	local barState = 0
	local bottomBarsManuallyHidden = false
	
	local function UpdateToggleButton()
		if barState == 0 then
			-- Both bars visible
			toggleBars.texture:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - both visible)
		elseif barState == 1 then
			-- Right bar hidden, left visible
			toggleBars.texture:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - still collapsing)
		elseif barState == 2 then
			-- Both bars hidden
			toggleBars.texture:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - both hidden)
		elseif barState == 3 then
			-- Left bar hidden, right visible
			toggleBars.texture:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - still expanding)
		end
	end
	
	toggleBars:SetScript('OnClick',function(self)

		-- Cycle through states: 0 -> 1 -> 2 -> 3 -> 0
		barState = (barState + 1) % 4
		
		-- Update manual hidden state based on current state
		if barState == 0 then
			-- Both bars visible
			bottomBarsManuallyHidden = false
			MultiBarBottomLeft:Show()
			MultiBarBottomRight:Show()
		elseif barState == 1 then
			-- Hide right bar first
			bottomBarsManuallyHidden = false
			MultiBarBottomRight:Hide()
			MultiBarBottomLeft:Show()
		elseif barState == 2 then
			-- Hide both bars
			bottomBarsManuallyHidden = true
			MultiBarBottomLeft:Hide()
			MultiBarBottomRight:Hide()
		elseif barState == 3 then
			-- Show left bar first, keep right hidden
			bottomBarsManuallyHidden = false
			MultiBarBottomLeft:Show()
			MultiBarBottomRight:Hide()
		end
		
		UpdateToggleButton()
		bottombars_state = barState
		-- print("bottombars_state saved as:", bottombars_state) -- Debug line
		
		-- Update hooks with new state
		HookBottomBars()
	end)
	
	-- Add mouseover effects to match other toggle button
	toggleBars:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	toggleBars:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not bottombars_state then bottombars_state = 0 end
		barState = bottombars_state
		
		-- print("Restoring bottombars_state:", bottombars_state) -- Debug line
		
		-- Update manual hidden state based on restored state
		if barState == 0 then
			bottomBarsManuallyHidden = false
		elseif barState == 1 then
			bottomBarsManuallyHidden = false
		elseif barState == 2 then
			bottomBarsManuallyHidden = true
		elseif barState == 3 then
			bottomBarsManuallyHidden = false
		end
		
		-- Apply state immediately
		if barState == 0 then
			MultiBarBottomLeft:Show()
			MultiBarBottomRight:Show()
		elseif barState == 1 then
			MultiBarBottomRight:Hide()
			MultiBarBottomLeft:Show()
		elseif barState == 2 then
			MultiBarBottomLeft:Hide()
			MultiBarBottomRight:Hide()
		elseif barState == 3 then
			MultiBarBottomLeft:Show()
			MultiBarBottomRight:Hide()
		end
		
		UpdateToggleButton()
		-- print("Applied state immediately:", barState) -- Debug line
		
		-- Update hooks with restored state
		HookBottomBars()
	end, 'PLAYER_LOGIN'
	);
	
	-- Hook the Show methods to prevent other modules from showing bars when our toggle is active
	local function HookBottomBars()
		if MultiBarBottomLeft then
			local originalShow = MultiBarBottomLeft.Show
			MultiBarBottomLeft.Show = function(self)
				-- Block MultiBarBottomLeft from showing only in state 2
				if barState == 2 then
					return -- Don't show
				else
					originalShow(self)
				end
			end
		end
		
		if MultiBarBottomRight then
			local originalShow = MultiBarBottomRight.Show
			MultiBarBottomRight.Show = function(self)
				-- Block MultiBarBottomRight from showing in states 1, 2, and 3
				if barState == 1 or barState == 2 or barState == 3 then
					return -- Don't show
				else
					originalShow(self)
				end
			end
		end
	end
	
	-- Initialize the hooks
	local hookFrame = CreateFrame("Frame")
	hookFrame:RegisterEvent("PLAYER_LOGIN")
	hookFrame:SetScript("OnEvent", function()
		HookBottomBars()
	end)
end


