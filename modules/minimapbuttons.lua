local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


-- MinimapButtons.lua - Step-by-step development

-- Store detected and hidden buttons
local DetectedButtons = {}
local HiddenButtons = {}

-- Button state
local ShowTimeout = -1
local IsShowing = false

-- Modern circular border (same art DragonUI uses for minimap addon icons)
local BORDER_TEX = "Interface\\AddOns\\DrakeishUI\\assets\\border_buttons"
local BORDER_SIZE = 23
local BUTTON_SIZE = 21

local SKIP_SKIN = {
	Minimap = true,
	MinimapBackdrop = true,
	MinimapCluster = true,
	MinimapButtonsToggleButton = true,
	MiniMapMailFrame = true,
	MiniMapMailButton = true,
	MinimapZoomIn = true,
	MinimapZoomOut = true,
	MiniMapWorldMapButton = true,
	MiniMapTracking = true,
	MiniMapTrackingButton = true,
	MiniMapTrackingFrame = true,
	TimeManagerClockButton = true,
	GameTimeFrame = true,
	MiniMapLFGFrame = true,
}

local function ShouldSkipSkin(button)
	if not button then
		return true
	end
	local ot = button:GetObjectType()
	if ot ~= "Button" and ot ~= "CheckButton" and ot ~= "Frame" then
		return true
	end
	local name = button:GetName()
	if name and SKIP_SKIN[name] then
		return true
	end
	if name and (name:find("DrakeishUI") or name:find("customMail") or name:find("CustomMail")) then
		return true
	end
	if button.GetWidth and button:GetWidth() > 80 then
		return true
	end
	return false
end

local function IsProtectedIconRegion(button, region)
	if not region then return false end
	if button.GetNormalTexture and region == button:GetNormalTexture() then return true end
	if button.GetPushedTexture and region == button:GetPushedTexture() then return true end
	if button.GetCheckedTexture and region == button:GetCheckedTexture() then return true end
	if button.icon == region or button.Icon == region or button.texture == region then return true end
	local tex = region:GetTexture()
	local s = tex and tostring(tex) or ""
	if s:find("Interface\\Icons") or s:find("Interface\\Spellbook") or s:find("Icons\\") then
		return true
	end
	-- Artwork is almost always the icon; don't hide it
	if region:GetDrawLayer() == "ARTWORK" then
		return true
	end
	return false
end

local function IsDecoTexture(region, button)
	if not region or region:GetObjectType() ~= "Texture" then
		return false
	end
	if region == button.drakeishCircle then
		return false
	end
	if region:GetDrawLayer() == "HIGHLIGHT" then
		return false
	end
	if IsProtectedIconRegion(button, region) then
		return false
	end
	local tex = region:GetTexture()
	local texStr = tex and tostring(tex) or ""
	-- Only hide clear classic border / mask art (no size heuristic — that hid racial icons)
	if texStr:find("TrackingBorder") or texStr:find("MiniMap%-TrackingBorder")
		or texStr:find("UI%-Minimap%-ZoomButton") or texStr:find("AlphaMask")
		or texStr:find("Minimap%-TrackingBorder") then
		return true
	end
	if texStr:find("Border") or texStr:find("Background") then
		return true
	end
	-- OVERLAY ring larger than the button (classic border pattern)
	if region:GetDrawLayer() == "OVERLAY" then
		local rw, rh = region:GetWidth() or 0, region:GetHeight() or 0
		local bw = button.DrakeishUI_OrigW or button:GetWidth() or 0
		local bh = button.DrakeishUI_OrigH or button:GetHeight() or 0
		if bw > 0 and bh > 0 and (rw >= bw + 8 or rh >= bh + 8) then
			return true
		end
	end
	return false
end

local function CollectTextures(button, list)
	for i = 1, button:GetNumRegions() do
		local region = select(i, button:GetRegions())
		if region and region:GetObjectType() == "Texture" then
			list[#list + 1] = region
		end
	end
	if button.GetChildren then
		local children = { button:GetChildren() }
		for _, child in ipairs(children) do
			if child and child.GetNumRegions then
				for i = 1, child:GetNumRegions() do
					local region = select(i, child:GetRegions())
					if region and region:GetObjectType() == "Texture" then
						list[#list + 1] = region
					end
				end
			end
		end
	end
	-- Explicit icon fields some custom buttons use
	if button.icon and button.icon.GetObjectType and button.icon:GetObjectType() == "Texture" then
		list[#list + 1] = button.icon
	end
	if button.Icon and button.Icon.GetObjectType and button.Icon:GetObjectType() == "Texture" then
		list[#list + 1] = button.Icon
	end
end

-- Apply DragonUI-style modern icon border (hide classic border, add circle overlay)
function DrakeishUI_SkinMinimapButton(button)
	if ShouldSkipSkin(button) then
		return
	end

	if not button.DrakeishUI_OrigW then
		button.DrakeishUI_OrigW, button.DrakeishUI_OrigH = button:GetWidth(), button:GetHeight()
	end

	local all = {}
	CollectTextures(button, all)

	button.DrakeishUI_DecoRegions = {}
	button.DrakeishUI_IconRegions = {}
	for _, region in ipairs(all) do
		if region == button.drakeishCircle then
			-- skip
		elseif IsDecoTexture(region, button) then
			table.insert(button.DrakeishUI_DecoRegions, region)
		elseif region:GetDrawLayer() ~= "HIGHLIGHT" then
			table.insert(button.DrakeishUI_IconRegions, region)
		end
	end

	-- Always keep normal/pushed/icon fields as icons
	local forced = {
		button.GetNormalTexture and button:GetNormalTexture(),
		button.GetPushedTexture and button:GetPushedTexture(),
		button.icon,
		button.Icon,
	}
	for _, region in ipairs(forced) do
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then
			local found = false
			for _, r in ipairs(button.DrakeishUI_IconRegions) do
				if r == region then found = true break end
			end
			if not found then
				table.insert(button.DrakeishUI_IconRegions, region)
			end
			-- ensure not stuck hidden from a previous bad skin
			region:SetAlpha(1)
		end
	end

	if not button.drakeishCircle then
		button.drakeishCircle = button:CreateTexture(nil, "OVERLAY")
		button.drakeishCircle:SetTexture(BORDER_TEX)
		button.drakeishCircle:SetPoint("CENTER", button, "CENTER", 0, 0)
	end
	button.DrakeishUI_Skinned = true

	button:SetWidth(BUTTON_SIZE)
	button:SetHeight(BUTTON_SIZE)

	for _, region in ipairs(button.DrakeishUI_DecoRegions) do
		region:SetAlpha(0)
	end

	for _, region in ipairs(button.DrakeishUI_IconRegions) do
		if region ~= button.drakeishCircle then
			region:ClearAllPoints()
			region:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
			region:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
			-- Only crop generic square icons; leave atlas coords alone if clearly an icon path
			local tex = region:GetTexture()
			local s = tex and tostring(tex) or ""
			if not (s:find("Interface\\Icons") or s:find("Icons\\")) then
				region:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			else
				region:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			end
			region:SetDrawLayer("ARTWORK")
			region:SetAlpha(1)
			region:Show()
		end
	end

	button.drakeishCircle:SetSize(BORDER_SIZE, BORDER_SIZE)
	button.drakeishCircle:SetDrawLayer("OVERLAY")
	button.drakeishCircle:Show()
end
_G.DrakeishUI_SkinMinimapButton = DrakeishUI_SkinMinimapButton

local function SkinKnownAddonButtons()
	local named = {
		"CustomRadialRacialButton",
	}
	for _, name in ipairs(named) do
		local btn = _G[name]
		if btn then
			DrakeishUI_SkinMinimapButton(btn)
		end
	end
end

-- Function to detect only visible minimap children and their children recursively
function DetectMinimapChildren(parent, depth)
	depth = depth or 0
	local indent = string.rep("  ", depth)
	
	if not parent then
		return
	end
	
	local children = {parent:GetChildren()}
	for i, child in ipairs(children) do
		-- Only process visible children
		if child:IsVisible() then
			local name = child:GetName()
			DrakeishUI_SkinMinimapButton(child)
			if name then
				-- Store detected button
				DetectedButtons[name] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown"
				}
			else
				-- Store unnamed button with unique identifier
				local uniqueName = "Unnamed_" .. tostring(child)
				DetectedButtons[uniqueName] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown",
					unnamed = true
				}
			end
			
			-- Recursively check children of this visible child
			DetectMinimapChildren(child, depth + 1)
		else
			-- Show hidden children but don't recurse into them
			local name = child:GetName()
			if name then
			else
			end
		end
	end
end

-- Function to scan and list all minimap children
function ScanMinimapChildren()
	-- Don't clear DetectedButtons - keep accumulating detected buttons
	DetectMinimapChildren(Minimap, 0)
end

-- Function to hide visible minimap children and their children recursively
function HideVisibleChildren(parent, depth)
	depth = depth or 0
	local indent = string.rep("  ", depth)
	
	if not parent then
		return
	end
	
	local children = {parent:GetChildren()}
	for i, child in ipairs(children) do
		-- Only hide visible children
		if child:IsVisible() then
			local name = child:GetName()
			-- Keep the eye's own border; the generic skin crops the flipbook.
			if name ~= "MiniMapLFGFrame" then
				DrakeishUI_SkinMinimapButton(child)
			end
			if name then
				child:Hide()
				HiddenButtons[name] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown",
					hiddenTime = GetTime()
				}
			else
				child:Hide()
				local uniqueName = "Unnamed_" .. tostring(child)
				HiddenButtons[uniqueName] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown",
					hiddenTime = GetTime(),
					unnamed = true
				}
			end
			HideVisibleChildren(child, depth + 1)
		end
	end
end

-- Function to hide all visible minimap children
function HideAllVisibleChildren()
	-- Don't clear HiddenButtons - keep accumulating hidden buttons
	
	-- Hide all visible children starting from Minimap
	HideVisibleChildren(Minimap, 0)
	SkinKnownAddonButtons()
	-- Also collect named heritage/racial button if parented elsewhere
	local racial = _G.CustomRadialRacialButton
	if racial and racial:IsVisible() then
		DrakeishUI_SkinMinimapButton(racial)
		racial:Hide()
		HiddenButtons["CustomRadialRacialButton"] = {
			frame = racial,
			depth = 0,
			parent = racial:GetParent() and racial:GetParent():GetName() or "Unknown",
			hiddenTime = GetTime()
		}
	end
end

-- Function to list detected buttons
function ListDetectedButtons()
	local count = 0
	for name, data in pairs(DetectedButtons) do
		count = count + 1
		local indent = string.rep("  ", data.depth)
		local status = data.unnamed and " [UNNAMED]" or ""
	end
end

-- Function to list hidden buttons
function ListHiddenButtons()
	local count = 0
	for name, data in pairs(HiddenButtons) do
		count = count + 1
		local indent = string.rep("  ", data.depth)
		local status = data.unnamed and " [UNNAMED]" or ""
		local timeAgo = GetTime() - data.hiddenTime
	end
end

-- Function to clear stored data
function ClearStoredData()
	DetectedButtons = {}
	HiddenButtons = {}
end

-- Function to show hidden buttons for 5 seconds
function ShowHiddenButtons()
	if IsShowing then
		return
	end

	SkinKnownAddonButtons()
	for name, data in pairs(HiddenButtons) do
		if data.frame and data.frame.Show then
			DrakeishUI_SkinMinimapButton(data.frame)
			data.frame:Show()
		end
	end
	
	IsShowing = true
	ShowTimeout = 3 -- 3 seconds
end

-- Function to hide the shown buttons again
function HideShownButtons()
	if not IsShowing then
		return
	end
	
	for name, data in pairs(HiddenButtons) do
		if data.frame and data.frame.Hide then
			data.frame:Hide()
		end
	end
	
	IsShowing = false
	ShowTimeout = -1
end

-- Update function for countdown timer and periodic hiding
function MinimapButtons_OnUpdate(self, elapsed)
	if ShowTimeout > 0 then
		ShowTimeout = ShowTimeout - elapsed
		if ShowTimeout <= 0 then
			HideShownButtons()
		end
	end
	
	-- Very quick check to ensure buttons stay hidden after UI changes (every 0.1 seconds)
	self.checkTimer = (self.checkTimer or 0) + elapsed
	if self.checkTimer >= 0.1 then
		self.checkTimer = 0
		-- Only hide if we're not currently showing buttons
		if not IsShowing then
			HideAllVisibleChildren()
		end
	end
end

-- Event handler for automatic hiding
function MinimapButtons_OnEvent()
	if event == "VARIABLES_LOADED" then
		-- Hide after a short delay to ensure all addons are loaded
		local timer = CreateFrame("Frame")
		timer:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed >= 3 then
				HideAllVisibleChildren()
				self:SetScript("OnUpdate", nil)
			end
		end)
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Always hide minimap buttons when this event fires
		-- This ensures buttons stay hidden even if other UI changes trigger this event
		local timer = CreateFrame("Frame")
		timer:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed >= 2 then
				HideAllVisibleChildren()
				self:SetScript("OnUpdate", nil)
			end
		end)
	end
end

-- Create event frame and register events
local MinimapButtonsFrame = CreateFrame("Frame")
MinimapButtonsFrame:RegisterEvent("VARIABLES_LOADED")
MinimapButtonsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
MinimapButtonsFrame:SetScript("OnEvent", MinimapButtons_OnEvent)
MinimapButtonsFrame:SetScript("OnUpdate", MinimapButtons_OnUpdate)

-- Create the toggle button. It sits on the bottom of the ring and orbits with the border.
local MinimapButtonsToggleButton = CreateFrame("Button", "MinimapButtonsToggleButton", UIParent)
MinimapButtonsToggleButton:SetWidth(18)
MinimapButtonsToggleButton:SetHeight(18)
MinimapButtonsToggleButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 1, -4)
MinimapButtonsToggleButton:SetFrameStrata("HIGH")
MinimapButtonsToggleButton:SetFrameLevel(10)

-- Set default visibility to 50%
MinimapButtonsToggleButton:SetAlpha(0.5)

-- Create button texture
local buttonTexture = MinimapButtonsToggleButton:CreateTexture(nil, "BACKGROUND")
buttonTexture:SetAllPoints()
buttonTexture:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\MBBbutton2")
buttonTexture:SetTexCoord(0.075, 0.925, 0.075, 0.925)

-- Create button highlight
local buttonHighlight = MinimapButtonsToggleButton:CreateTexture(nil, "HIGHLIGHT")
buttonHighlight:SetAllPoints()
buttonHighlight:SetTexture("Interface\\AddOns\\DrakeishUI\\assets\\MBBbutton2")
buttonHighlight:SetTexCoord(0.075, 0.925, 0.075, 0.925)
buttonHighlight:SetBlendMode("ADD")
buttonHighlight:SetAlpha(0.3)

local toggleAngle = 0
local togglePressed = false
local tcos, tsin = math.cos, math.sin

local function RotateToggleTexture(texture, angle, inset)
	local c, s = tcos(angle), tsin(angle)
	local span = 1 - 2 * inset
	local function r(px, py)
		local rx = c * px + s * py
		local ry = -s * px + c * py
		return 0.5 + rx * span, 0.5 - ry * span
	end
	local ulx, uly = r(-0.5, 0.5)
	local llx, lly = r(-0.5, -0.5)
	local urx, ury = r(0.5, 0.5)
	local lrx, lry = r(0.5, -0.5)
	texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

function DrakeishUI_UpdateMinimapButtonsToggle(angle)
	if angle then
		toggleAngle = angle
	end
	local mapH = Minimap:GetHeight()
	if not mapH or mapH < 1 then
		mapH = 140
	end
	-- Offsets are in the button's parent space. The minimap is scaled, so the
	-- distance from its center to its bottom has to be scaled too or the
	-- button sits high of the original BOTTOM anchor.
	local scale = 1
	if Minimap.GetEffectiveScale and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() > 0 then
		scale = Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale()
	end
	local ox, oy = 1, -(mapH / 2) * scale - 4 + (MinimapButtonsToggleButton:GetHeight() / 2)
	local c, s = tcos(toggleAngle), tsin(toggleAngle)
	local x = ox * c - oy * s
	local y = ox * s + oy * c
	MinimapButtonsToggleButton:ClearAllPoints()
	MinimapButtonsToggleButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
	local inset = togglePressed and 0 or 0.075
	RotateToggleTexture(buttonTexture, toggleAngle, inset)
	RotateToggleTexture(buttonHighlight, toggleAngle, inset)
end
_G.DrakeishUI_UpdateMinimapButtonsToggle = DrakeishUI_UpdateMinimapButtonsToggle

-- Button scripts
MinimapButtonsToggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
MinimapButtonsToggleButton:SetScript("OnClick", function(self, button)
	if button == "LeftButton" then
		ShowHiddenButtons()
	elseif button == "RightButton" then
		if IsShowing then
			HideShownButtons()
		else
			ShowHiddenButtons()
		end
	end
end)

MinimapButtonsToggleButton:SetScript("OnMouseDown", function(self)
	togglePressed = true
	DrakeishUI_UpdateMinimapButtonsToggle()
end)

MinimapButtonsToggleButton:SetScript("OnMouseUp", function(self)
	togglePressed = false
	DrakeishUI_UpdateMinimapButtonsToggle()
end)

-- Tooltip and visibility effects
MinimapButtonsToggleButton:SetScript("OnEnter", function(self)
	-- Set visibility to 100% on mouse hover
	self:SetAlpha(1.0)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Minimap Buttons Toggle")
	GameTooltip:AddLine("Left-click: Show hidden buttons for 3 seconds", 1, 1, 1)
	GameTooltip:AddLine("Right-click: Toggle show/hide", 1, 1, 1)
	GameTooltip:Show()
end)

MinimapButtonsToggleButton:SetScript("OnLeave", function(self)
	-- Set visibility back to 50% when mouse leaves
	self:SetAlpha(0.5)
	GameTooltip:Hide()
end)

-- Register slash command for testing
SLASH_MINIMAPBUTTONS1 = "/mb"
SlashCmdList["MINIMAPBUTTONS"] = function(msg)
	if msg == "scan" then
		ScanMinimapChildren()
	elseif msg == "hide" then
		HideAllVisibleChildren()
	elseif msg == "detected" then
		ListDetectedButtons()
	elseif msg == "hidden" then
		ListHiddenButtons()
	elseif msg == "clear" then
		ClearStoredData()
	elseif msg == "show" then
		ShowHiddenButtons()
	else
		-- Commands available but no debug output
	end
end
