local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;

-- const
local PERFORMANCEBAR_LOW_LATENCY = 300;
local PERFORMANCEBAR_MEDIUM_LATENCY = 600;

local MainMenuMicroButtonMixin = {};
local MainMenuBarBackpackButton = _G.MainMenuBarBackpackButton;
local MainMenuMicroButton = _G.MainMenuMicroButton;

local AdventureGuideMicroButton = CreateFrame("Button", "AdventureGuideMicroButton", UIParent)
AdventureGuideMicroButton:SetSize(14, 19)
AdventureGuideMicroButton:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
AdventureGuideMicroButton:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
AdventureGuideMicroButton:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
AdventureGuideMicroButton:SetDisabledTexture("Interface\\Buttons\\WHITE8X8")
AdventureGuideMicroButton:SetScript("OnClick", function()
	local journal = DrakeishUI_SocialNE and DrakeishUI_SocialNE.ej
	if journal and journal.Toggle then journal.Toggle() end
	-- Frame is built lazily; wire + sync after Toggle so open AND close both update art.
	if addon.SyncOpenMicroButtons then addon.SyncOpenMicroButtons() end
end)
AdventureGuideMicroButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Adventure Guide")
	GameTooltip:Show()
end)
AdventureGuideMicroButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
local KeyRingButton = _G.KeyRingButton;

local bagslots = {
    _G.CharacterBag0Slot,
    _G.CharacterBag1Slot,
    _G.CharacterBag2Slot,
    _G.CharacterBag3Slot
};
local MICRO_BUTTONS = {
	_G.CharacterMicroButton,
	_G.SpellbookMicroButton,
	_G.TalentMicroButton,
	_G.AchievementMicroButton,
	_G.CollectionsMicroButton, -- replaces Quest Log (quest log lives on the world map)
	_G.SocialsMicroButton,
	_G.LFDMicroButton,
	_G.PVPMicroButton,
	AdventureGuideMicroButton,
	_G.MainMenuMicroButton,
};
local pUiBagsBar = CreateFrame(
	'Frame',
	'pUiBagsBar',
	UIParent
);
pUiBagsBar:SetScale(config.micromenu.scale_bags);
MainMenuBarBackpackButton:SetParent(pUiBagsBar);
KeyRingButton:SetParent(_G.CharacterBag3Slot);
function MainMenuMicroButtonMixin:bagbuttons_setup()
	MainMenuBarBackpackButton:SetSize(50, 50)
	MainMenuBarBackpackButton:SetNormalTexture(nil)
	MainMenuBarBackpackButton:SetPushedTexture(nil)
	MainMenuBarBackpackButton:SetHighlightTexture''
	MainMenuBarBackpackButton:SetCheckedTexture''
	MainMenuBarBackpackButton:GetHighlightTexture():set_atlas('bag-main-highlight-2x')
	MainMenuBarBackpackButton:GetCheckedTexture():set_atlas('bag-main-highlight-2x')
	MainMenuBarBackpackButtonIconTexture:set_atlas('bag-main-2x')
	MainMenuBarBackpackButton:SetClearPoint('BOTTOMRIGHT', MainMenuMicroButton, 'BOTTOMRIGHT', 0, 30)
	MainMenuBarBackpackButton.SetPoint = addon._noop
	
	MainMenuBarBackpackButtonCount:SetClearPoint('CENTER', MainMenuBarBackpackButton, 'BOTTOM', 0, 14)
	CharacterBag0Slot:SetClearPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', -14, -2)
	
	KeyRingButton:SetSize(34, 34)
	KeyRingButton:SetClearPoint('RIGHT', CharacterBag3Slot, 'LEFT', -2, 0)
	KeyRingButton:SetNormalTexture''
	KeyRingButton:SetPushedTexture(nil)
	KeyRingButton:SetHighlightTexture''
	KeyRingButton:SetCheckedTexture''
	
	local highlight = KeyRingButton:GetHighlightTexture();
	highlight:SetAllPoints();
	highlight:SetBlendMode('ADD');
	highlight:SetAlpha(.4);
	highlight:set_atlas('bag-border-highlight-2x', true)
	KeyRingButton:GetNormalTexture():set_atlas('bag-reagent-border-2x')
	KeyRingButton:GetCheckedTexture():set_atlas('bag-border-highlight-2x', true)
	KeyRingButton:Hide();
	
	for _,bags in pairs(bagslots) do
		bags:SetHighlightTexture''
		bags:SetCheckedTexture''
		bags:SetPushedTexture(nil)
		bags:SetNormalTexture''
		bags:SetSize(28, 28)

		bags:GetCheckedTexture():set_atlas('bag-border-highlight-2x', true)
		bags:GetCheckedTexture():SetDrawLayer('OVERLAY', 7)
		
		local highlight = bags:GetHighlightTexture();
		highlight:SetAllPoints();
		highlight:SetBlendMode('ADD');
		highlight:SetAlpha(.4);
		highlight:set_atlas('bag-border-highlight-2x', true)

		local icon = _G[bags:GetName()..'IconTexture']
		icon:ClearAllPoints()
		icon:SetPoint('TOPRIGHT', bags, 'TOPRIGHT', -5, -2.9);
		icon:SetPoint('BOTTOMLEFT', bags, 'BOTTOMLEFT', 2.9, 5);
		icon:SetTexCoord(.08,.92,.08,.92)
		
		local border = bags:CreateTexture(nil, 'OVERLAY')
		border:SetPoint('CENTER')
		border:set_atlas('bag-border-2x', true)
		bags:GetCheckedTexture():SetAllPoints(border)
		
		local w, h = border:GetSize()
		bags.background = bags:CreateTexture(nil, 'BACKGROUND')
		bags.background:SetSize(w, h)
		bags.background:SetPoint('CENTER')
		bags.background:SetTexture(addon._dir..'bagslots2x')
		bags.background:SetTexCoord(295/512, 356/512, 64/128, 125/128)
		
		local count = _G[bags:GetName()..'Count']
		count:SetClearPoint('CENTER', 0, -10);
		count:SetDrawLayer('OVERLAY')
	end
end

addon.package:RegisterEvents(function(self)
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
	if HasKey() then
		KeyRingButton:Show();
	else
		KeyRingButton:Hide();
	end
	if config.style.bags == 'new' then
		for _,bags in pairs(bagslots) do
			local icon = _G[bags:GetName()..'IconTexture']
			local empty = icon:GetTexture() == 'interface\\paperdoll\\UI-PaperDoll-Slot-Bag'
			if empty then
				icon:SetAlpha(0)
			else
				icon:SetAlpha(1)
			end
		end
	end
end,
	'BAG_UPDATE', 'PLAYER_ENTERING_WORLD'
);

do
	for _,bags in pairs(bagslots) do
		bags:SetParent(pUiBagsBar);
	end
	if config.style.bags == 'new' then
		MainMenuMicroButtonMixin:bagbuttons_setup();
	elseif config.style.bags == 'old' then
		MainMenuBarBackpackButton:SetClearPoint('BOTTOMRIGHT', MainMenuMicroButton, 'BOTTOMRIGHT', 0, 34)
		MainMenuBarBackpackButtonIconTexture:SetTexture(addon._dir..'INV_Misc_Bag_08')
		CharacterBag0Slot:SetClearPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', -20, 0)
	else
		MainMenuBarBackpackButton:Hide();
		for _,bags in pairs(bagslots) do
			bags:Hide();
		end
	end
end

-- GameMenuFrame_OnShow calls Disable_BagButtons, which desaturates the backpack.
-- Keep the bag art full color while the game menu is open.
local function RestoreBagButtons()
	local function undesaturate(tex)
		if not tex then return end
		if SetDesaturation then SetDesaturation(tex, nil) end
		if tex.SetDesaturated then tex:SetDesaturated(false) end
		if tex.SetVertexColor then tex:SetVertexColor(1, 1, 1) end
	end
	if MainMenuBarBackpackButton then
		MainMenuBarBackpackButton:Enable()
		undesaturate(_G.MainMenuBarBackpackButtonIconTexture)
	end
	for _, bags in pairs(bagslots) do
		if bags.Enable then bags:Enable() end
		undesaturate(_G[bags:GetName() .. "IconTexture"])
	end
end
if type(Disable_BagButtons) == "function" then
	hooksecurefunc("Disable_BagButtons", RestoreBagButtons)
end

-- Make arrow accessible outside the do block
local arrow
do
	local old = config.style.bags == 'old'
	arrow = CreateFrame('CheckButton', 'pUiArrowManager', MainMenuBarBackpackButton)
	arrow:SetSize(12, 18)
	arrow:SetPoint('RIGHT', MainMenuBarBackpackButton, 'LEFT', old and -4 or 0, -2)
	arrow:SetAlpha(0.3)
	arrow:SetNormalTexture''
	arrow:SetPushedTexture''
	arrow:SetHighlightTexture''
	arrow:RegisterForClicks('LeftButtonUp')

	local normal = arrow:GetNormalTexture()
	normal:set_atlas('bag-arrow-2x')

	local pushed = arrow:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = arrow:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')

	arrow:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		if checked then
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			for _,bags in pairs(bagslots) do bags:Show(); end
		else
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			for _,bags in pairs(bagslots) do bags:Hide(); end
		end
		collapse_state = checked and 1 or 0
	end)
	
	-- Add mouseover effects to match other toggle button
	arrow:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	arrow:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not collapse_state then collapse_state = 0 end
		if collapse_state == 1 then
			for _,bags in pairs(bagslots) do bags:Show(); end
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			arrow:SetChecked(1)
		else
			for _,bags in pairs(bagslots) do bags:Hide(); end
			arrow:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end

-- Dungeon finder eye sits on the minimap ring, same size as the other minimap icons,
-- with the shared yellow circle. The flipbook art only fills the middle of each cell,
-- so the eye frame is larger than the button and the ring draws in the padding.
local function PlaceMinimapLFG()
	local f = MiniMapLFGFrame
	if not f then return end
	f:SetParent(Minimap)
	f:SetScale(1)
	f:SetSize(21, 21)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
	f:SetClearPoint("CENTER", Minimap, "LEFT", 0, -20)

	local border = _G.MiniMapLFGFrameBorder
	if border then
		border:SetTexture(addon._dir .. "border_buttons.tga")
		border:ClearAllPoints()
		border:SetPoint("CENTER", f, "CENTER", 0, 0)
		border:SetSize(23, 23)
		border:SetDrawLayer("OVERLAY")
		border:Show()
	end

	local eye = f.eye
	if eye then
		if eye.SetSize then eye:SetSize(26, 26) end
		if eye.ClearAllPoints then
			eye:ClearAllPoints()
			eye:SetPoint("CENTER", f, "CENTER", 0, 0)
		end
		if eye.texture then
			eye.texture:SetTexture(addon._dir .. "uigroupfinderflipbookeye.tga")
			eye.texture:ClearAllPoints()
			eye.texture:SetSize(26, 26)
			eye.texture:SetPoint("CENTER", f, "CENTER", 0, 0)
		end
	end
end

hooksecurefunc("MiniMapLFG_UpdateIsShown", PlaceMinimapLFG)
PlaceMinimapLFG()

MiniMapLFGFrame:SetScript('OnClick',function(self, button)
	local mode, submode = GetLFGMode();
	if ( button == "RightButton" or mode == "lfgparty" or mode == "abandonedInDungeon") then
		PlaySound("igMainMenuOpen");
		local yOffset;
		if ( mode == "queued" ) then
			MiniMapLFGFrameDropDown.point = "BOTTOMRIGHT";
			MiniMapLFGFrameDropDown.relativePoint = "TOPLEFT";
			yOffset = 105;
		else
			MiniMapLFGFrameDropDown.point = nil;
			MiniMapLFGFrameDropDown.relativePoint = nil;
			yOffset = 110;
		end
		ToggleDropDownMenu(1, nil, MiniMapLFGFrameDropDown, "MiniMapLFGFrame", -60, yOffset);
	elseif ( mode == "proposal" ) then
		if ( not LFDDungeonReadyPopup:IsShown() ) then
			PlaySound("igCharacterInfoTab");
			StaticPopupSpecial_Show(LFDDungeonReadyPopup);
		end
	elseif ( mode == "queued" or mode == "rolecheck" ) then
		ToggleLFDParentFrame();
	elseif ( mode == "listed" ) then
		ToggleLFRParentFrame();
	end
end)

LFDSearchStatus:SetParent(MinimapBackdrop)
LFDSearchStatus:SetClearPoint('TOPRIGHT', MinimapBackdrop, 'TOPLEFT')

hooksecurefunc('CharacterMicroButton_SetPushed',function()
	MicroButtonPortrait:SetTexCoord(0,0,0,0);
	MicroButtonPortrait:SetAlpha(0);
end)

hooksecurefunc('CharacterMicroButton_SetNormal',function()
	MicroButtonPortrait:SetTexCoord(0,0,0,0);
	MicroButtonPortrait:SetAlpha(0);
end)

function MainMenuMicroButtonMixin:OnUpdate(elapsed)
	local _, _, latencyHome = GetNetStats();
	local latency = latencyHome;
	if ( latency > PERFORMANCEBAR_MEDIUM_LATENCY ) then
		self:SetStatusBarColor(1, 0, 0);
	elseif ( latency > PERFORMANCEBAR_LOW_LATENCY ) then
		self:SetStatusBarColor(1, 1, 0);
	else
		self:SetStatusBarColor(0, 1, 0);
	end
end

function MainMenuMicroButtonMixin:CreateBar()
	local latencybar = CreateFrame('Statusbar', nil, UIParent)
	latencybar:SetParent(MainMenuMicroButton)
	latencybar:SetSize(14, 39)
	latencybar:SetPoint('BOTTOM', MainMenuMicroButton, 'BOTTOM', 0, -4)
	latencybar:SetStatusBarTexture(addon._dir..'ui-mainmenubar-performancebar')
	latencybar:SetStatusBarColor(1, 1, 0)
	latencybar:GetStatusBarTexture():SetBlendMode('ADD')
	latencybar:GetStatusBarTexture():SetDrawLayer('OVERLAY')
	latencybar:SetScript('OnUpdate', MainMenuMicroButtonMixin.OnUpdate)
end
MainMenuMicroButtonMixin:CreateBar();

local function setupMicroButtons(xOffset)
	local buttonxOffset = 0
	local menu = CreateFrame('Frame', 'pUiMicroMenu', UIParent)
	menu:SetScale(config.micromenu.scale_menu)
	menu:SetSize(10, 10)
	menu:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMRIGHT', xOffset-2, config.micromenu.y_position)

	-- Quest log is on the map; keep Blizzard's micro button permanently out of the strip.
	if QuestLogMicroButton then
		QuestLogMicroButton:Hide()
		QuestLogMicroButton:UnregisterAllEvents()
		QuestLogMicroButton:SetParent(UIParent)
		QuestLogMicroButton:ClearAllPoints()
		QuestLogMicroButton:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -5000, 0)
		hooksecurefunc(QuestLogMicroButton, 'Show', function(self) self:Hide() end)
	end
	if HelpMicroButton then
		HelpMicroButton:Hide()
		HelpMicroButton:UnregisterAllEvents()
		HelpMicroButton:SetParent(UIParent)
		HelpMicroButton:ClearAllPoints()
		HelpMicroButton:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -5000, 0)
		hooksecurefunc(HelpMicroButton, 'Show', function(self) self:Hide() end)
	end

	for _,button in pairs(MICRO_BUTTONS) do
		if not button or button.drakeishUISuppressed then
			-- skip
		else
		local buttonName = button:GetName():gsub('MicroButton', '')
		local name = strlower(buttonName);
		button._drakeishMicroName = name

		button:texture_strip()

		-- TalentMicroButtonFlash is a separate ADD texture; leave it cleared so it
		-- cannot cover the real highlight (same idea as stripping other regions).
		if button == _G.TalentMicroButton and _G.TalentMicroButtonFlash then
			_G.TalentMicroButtonFlash:SetTexture(nil)
			_G.TalentMicroButtonFlash:Hide()
		end

		CharacterMicroButton:SetDisabledTexture'' -- doesn't exist by default
		PVPMicroButton:SetDisabledTexture'' -- doesn't exist by default
		PVPMicroButton:GetDisabledTexture():set_atlas('ui-hud-micromenu-pvp-disabled-2x')

		button:SetParent(pUiMicroMenu)
		-- button:SetScale(1.4)
		button:SetSize(14, 19)
		button:SetClearPoint('BOTTOMLEFT', pUiMicroMenu, 'BOTTOMRIGHT', buttonxOffset, 55)
		button.SetPoint = addon._noop
		button:SetHitRectInsets(0,0,0,0)

		-- Ensure texture slots exist before atlas (custom buttons / stripped regions).
		button:SetNormalTexture''
		button:SetPushedTexture''
		button:SetDisabledTexture''
		button:GetNormalTexture():set_atlas('ui-hud-micromenu-'..name..'-up-2x')
		button:GetPushedTexture():set_atlas('ui-hud-micromenu-'..name..'-down-2x')
		button:GetDisabledTexture():set_atlas('ui-hud-micromenu-'..name..'-disabled-2x')
		-- Same pattern as bag buttons: reset highlight slot, atlas, ADD, pin to button
		button:SetHighlightTexture''
		local highlight = button:GetHighlightTexture()
		highlight:set_atlas('ui-hud-micromenu-'..name..'-mouseover-2x')
		highlight:SetBlendMode('ADD')
		highlight:ClearAllPoints()
		highlight:SetAllPoints(button)

		-- Talent: keep binding tooltip text fresh and use an OnEnter that works when
		-- IsEnabled() returns a boolean (ClassicAPI) instead of 1/0 (stock XML used == 1).
		if button == _G.TalentMicroButton then
			local function refreshTalentTip()
				if MicroButtonTooltipText then
					button.tooltipText = MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS")
				else
					button.tooltipText = TALENTS_BUTTON or "Talents"
				end
				button.newbieText = NEWBIE_TOOLTIP_TALENTS or button.newbieText
			end
			refreshTalentTip()
			button:SetScript("OnEnter", function(self)
				refreshTalentTip()
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				if GameTooltip_AddNewbieTip then
					GameTooltip_AddNewbieTip(self, self.tooltipText, 1.0, 1.0, 1.0, self.newbieText)
				else
					GameTooltip:SetText(self.tooltipText or TALENTS_BUTTON or "Talents", 1, 1, 1)
					if self.newbieText then
						GameTooltip:AddLine(self.newbieText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
					end
					GameTooltip:Show()
				end
			end)
			button:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		buttonxOffset = buttonxOffset + 15
		end
	end
end

addon.package:RegisterEvents(function()
	local xOffset = -166
	if _G.CollectionsMicroButton and not _G.CollectionsMicroButton.drakeishUISuppressed then
		-- same width as the old 10-button strip (quest log slot reused by collections)
		xOffset = -166
	end
	setupMicroButtons(xOffset + config.micromenu.x_position);
	if config.micromenu.hide_on_vehicle then
		RegisterStateDriver(pUiMicroMenu, 'visibility', '[vehicleui] hide;show')
		RegisterStateDriver(pUiBagsBar, 'visibility', '[vehicleui] hide;show')
	else
		UnregisterStateDriver(pUiMicroMenu, 'visibility')
		UnregisterStateDriver(pUiBagsBar, 'visibility')
	end
end, 'PLAYER_LOGIN'
);


-- Store reference to arrow for use in toggle
local pUiArrowToggleButton = nil -- we’ll assign it later



local bagsToggleButton
do
	bagsToggleButton = CreateFrame('CheckButton', 'bagstoggle', UIParent)
	bagsToggleButton:SetSize(10, 14)
	bagsToggleButton:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", -2, 57)
	bagsToggleButton:SetParent(UIParent)
	bagsToggleButton:SetAlpha(0.3)
	bagsToggleButton:SetNormalTexture''
	bagsToggleButton:SetPushedTexture''
	bagsToggleButton:SetHighlightTexture''
	bagsToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = bagsToggleButton:GetNormalTexture()
	normal:set_atlas('bag-arrow-invert-2x')

	local pushed = bagsToggleButton:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = bagsToggleButton:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-invert-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	bagsToggleButton:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		-- Update state first so Show/Hide hooks see the correct value
		bags_state = checked and 1 or 0
		if checked then
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			MainMenuBarBackpackButton:Hide()
			-- Hide micromenu buttons
			for _, button in pairs(MICRO_BUTTONS) do
				if button then button:Hide() end
			end
			
			-- Hide bags only if they are currently expanded (collapse_state == 1)
			if collapse_state == 1 then
				for _, bag in pairs(bagslots) do
					bag:Hide()
				end
			end
		else
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			MainMenuBarBackpackButton:Show()
			-- Show micromenu buttons
			for _, button in pairs(MICRO_BUTTONS) do
				if button then button:Show() end
			end
			
			-- Show bags only if they are currently expanded (collapse_state == 1)
			if collapse_state == 1 then
				for _, bag in pairs(bagslots) do
					bag:Show()
				end
			end
		end
	end)
	
	-- Add mouseover effects to match other toggle button
	bagsToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	bagsToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	-- Blizzard (esp. TalentMicroButton via UpdateMicroButtons) re-Shows buttons;
	-- keep them hidden while micromenu toggle is off.
	local function EnforceMicroMenuHidden()
		if bags_state ~= 1 then return end
		for _, button in pairs(MICRO_BUTTONS) do
			if button and button:IsShown() then
				button:Hide()
			end
		end
	end

	for _, button in pairs(MICRO_BUTTONS) do
		if button then
			hooksecurefunc(button, 'Show', function(self)
				if bags_state == 1 then
					self:Hide()
				end
			end)
		end
	end

	if UpdateMicroButtons then
		hooksecurefunc('UpdateMicroButtons', EnforceMicroMenuHidden)
	end
	if UpdateMicroButtonsParent then
		hooksecurefunc('UpdateMicroButtonsParent', EnforceMicroMenuHidden)
	end

	-- Stock UpdateMicroButtons only knows FriendsFrame / LFDParentFrame / PlayerTalentFrame /
	-- PVPParentFrame. Social, LFG, Adventure Guide, and PvP use custom DrakeishUI frames. Also:
	-- atlas-skinned NormalTextures do not always follow SetButtonState on this client (Talent),
	-- so paint the down/up atlas onto NormalTexture explicitly while the panel is open.
	local function IsBtnEnabled(button)
		if not button or not button.IsEnabled then return false end
		local e = button:IsEnabled()
		return e == 1 or e == true
	end

	local function ApplyMicroOpenArt(button, open)
		if not button or not button._drakeishMicroName then return end
		local name = button._drakeishMicroName
		local suffix = open and '-down-2x' or '-up-2x'
		local nt = button:GetNormalTexture()
		if nt and nt.set_atlas then
			nt:set_atlas('ui-hud-micromenu-' .. name .. suffix)
		end
		-- Always refresh the pushed slot too — some clients keep showing Normal while locked.
		local pt = button:GetPushedTexture()
		if pt and pt.set_atlas then
			pt:set_atlas('ui-hud-micromenu-' .. name .. '-down-2x')
		end
		if open then
			button:SetButtonState("PUSHED", 1)
		else
			button:SetButtonState("NORMAL")
		end
	end

	local WireOpenState, WireKnownOpenFrames

	local function SyncOpenMicroButtons()
		-- Wire lazily-created frames (Adventure Guide / Talent) so close/hide clears art too.
		WireKnownOpenFrames()

		local social = _G.DrakeishUI_Social_FriendsFrame
		if SocialsMicroButton then
			ApplyMicroOpenArt(SocialsMicroButton, social and social:IsShown())
		end

		local lfg = _G.DrakeishUI_Social_GroupFinderFrame
		if LFDMicroButton and IsBtnEnabled(LFDMicroButton) then
			ApplyMicroOpenArt(LFDMicroButton, lfg and lfg:IsShown())
		end

		local journal = _G.DrakeishUI_Social_EncounterJournal
		if AdventureGuideMicroButton then
			ApplyMicroOpenArt(AdventureGuideMicroButton, journal and journal:IsShown())
		end

		local pvp = _G.DrakeishUI_Social_PVPFrame
		if PVPMicroButton and IsBtnEnabled(PVPMicroButton) then
			ApplyMicroOpenArt(PVPMicroButton, pvp and pvp:IsShown())
		end

		if TalentMicroButton and IsBtnEnabled(TalentMicroButton) then
			local talentOpen = PlayerTalentFrame and PlayerTalentFrame:IsShown()
			ApplyMicroOpenArt(TalentMicroButton, talentOpen and true or false)
		end
	end
	addon.SyncOpenMicroButtons = SyncOpenMicroButtons

	local function RefreshMicroButtons()
		if UpdateMicroButtons then UpdateMicroButtons() end
		SyncOpenMicroButtons()
	end

	function WireOpenState(frame)
		if not frame or frame._drakeishMicroOpenWired then return end
		frame._drakeishMicroOpenWired = true
		frame:HookScript("OnShow", function()
			SyncOpenMicroButtons()
			-- Talent UIPanel show can lag one frame behind the click.
			if C_Timer and C_Timer.After then
				C_Timer.After(0, SyncOpenMicroButtons)
			end
		end)
		frame:HookScript("OnHide", function()
			SyncOpenMicroButtons()
			if C_Timer and C_Timer.After then
				C_Timer.After(0, SyncOpenMicroButtons)
			end
		end)
	end

	function WireKnownOpenFrames()
		WireOpenState(_G.DrakeishUI_Social_FriendsFrame)
		WireOpenState(_G.DrakeishUI_Social_GroupFinderFrame)
		WireOpenState(_G.DrakeishUI_Social_EncounterJournal)
		WireOpenState(_G.DrakeishUI_Social_PVPFrame)
		WireOpenState(_G.PlayerTalentFrame)
	end

	if UpdateMicroButtons then
		hooksecurefunc('UpdateMicroButtons', function()
			WireKnownOpenFrames()
			SyncOpenMicroButtons()
		end)
	end

	if type(TalentFrame_LoadUI) == "function" then
		hooksecurefunc("TalentFrame_LoadUI", function()
			WireOpenState(_G.PlayerTalentFrame)
			if C_Timer and C_Timer.After then
				C_Timer.After(0, SyncOpenMicroButtons)
			end
		end)
	end

	-- Talent panel is a UIPanel — catch show/hide even when OnShow wiring races LoadUI.
	if type(ShowUIPanel) == "function" then
		hooksecurefunc("ShowUIPanel", function(frame)
			if frame and frame == _G.PlayerTalentFrame then
				WireOpenState(frame)
				SyncOpenMicroButtons()
				if C_Timer and C_Timer.After then
					C_Timer.After(0, SyncOpenMicroButtons)
				end
			end
		end)
	end
	if type(HideUIPanel) == "function" then
		hooksecurefunc("HideUIPanel", function(frame)
			if frame and frame == _G.PlayerTalentFrame then
				SyncOpenMicroButtons()
				if C_Timer and C_Timer.After then
					C_Timer.After(0, SyncOpenMicroButtons)
				end
			end
		end)
	end

	if TalentMicroButton then
		TalentMicroButton:HookScript("OnClick", function()
			WireOpenState(_G.PlayerTalentFrame)
			SyncOpenMicroButtons()
			if C_Timer and C_Timer.After then
				C_Timer.After(0, SyncOpenMicroButtons)
			end
		end)
	end

	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		WireKnownOpenFrames()
		SyncOpenMicroButtons()
	end, 'PLAYER_LOGIN')
	
	addon.package:RegisterEvents(function(self, event)
		self:UnregisterEvent(event)
		if not bags_state then bags_state = 0 end
		if bags_state == 1 then
		    MainMenuBarBackpackButton:Hide()
			-- Hide micromenu buttons
			for _, button in pairs(MICRO_BUTTONS) do
				if button then button:Hide() end
			end
			
			-- Hide bags only if they are currently expanded (collapse_state == 1)
			if collapse_state == 1 then
				for _, bag in pairs(bagslots) do
					bag:Hide()
				end
			end
			
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			bagsToggleButton:SetChecked(1)
		else
		    MainMenuBarBackpackButton:Show()
			-- Show micromenu buttons
			for _, button in pairs(MICRO_BUTTONS) do
				if button then button:Show() end
			end
			
			-- Show bags only if they are currently expanded (collapse_state == 1)
			if collapse_state == 1 then
				for _, bag in pairs(bagslots) do
					bag:Show()
				end
			end
			
			bagsToggleButton:SetChecked(nil)
		end
	end, 'PLAYER_LOGIN'
	);
end
