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
			if name then
				-- Hide it
				child:Hide()
				-- Store hidden button
				HiddenButtons[name] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown",
					hiddenTime = GetTime()
				}
			else
				-- Hide unnamed child
				child:Hide()
				-- Store unnamed hidden button
				local uniqueName = "Unnamed_" .. tostring(child)
				HiddenButtons[uniqueName] = {
					frame = child,
					depth = depth,
					parent = parent:GetName() or "Unknown",
					hiddenTime = GetTime(),
					unnamed = true
				}
			end
			
			-- Recursively hide children of this child
			HideVisibleChildren(child, depth + 1)
		end
	end
end

-- Function to hide all visible minimap children
function HideAllVisibleChildren()
	-- Don't clear HiddenButtons - keep accumulating hidden buttons
	
	-- Hide all visible children starting from Minimap
	HideVisibleChildren(Minimap, 0)
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
	
	for name, data in pairs(HiddenButtons) do
		if data.frame and data.frame.Show then
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

-- Create the toggle button
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
	buttonTexture:SetTexCoord(0, 1, 0, 1)
end)

MinimapButtonsToggleButton:SetScript("OnMouseUp", function(self)
	buttonTexture:SetTexCoord(0.075, 0.925, 0.075, 0.925)
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
