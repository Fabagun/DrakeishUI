local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


-- Create event frame
local WatchEvent = CreateFrame("Frame")
WatchEvent:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Function to reposition WatchFrame and add banner
local function SetupWatchFrame()
    -- === WatchFrame Repositioning ===
    WatchFrame:SetMovable(true)
    WatchFrame:SetUserPlaced(true)
    WatchFrame:SetHeight(300)
	WatchFrame:SetScale(1)
	
	if WatchFrameTitle then
        WatchFrameTitle:Hide()
        -- Prevent it from being shown again
        WatchFrameTitle.Show = function() end
    end
	

    if MultiBarRight:IsVisible() and MultiBarLeft:IsVisible() then
        WatchFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 190, -30)
    elseif MultiBarRight:IsVisible() then
        WatchFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 190, -30)
    else
        WatchFrame:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 190, -30)
    end

    -- === WatchFrameCollapseExpandButton Repositioning ===
    if WatchFrameCollapseExpandButton then
        -- Move the collapse/expand button 4 pixels to the left
        local currentPoint, relativeTo, relativePoint, xOfs, yOfs = WatchFrameCollapseExpandButton:GetPoint()
        WatchFrameCollapseExpandButton:ClearAllPoints()
        WatchFrameCollapseExpandButton:SetPoint(currentPoint, relativeTo, relativePoint, xOfs - 4, yOfs)
        
        -- Set alpha to 50% normally
        WatchFrameCollapseExpandButton:SetAlpha(0.5)
        
        -- Add mouseover effects
        WatchFrameCollapseExpandButton:SetScript("OnEnter", function(self)
            self:SetAlpha(1.0)  -- 100% alpha on mouseover
        end)
        
        WatchFrameCollapseExpandButton:SetScript("OnLeave", function(self)
            self:SetAlpha(0.5)  -- 50% alpha normally
        end)
    end

    -- === Banner Texture ===
    if not WatchFrameBanner then
        local bannerFrame = CreateFrame("Frame", "WatchFrameBanner", WatchFrameHeader)
        bannerFrame:SetSize(216, 32)  -- Adjust size to your needs
        bannerFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -58)
		bannerFrame:SetFrameStrata(WatchFrameHeader:GetFrameStrata())
        bannerFrame:SetFrameLevel(WatchFrameHeader:GetFrameLevel() - 1)  -- Behind the header
        bannerFrame:SetAlpha(1.0)  -- Ensure frame is fully visible
        
        -- Also ensure parent frame is fully visible
        if WatchFrameHeader then
            WatchFrameHeader:SetAlpha(1.0)
        end

        local bannerTexture = bannerFrame:CreateTexture(nil, "BACKGROUND")
        bannerTexture:SetAllPoints()
        bannerTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\Assets\\questtrackerheader3.tga")  -- Change if needed
        bannerTexture:SetAlpha(1.0)  -- Ensure full visibility

        -- Optional: Add title text
        local bannerText = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bannerText:SetPoint("CENTER", bannerFrame, "CENTER", 0, 0)
        bannerText:SetText("World Objectives")
    end
end

-- Register the function to run after the player enters the world
WatchEvent:SetScript("OnEvent", function()
    SetupWatchFrame()
end)


local questToggleButton
do
	questToggleButton = CreateFrame('CheckButton', 'watchframetoggle', UIParent)
	questToggleButton:SetSize(10, 14)
	questToggleButton:SetPoint("LEFT", UIParent, "RIGHT", -12, 295)
	questToggleButton:SetAlpha(0.3)
	questToggleButton:SetNormalTexture''
	questToggleButton:SetPushedTexture''
	questToggleButton:SetHighlightTexture''
	questToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = questToggleButton:GetNormalTexture()
	normal:set_atlas('bag-arrow-invert-2x')

	local pushed = questToggleButton:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = questToggleButton:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-invert-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	questToggleButton:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		if checked then
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			WatchFrame:Hide()
		else
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			WatchFrame:Show()
		end
		quest_state = checked and 1 or 0
		-- print("quest_state saved as:", quest_state) -- Debug line
	end)
	
	-- Add mouseover effects to match other toggle button
	questToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	questToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not quest_state then quest_state = 0 end
		if quest_state == 1 then
			WatchFrame:Hide()
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			questToggleButton:SetChecked(1)
		else
			WatchFrame:Show()
			questToggleButton:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end


