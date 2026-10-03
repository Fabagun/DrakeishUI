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
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
		addon.SetEndCapBasePoints(-85, 84, -22)
	elseif config.style.gryphons == 'new' then
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
		addon.SetEndCapBasePoints(-95, 95, -23)
	elseif config.style.gryphons == 'flying' then
		-- Always show Alliance gryphon on left, Horde wyvern on right
		MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
		MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
		addon.SetEndCapBasePoints(-80, 80, -21)
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
	for _,bar in pairs({MainMenuExpBar, ReputationWatchStatusBar}) do
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

	-- Rep fill max is 2px short of the shared bar width (right edge only)
	if new then
		ReputationWatchStatusBar:SetWidth(535)
	end
	
	-- Default: XP above reputation; ReputationWatchBar_Update / actionbar_update refine this
	MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 3, 22)
	MainMenuExpBar:SetFrameLevel(10)
	ReputationWatchBar:SetParent(pUiMainBar)
	ReputationWatchBar:SetFrameLevel(10)
	ReputationWatchBar:SetWidth(537)
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

-- High-contrast azure XP fill (rested uses a slightly brighter tint)
local XP_FILL_AZURE = { 0.0, 0.72, 1.0, 1.0 }
local XP_FILL_AZURE_RESTED = { 0.15, 0.82, 1.0, 1.0 }

-- Standard WoW standing hues, boosted for contrast/vibrancy
-- 1 Hated, 2 Hostile, 3 Unfriendly, 4 Neutral, 5 Friendly, 6 Honored, 7 Revered, 8 Exalted
local REP_FILL_COLORS = {
	[1] = { 1.00, 0.18, 0.18 }, -- Hated (red)
	[2] = { 1.00, 0.42, 0.08 }, -- Hostile (orange-red)
	[3] = { 1.00, 0.62, 0.12 }, -- Unfriendly (orange)
	[4] = { 1.00, 0.95, 0.12 }, -- Neutral (yellow)
	[5] = { 0.18, 0.92, 0.22 }, -- Friendly (green)
	[6] = { 0.12, 0.55, 1.00 }, -- Honored (blue)
	[7] = { 0.78, 0.28, 1.00 }, -- Revered (purple)
	[8] = { 1.00, 0.86, 0.22 }, -- Exalted (gold)
}

local function ApplyXpBarFillColor()
	if not new then return end
	local exhaustionStateID = GetRestState()
	local c = (exhaustionStateID == 1) and XP_FILL_AZURE_RESTED or XP_FILL_AZURE
	MainMenuExpBar:SetStatusBarTexture(addon._dir..'statusbarfill.tga')
	MainMenuExpBar:SetStatusBarColor(c[1], c[2], c[3], c[4])
	local tex = MainMenuExpBar:GetStatusBarTexture()
	if tex then
		tex:SetTexCoord(0, 1, 0, 1)
		tex:SetVertexColor(c[1], c[2], c[3], c[4])
	end
end

local function ApplyRepBarFillColor()
	if not new then return end
	local name, reaction = GetWatchedFactionInfo()
	if not name or not reaction then return end
	local c = REP_FILL_COLORS[reaction] or REP_FILL_COLORS[4]
	ReputationWatchStatusBar:SetStatusBarTexture(addon._dir..'statusbarfill.tga')
	ReputationWatchStatusBar:SetStatusBarColor(c[1], c[2], c[3], 1)
	local tex = ReputationWatchStatusBar:GetStatusBarTexture()
	if tex then
		tex:SetTexCoord(0, 1, 0, 1)
		tex:SetVertexColor(c[1], c[2], c[3], 1)
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

		ApplyXpBarFillColor()
		ApplyRepBarFillColor()
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
			ExhaustionLevelFillBar:SetVertexColor(0.0, 0.55, 1.0, 0.45);
		elseif exhaustionStateID == 2 then
			ExhaustionLevelFillBar:SetVertexColor(0.0, 0.45, 0.9, 0.35);
		end
	else
		if exhaustionStateID == 1 then
			ExhaustionTick:Show();
		end
	end
end,
	'PLAYER_ENTERING_WORLD',
	'UPDATE_EXHAUSTION',
	'PLAYER_XP_UPDATE',
	'UPDATE_FACTION'
);

local both = config.xprepbar.bothbar_offset;
local single = config.xprepbar.singlebar_offset;
local nobar	= config.xprepbar.nobar_offset;
local abovexp = config.xprepbar.repbar_abovexp_offset;
local default = config.xprepbar.repbar_offset;

-- Bottom stack: rep at y=3 (when tracked), XP above it at y=22.
-- When no reputation is tracked, XP drops to y=3 and the main bar uses singlebar_offset
-- so action / stance / pet bars follow downward.
local XP_BAR_Y_WITH_REP = 22
local XP_BAR_Y_ALONE = 3
local REP_BAR_Y = 3

-- End caps stay at the screen Y of the bothbar layout while the main bar moves
local mainBarYOffset = both
local endCapLeftX, endCapRightX, endCapBaseY = -95, 95, -23

local function RefreshEndCapPositions()
	if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return end
	local y = endCapBaseY + (both - mainBarYOffset)
	MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', endCapLeftX, y)
	MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', endCapRightX, y)
end

function addon.SetEndCapBasePoints(leftX, rightX, baseY)
	endCapLeftX, endCapRightX, endCapBaseY = leftX, rightX, baseY
	RefreshEndCapPositions()
end

addon.RefreshEndCapPositions = RefreshEndCapPositions

local function StatusBars_UpdateLayout()
	local watchedName = GetWatchedFactionInfo()
	local xpShown = MainMenuExpBar:IsShown()
	-- Blizzard shows ReputationWatchBar when a faction is watched
	local repShown = watchedName ~= nil

	if xpShown and repShown then
		MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 3, XP_BAR_Y_WITH_REP)
		ReputationWatchBar:SetClearPoint('BOTTOM', UIParent, 3, REP_BAR_Y)
		if ReputationWatchBarOverlayFrame then
			ReputationWatchBarOverlayFrame:SetClearPoint('BOTTOM', UIParent, 3, REP_BAR_Y)
		end
		ReputationWatchStatusBar:SetHeight(10)
		ReputationWatchStatusBar:SetWidth(535)
		ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)
		ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, old and 0 or 1)
		ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
		mainBarYOffset = both
		pUiMainBar:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, both)
	elseif xpShown then
		-- No tracked reputation: XP occupies the lower slot
		MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 3, XP_BAR_Y_ALONE)
		mainBarYOffset = single
		pUiMainBar:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, single)
	elseif repShown then
		-- Max level (or XP hidden) with reputation tracked
		ReputationWatchBar:SetClearPoint('BOTTOM', UIParent, 3, REP_BAR_Y)
		if ReputationWatchBarOverlayFrame then
			ReputationWatchBarOverlayFrame:SetClearPoint('BOTTOM', UIParent, 3, REP_BAR_Y)
		end
		ReputationWatchStatusBar:SetHeight(10)
		ReputationWatchStatusBar:SetWidth(535)
		ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)
		ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, old and 0 or 1)
		ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
		mainBarYOffset = single
		pUiMainBar:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, single)
	else
		mainBarYOffset = nobar
		pUiMainBar:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, nobar)
	end

	RefreshEndCapPositions()

	-- Stance / pet anchors are relative to pUiMainBar; refresh their stacked offsets
	if pUiStanceHolder and pUiStanceHolder.stancebar_update then
		pUiStanceHolder:stancebar_update()
	end
	if pUiPetBarHolder and pUiPetBarHolder.petbar_update then
		pUiPetBarHolder:petbar_update()
	end
end

hooksecurefunc('ReputationWatchBar_Update', function()
	StatusBars_UpdateLayout()
	ApplyRepBarFillColor()
end)

function pUiMainBar:actionbar_update()
	StatusBars_UpdateLayout()
end

event:RegisterEvents(function()
	pUiMainBar:actionbar_update();
end,
	'PLAYER_LOGIN','ADDON_LOADED','PLAYER_LEVEL_UP','UPDATE_EXHAUSTION','PLAYER_XP_UPDATE'
);

for _,bar in pairs({MainMenuExpBar, ReputationWatchBar}) do
	bar:HookScript('OnShow', function()
		StatusBars_UpdateLayout()
	end)
	bar:HookScript('OnHide', function()
		StatusBars_UpdateLayout()
	end)
end

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
	capsToggleButton:SetFrameStrata('TOOLTIP')
	capsToggleButton:SetFrameLevel(2000)
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
		caps_state = checked and 1 or 0
		
		if checked then
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - caps are hidden)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
		else
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
		end
		
		-- Apply gryphon style to handle both gryphons and angel/demon state
		-- This ensures that when state is 4 (angel/demon), the artwork is shown/hidden correctly
		if _G.ApplyGryphonStyle then
			local style = _G.gryphon_style_state or gryphon_style_state or 1
			_G.ApplyGryphonStyle(style)
		else
			-- Fallback to simple gryphon toggle if ApplyGryphonStyle is not available
			if checked then
				MainMenuBarLeftEndCap:Show()
				MainMenuBarRightEndCap:Show()
			else
				MainMenuBarLeftEndCap:Hide()
				MainMenuBarRightEndCap:Hide()
			end
		end
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
		if not caps_state then caps_state = 1 end  -- Default to visible (1) when no variables saved
		if caps_state == 1 then
			normal:SetTexCoord(0, 0.5, 0, 1)  -- Left half (up arrow - caps are hidden)
			pushed:SetTexCoord(0, 0.5, 0, 1)
			highlight:SetTexCoord(0, 0.5, 0, 1)
			capsToggleButton:SetChecked(1)
		else
			normal:SetTexCoord(0.5, 1, 0, 1)  -- Right half (down arrow - caps are visible)
			pushed:SetTexCoord(0.5, 1, 0, 1)
			highlight:SetTexCoord(0.5, 1, 0, 1)
			capsToggleButton:SetChecked(nil)
		end
		
		-- Apply gryphon style to handle both gryphons and angel/demon state
		-- This ensures that when state is 4 (angel/demon), the artwork is shown/hidden correctly
		if _G.ApplyGryphonStyle then
			local style = _G.gryphon_style_state or gryphon_style_state or 1
			_G.ApplyGryphonStyle(style)
		else
			-- Fallback to simple gryphon toggle if ApplyGryphonStyle is not available
			if caps_state == 1 then
				MainMenuBarLeftEndCap:Show()
				MainMenuBarRightEndCap:Show()
			else
				MainMenuBarLeftEndCap:Hide()
				MainMenuBarRightEndCap:Hide()
			end
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
	stanceToggleButton:SetFrameStrata('TOOLTIP')
	stanceToggleButton:SetFrameLevel(2000)
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
		if not stance_state then stance_state = 1 end  -- Default to visible (1) when no variables saved
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
