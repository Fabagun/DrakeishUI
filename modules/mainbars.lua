local addon = select(2,...);
local config = addon.config;
local event = addon.package;
local do_action = addon.functions;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local format = string.format;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local UnitFactionGroup = UnitFactionGroup;
local _G = getfenv(0);

-- const
local faction = UnitFactionGroup('player');
local old = (config.style.xpbar == 'old');
local new = (config.style.xpbar == 'new');
local MainMenuBarMixin = {};
local pUiMainBar = CreateFrame(
	'Frame',
	'pUiMainBar',
	UIParent,
	'MainMenuBarUiTemplate'
);
local pUiMainBarArt = CreateFrame(
	'Frame',
	'pUiMainBarArt',
	pUiMainBar
);
pUiMainBar:SetScale(config.mainbars.scale_actionbar);
pUiMainBarArt:SetFrameStrata('HIGH');
pUiMainBarArt:SetFrameLevel(pUiMainBar:GetFrameLevel() + 4);
pUiMainBarArt:SetAllPoints(pUiMainBar);

function MainMenuBarMixin:actionbutton_setup()
	for _,obj in ipairs({MainMenuBar:GetChildren(),MainMenuBarArtFrame:GetChildren()}) do
		obj:SetParent(pUiMainBar)
	end
	
	for index=1, NUM_ACTIONBAR_BUTTONS do
		pUiMainBar:SetFrameRef('ActionButton'..index, _G['ActionButton'..index])
	end
	
	for index=1, NUM_ACTIONBAR_BUTTONS -1 do
		local ActionButtons = _G['ActionButton'..index]
		do_action.SetThreeSlice(ActionButtons);
	end
	
	for index=2, NUM_ACTIONBAR_BUTTONS do
		local ActionButtons = _G['ActionButton'..index]
		ActionButtons:SetParent(pUiMainBar)
		ActionButtons:SetClearPoint('LEFT', _G['ActionButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BottomLeftButtons = _G['MultiBarBottomLeftButton'..index]
		BottomLeftButtons:SetClearPoint('LEFT', _G['MultiBarBottomLeftButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BottomRightButtons = _G['MultiBarBottomRightButton'..index]
		BottomRightButtons:SetClearPoint('LEFT', _G['MultiBarBottomRightButton'..(index-1)], 'RIGHT', 7, 0)
		
		local BonusActionButtons = _G['BonusActionButton'..index]
		BonusActionButtons:SetClearPoint('LEFT', _G['BonusActionButton'..(index-1)], 'RIGHT', 7, 0)
	end
end

function MainMenuBarMixin:actionbar_art_setup()
	-- art
	MainMenuBarArtFrame:SetParent(pUiMainBar)
	for _,art in pairs({MainMenuBarLeftEndCap, MainMenuBarRightEndCap}) do
		art:SetParent(pUiMainBarArt)
		art:SetDrawLayer('ARTWORK')
	end
	
	if config.style.gryphons == 'old' then
		MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -85, -22)
		MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
	elseif config.style.gryphons == 'new' then
		MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
		MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
	elseif config.style.gryphons == 'flying' then
		MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
		MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
	else
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	end
end

function MainMenuBarMixin:actionbar_setup()
	ActionButton1:SetParent(pUiMainBar)
	ActionButton1:SetClearPoint('BOTTOMLEFT', pUiMainBar, 2, 2)
	MultiBarBottomLeftButton1:SetClearPoint('BOTTOMLEFT', ActionButton1, 'BOTTOMLEFT', 0, 49)
	
	if config.buttons.pages.show then
		do_action.SetNumPagesButton(ActionBarUpButton, pUiMainBarArt, 'pageuparrow', -2)
		do_action.SetNumPagesButton(ActionBarDownButton, pUiMainBarArt, 'pagedownarrow', -24)
		
		MainMenuBarPageNumber:SetParent(pUiMainBarArt)
		MainMenuBarPageNumber:SetClearPoint('CENTER', ActionBarDownButton, 0, 12)
		MainMenuBarPageNumber:SetFont(unpack(config.buttons.pages.font))
		MainMenuBarPageNumber:SetShadowColor(0, 0, 0, 1)
		MainMenuBarPageNumber:SetShadowOffset(1.2, -1.2)
		MainMenuBarPageNumber:SetDrawLayer('OVERLAY', 7)
		
		-- Hide page controls by default
		ActionBarUpButton:SetAlpha(0)
		ActionBarDownButton:SetAlpha(0)
		MainMenuBarPageNumber:SetAlpha(0)
		
		-- Create invisible frame anchor for page controls mouseover
		local pageControlsAnchor = CreateFrame("Frame", "PageControlsAnchor", pUiMainBarArt)
		pageControlsAnchor:SetSize(32, 50) -- Reduced width by 60% to cover the page controls area
		pageControlsAnchor:SetPoint("CENTER", ActionBarDownButton, "CENTER", 0, 10)
		pageControlsAnchor:EnableMouse(true)
		pageControlsAnchor:SetFrameLevel(pUiMainBarArt:GetFrameLevel() + 1) -- Very low frame level
		pageControlsAnchor:EnableMouseWheel(false) -- Disable mouse wheel to allow clicks to pass through
		
		-- Frame-based timer for hiding
		local timerFrame = CreateFrame("Frame")
		local hideDelay = 0
		local shouldHide = false
		
		timerFrame:SetScript("OnUpdate", function(self, elapsed)
			if shouldHide then
				hideDelay = hideDelay + elapsed
				if hideDelay >= 1.0 then
					ActionBarUpButton:SetAlpha(0)
					ActionBarDownButton:SetAlpha(0)
					MainMenuBarPageNumber:SetAlpha(0)
					shouldHide = false
					hideDelay = 0
				end
			end
		end)
		
		pageControlsAnchor:SetScript("OnEnter", function(self)
			-- Stop hiding
			shouldHide = false
			hideDelay = 0
			ActionBarUpButton:SetAlpha(1)
			ActionBarDownButton:SetAlpha(1)
			MainMenuBarPageNumber:SetAlpha(1)
			-- Ensure buttons are clickable when visible
			ActionBarUpButton:EnableMouse(true)
			ActionBarDownButton:EnableMouse(true)
		end)
		
		pageControlsAnchor:SetScript("OnLeave", function(self)
			-- Start hiding timer
			shouldHide = true
			hideDelay = 0
		end)
	else
		ActionBarUpButton:Hide();
		ActionBarDownButton:Hide();
		MainMenuBarPageNumber:Hide();
	end
	MultiBarBottomLeft:SetParent(pUiMainBar)
	MultiBarBottomRight:SetParent(pUiMainBar)
	MultiBarBottomRight:EnableMouse(false)
	MultiBarBottomRight:SetClearPoint('BOTTOMLEFT', MultiBarBottomLeftButton1, 'TOPLEFT', 0, 8)
	-- MultiBarRight:SetClearPoint('TOPRIGHT', UIParent, 'RIGHT', -6, (Minimap:GetHeight() * 1.3))
	-- MultiBarRight:SetScale(config.mainbars.scale_rightbar)
	-- MultiBarLeft:SetScale(config.mainbars.scale_leftbar)

	-- MultiBarLeft:SetParent(UIParent)
	-- MultiBarLeft:SetClearPoint('TOPRIGHT', MultiBarRight, 'TOPLEFT', -7, 0)
end

event:RegisterEvents(function()
	MainMenuBarPageNumber:SetText(GetActionBarPage());
end,
	'ACTIONBAR_PAGE_CHANGED'
);

function MainMenuBarMixin:statusbar_setup()
	for _,bar in pairs({MainMenuExpBar,ReputationWatchStatusBar}) do
		bar:GetStatusBarTexture():SetDrawLayer('BORDER')
		bar.status = bar:CreateTexture(nil, 'ARTWORK')
		if old then
			bar:SetSize(545, 10)
			bar.status:SetPoint('CENTER', -2, -1)  -- Move 2px left to prevent edge overflow
			bar.status:SetSize(545, 10)  -- Match bar height to prevent overflow
			bar.status:set_atlas('ui-hud-experiencebar')
		elseif new then
			bar:SetSize(537, 10)
			bar.status:SetPoint('CENTER', -2, -2)  -- Move 2px left to prevent edge overflow
			bar.status:SetSize(537, 10)  -- Match bar height to prevent overflow
			bar.status:set_atlas('ui-hud-experiencebar-round', true)
			ReputationWatchStatusBar:SetStatusBarTexture(addon._dir..'statusbarfill.tga')
			ReputationWatchStatusBarBackground:set_atlas('ui-hud-experiencebar-background', true)
			ExhaustionTick:GetNormalTexture():set_atlas('ui-hud-experiencebar-frame-pip')
			ExhaustionTick:GetHighlightTexture():set_atlas('ui-hud-experiencebar-frame-pip-mouseover')
			ExhaustionTick:GetHighlightTexture():SetBlendMode('ADD')
		else
			bar.status:Hide()
		end
	end
	
	-- Position XP bar above reputation bar (inverted positions)
	MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 3, 22)
	MainMenuExpBar:SetFrameLevel(10)
	ReputationWatchBar:SetParent(pUiMainBar)
	ReputationWatchBar:SetFrameLevel(10)
	ReputationWatchBar:SetWidth(ReputationWatchStatusBar:GetWidth())
	ReputationWatchBar:SetHeight(ReputationWatchStatusBar:GetHeight())
	
	MainMenuBarExpText:SetParent(MainMenuExpBar)
	MainMenuBarExpText:SetClearPoint('CENTER', MainMenuExpBar, 'CENTER', 0, old and 0 or 1)
	
	if new then
		for _,obj in pairs{MainMenuExpBar:GetRegions()} do 
			if obj:GetObjectType() == 'Texture' and obj:GetDrawLayer() == 'BACKGROUND' then
				obj:set_atlas('ui-hud-experiencebar-background', true)
			end
		end
	end
end

event:RegisterEvents(function(self)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD');
	local exhaustionStateID = GetRestState();
	ExhaustionTick:SetParent(pUiMainBar);
	ExhaustionTick:SetFrameLevel(MainMenuExpBar:GetFrameLevel() +2);
	if new then
		ExhaustionLevelFillBar:SetHeight(MainMenuExpBar:GetHeight());
		ExhaustionLevelFillBar:set_atlas('ui-hud-experiencebar-fill-prediction');
		ExhaustionTick:SetSize(10, 14);
		ExhaustionTick:SetClearPoint('CENTER', ExhaustionLevelFillBar, 'RIGHT', 0, 2);

		MainMenuExpBar:SetStatusBarTexture(addon._dir..'uiexperiencebar');
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(574/2048, 1137/2048, 34/64, 43/64);
			ExhaustionLevelFillBar:SetVertexColor(0.0, 0, 1, 0.45);
		elseif exhaustionStateID == 2 then
			MainMenuExpBar:GetStatusBarTexture():SetTexCoord(1/2048, 570/2048, 42/64, 51/64);
			ExhaustionLevelFillBar:SetVertexColor(0.58, 0.0, 0.55, 0.45);
		end
	else
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
		end
	end
end,
	'PLAYER_ENTERING_WORLD',
	'UPDATE_EXHAUSTION'
);

local both = config.xprepbar.bothbar_offset;
local single = config.xprepbar.singlebar_offset;
local nobar	= config.xprepbar.nobar_offset;
local abovexp = config.xprepbar.repbar_abovexp_offset;
local default = config.xprepbar.repbar_offset;

hooksecurefunc('ReputationWatchBar_Update',function()
	local name = GetWatchedFactionInfo();
	if name then
		-- Position reputation bar below XP bar with 3px spacing (closest to main action bar)
		ReputationWatchBar:SetClearPoint('BOTTOM', UIParent, 3, 3);
		ReputationWatchBarOverlayFrame:SetClearPoint('BOTTOM', UIParent, 3, 3);
		ReputationWatchStatusBar:SetHeight(10)
		ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)
		ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, old and 0 or 1);
		ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
	end
end)

-- method update position - always keep main bar at "both bars visible" position
function pUiMainBar:actionbar_update()
	-- Always position main bar as if both XP and rep bars are visible
	-- This prevents toggle buttons from going off screen when bars are hidden
	self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, both);
end

event:RegisterEvents(function()
	pUiMainBar:actionbar_update();
end,
	'PLAYER_LOGIN','ADDON_LOADED'
);


for _,bar in pairs({MainMenuExpBar,ReputationWatchBar}) do
	if notRequired then return; end
	
	local yOffset = select(5, pUiMainBar:GetPoint());
	if (yOffset == nobar) then notRequired = true; end
	
	bar:HookScript('OnShow',function()
		if (yOffset ~= nobar) then
			pUiMainBar:actionbar_update();
		end
	end);
	bar:HookScript('OnHide',function()
		if (yOffset ~= nobar) then
			pUiMainBar:actionbar_update();
		end
	end);
end;

function MainMenuBarMixin:initialize()
	self:actionbutton_setup();
	self:actionbar_setup();
	self:actionbar_art_setup();
	self:statusbar_setup();
end
addon.pUiMainBar = pUiMainBar;
MainMenuBarMixin:initialize();

-- TOGGLE BUTTON

local capsToggleButton
do
	capsToggleButton = CreateFrame('CheckButton', 'gryphontoggle', UIParent)
	capsToggleButton:SetSize(16, 16)  -- Square size for better texture display
	capsToggleButton:SetPoint("LEFT", MainMenuBar, "LEFT", 250, -16)
	capsToggleButton:SetAlpha(0.3)
	capsToggleButton:SetNormalTexture''
	capsToggleButton:SetPushedTexture''
	capsToggleButton:SetHighlightTexture''
	capsToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = capsToggleButton:GetNormalTexture()
	normal:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	normal:SetAllPoints()  -- Make texture fill the entire button
	normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)

	local pushed = capsToggleButton:GetPushedTexture()
	pushed:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	pushed:SetAllPoints()
	pushed:SetTexCoord(0.5, 1, 0, 1)

	local highlight = capsToggleButton:GetHighlightTexture()
	highlight:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	highlight:SetAllPoints()
	highlight:SetTexCoord(0.5, 1, 0, 1)
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	capsToggleButton:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		if checked then
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - caps are hidden)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
			MainMenuBarLeftEndCap:Show()
		   MainMenuBarRightEndCap:Show()
		else
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			MainMenuBarLeftEndCap:Hide()
		    MainMenuBarRightEndCap:Hide()
		end
		caps_state = checked and 1 or 0
		-- print("buffs_state saved as:", buffs_state) -- Debug line
	end)
	
	-- Add mouseover effects to match other toggle button
	capsToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	capsToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not caps_state then caps_state = 0 end
		if caps_state == 1 then
			MainMenuBarLeftEndCap:Show()
		    MainMenuBarRightEndCap:Show()
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - caps are hidden)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
			capsToggleButton:SetChecked(1)
		else
			MainMenuBarLeftEndCap:Hide()
		    MainMenuBarRightEndCap:Hide()
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			capsToggleButton:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end


local stanceToggleButton
local stanceBarsManuallyHidden = false
do
	stanceToggleButton = CreateFrame('CheckButton', 'stancetoggle', UIParent)
	stanceToggleButton:SetSize(16, 16)  -- Square size for better texture display
	stanceToggleButton:SetPoint("LEFT", MainMenuBar, "LEFT", 230, -16)
	stanceToggleButton:SetAlpha(0.3)
	stanceToggleButton:SetNormalTexture''
	stanceToggleButton:SetPushedTexture''
	stanceToggleButton:SetHighlightTexture''
	stanceToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = stanceToggleButton:GetNormalTexture()
	normal:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	normal:SetAllPoints()  -- Make texture fill the entire button
	normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)

	local pushed = stanceToggleButton:GetPushedTexture()
	pushed:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	pushed:SetAllPoints()
	pushed:SetTexCoord(0.5, 1, 0, 1)

	local highlight = stanceToggleButton:GetHighlightTexture()
	highlight:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\uicollapsebuttonh.tga")
	highlight:SetAllPoints()
	highlight:SetTexCoord(0.5, 1, 0, 1)
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	stanceToggleButton:SetScript('OnClick',function(self)
		if InCombatLockdown() then
			print("Cannot toggle stance bars while in combat.")
			return
		end

		local checked = self:GetChecked();
		
		if checked then
			-- Show all stance bars
			stanceBarsManuallyHidden = false
			
			if pUiStanceBar then 
				pUiStanceBar:SetAlpha(1)
				pUiStanceBar:Show()
			end
			if pUiPetBar then 
				pUiPetBar:SetAlpha(1)
				pUiPetBar:Show()
			end
			if pUiPossessBar then 
				pUiPossessBar:SetAlpha(1)
				pUiPossessBar:Show()
			end
			if MultiCastActionBarFrame then 
				MultiCastActionBarFrame:SetAlpha(1)
				MultiCastActionBarFrame:Show()
			end
			
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - bars are shown)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
		else
			-- Hide all stance bars
			if pUiStanceBar then 
				pUiStanceBar:Hide()
				pUiStanceBar:SetAlpha(0)
			end
			if pUiPetBar then 
				pUiPetBar:Hide()
				pUiPetBar:SetAlpha(0)
			end
			if pUiPossessBar then 
				pUiPossessBar:Hide()
				pUiPossessBar:SetAlpha(0)
			end
			if MultiCastActionBarFrame then MultiCastActionBarFrame:Hide() end
			
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - bars are hidden)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			stanceBarsManuallyHidden = true
		end
		stance_state = checked and 1 or 0
	end)
	
	-- Add mouseover effects to match other toggle button
	stanceToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	stanceToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not stance_state then stance_state = 0 end
		if stance_state == 1 then
			-- Bars are shown, show up arrow
			stanceBarsManuallyHidden = false
			stanceToggleButton:SetChecked(1)
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - bars are shown)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
			-- Show bars
			if pUiStanceBar then 
				pUiStanceBar:SetAlpha(1)
				pUiStanceBar:Show()
			end
			if pUiPetBar then 
				pUiPetBar:SetAlpha(1)
				pUiPetBar:Show()
			end
			if pUiPossessBar then 
				pUiPossessBar:SetAlpha(1)
				pUiPossessBar:Show()
			end
			if MultiCastActionBarFrame then 
				MultiCastActionBarFrame:SetAlpha(1)
				MultiCastActionBarFrame:Show()
			end
		else
			-- Bars are hidden, show down arrow
			stanceBarsManuallyHidden = true
			stanceToggleButton:SetChecked(nil)
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - bars are hidden)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			-- Hide bars
			if pUiStanceBar then 
				pUiStanceBar:Hide()
				pUiStanceBar:SetAlpha(0)
			end
			if pUiPetBar then 
				pUiPetBar:Hide()
				pUiPetBar:SetAlpha(0)
			end
			if pUiPossessBar then 
				pUiPossessBar:Hide()
				pUiPossessBar:SetAlpha(0)
			end
			if MultiCastActionBarFrame then MultiCastActionBarFrame:Hide() end
		end
	end, 'PLAYER_LOGIN'
	);
end



-- Override the original Show/Hide methods to respect manual toggle
local function OverrideBarVisibility()
    if stanceBarsManuallyHidden then
        -- Force hide all stance bars regardless of state drivers
        if pUiStanceBar then 
            pUiStanceBar:Hide()
            pUiStanceBar:SetAlpha(0)
        end
        if pUiPetBar then 
            pUiPetBar:Hide()
            pUiPetBar:SetAlpha(0)
        end
        if pUiPossessBar then 
            pUiPossessBar:Hide()
            pUiPossessBar:SetAlpha(0)
        end
        if MultiCastActionBarFrame then 
            MultiCastActionBarFrame:Hide()
            MultiCastActionBarFrame:SetAlpha(0)
        end
    else
        -- Allow normal visibility behavior
        if pUiStanceBar then 
            pUiStanceBar:SetAlpha(1)
        end
        if pUiPetBar then 
            pUiPetBar:SetAlpha(1)
        end
        if pUiPossessBar then 
            pUiPossessBar:SetAlpha(1)
        end
        if MultiCastActionBarFrame then 
            MultiCastActionBarFrame:SetAlpha(1)
        end
    end
end

-- Hook into the bar frames to maintain manual override
local function HookBarFrames()
    if pUiStanceBar then
        local originalShow = pUiStanceBar.Show
        pUiStanceBar.Show = function(self)
            if not stanceBarsManuallyHidden then
                originalShow(self)
            end
        end
    end
    
    if pUiPetBar then
        local originalShow = pUiPetBar.Show
        pUiPetBar.Show = function(self)
            if not stanceBarsManuallyHidden then
                originalShow(self)
            end
        end
    end
    
    if pUiPossessBar then
        local originalShow = pUiPossessBar.Show
        pUiPossessBar.Show = function(self)
            if not stanceBarsManuallyHidden then
                originalShow(self)
            end
        end
    end
    
    if MultiCastActionBarFrame then
        local originalShow = MultiCastActionBarFrame.Show
        MultiCastActionBarFrame.Show = function(self)
            if not stanceBarsManuallyHidden then
                originalShow(self)
            end
        end
    end
end

-- Initialize the hooks
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    HookBarFrames()
end)
