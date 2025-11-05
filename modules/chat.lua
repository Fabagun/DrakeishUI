local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local gsub = string.gsub;
local UIParent = UIParent;
local hooksecurefunc = hooksecurefunc;
local _G = _G;


local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

-- SavedVariables setup
MinimalChatDB = MinimalChatDB or {}

-- Anchor frame for moving chat
local chatAnchor = CreateFrame("Frame", "MinimalChatAnchor", UIParent)
chatAnchor:SetSize(300, 100)
chatAnchor:SetMovable(true)
chatAnchor:EnableMouse(true)
chatAnchor:SetClampedToScreen(true)
chatAnchor:RegisterForDrag("LeftButton")

-- Border visuals
chatAnchor:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
chatAnchor:SetBackdropColor(0, 0.5, 1, 0.3)
chatAnchor:SetBackdropBorderColor(0.2, 0.6, 1, 0.8)
chatAnchor:Hide()

chatAnchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
chatAnchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    MinimalChatDB.x = x
    MinimalChatDB.y = y
end)

-- Register slash command AFTER everything is loaded
SLASH_MINIMALCHAT1 = "/chatanchor"
SlashCmdList["MINIMALCHAT"] = function()
    if chatAnchor:IsShown() then
        chatAnchor:Hide()
    else
        chatAnchor:Show()
    end
end

-- Function to apply chat positioning and styling
local function ApplyChatPositioning()
    local chat = ChatFrame1
    local editBox = ChatFrame1EditBox

    if not chat or not editBox then return end

    -- Position anchor and chat
    if MinimalChatDB.x and MinimalChatDB.y then
        chatAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", MinimalChatDB.x, MinimalChatDB.y)
    else
        chatAnchor:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 20)
    end

    chat:ClearAllPoints()
    chat:SetPoint("BOTTOMLEFT", chatAnchor, "BOTTOMLEFT", 0, 0)

    chat:SetWidth(300)
    chat:SetHeight(100)
    chat:SetMovable(false)
    chat:SetResizable(true)
    chat:EnableMouse(false)
    chat:SetClampedToScreen(false)
    chat:SetUserPlaced(true)

    -- Function to fully hide UI elements
    local function kill(frame)
        if frame then
            frame:Hide()
            frame.Show = function() end
            frame:SetAlpha(0)
            frame:SetScale(0.001)
            frame:SetParent(chatAnchor) -- prevent UIParent resets
        end
    end

    -- Hide buttons and side elements
    kill(ChatFrame1ScrollBar)
    kill(ChatFrame1UpButton)
    kill(ChatFrame1DownButton)
    kill(ChatFrameMenuButton)
    kill(QuickJoinToastButton)
    kill(ChatFrameChannelButton)
    kill(ChatFrameToggleVoiceDeafenButton)
    kill(ChatFrameToggleVoiceMuteButton)
    kill(ChatFrame1ButtonFrame)
    kill(FriendsMicroButton)

    -- Hide chat tabs
    for i = 1, NUM_CHAT_WINDOWS do
        kill(_G["ChatFrame"..i.."Tab"])
    end

    -- Hide textures
    for _, region in ipairs({chat:GetRegions()}) do
        if region.GetTexture and region:GetTexture() then
            region:SetTexture(nil)
        end
    end

    -- Edit box cleanup
    for i = 1, select("#", editBox:GetRegions()) do
        local region = select(i, editBox:GetRegions())
        if region.GetTexture and region:GetTexture() then
            region:SetTexture(nil)
        end
    end

    -- Edit box above chat
    editBox:ClearAllPoints()
    editBox:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", 0, 2)
    editBox:SetPoint("BOTTOMRIGHT", chat, "TOPRIGHT", 0, 2)

    chat:SetJustifyH("LEFT")
end

-- Periodic check to ensure chat positioning stays correct (runs every 2 seconds for first 10 seconds after login)
local chatCheckFrame = CreateFrame("Frame")
local chatCheckCount = 0
chatCheckFrame:SetScript("OnUpdate", function(self, elapsed)
    chatCheckCount = chatCheckCount + elapsed
    if chatCheckCount >= 2 then
        chatCheckCount = 0
        ApplyChatPositioning()
    end
end)

f:SetScript("OnEvent", function(self, event)
    ApplyChatPositioning()
    
    -- Add delayed positioning to handle chat that loads after initial events
    if event == "PLAYER_ENTERING_WORLD" then
        -- Start periodic check for 10 seconds
        chatCheckFrame:Show()
        -- Use WoTLK-compatible timer instead of C_Timer.After
        local timer = CreateFrame("Frame")
        local elapsed = 0
        timer:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 10 then
                chatCheckFrame:Hide()
                timer:SetScript("OnUpdate", nil)
            end
        end)
        
        -- Delayed positioning using WoTLK-compatible method
        local delayTimer1 = CreateFrame("Frame")
        delayTimer1:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.5 then
                ApplyChatPositioning()
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        local delayTimer2 = CreateFrame("Frame")
        delayTimer2:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 1.0 then
                ApplyChatPositioning()
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        local delayTimer3 = CreateFrame("Frame")
        delayTimer3:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 2.0 then
                ApplyChatPositioning()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Hook chat frame updates to ensure positioning is maintained
if ChatFrame1 then
    ChatFrame1:HookScript("OnShow", function()
        -- Use WoTLK-compatible delayed execution
        local hookTimer = CreateFrame("Frame")
        hookTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.1 then
                ApplyChatPositioning()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end)
end

-- Hook edit box updates
if ChatFrame1EditBox then
    ChatFrame1EditBox:HookScript("OnShow", function()
        -- Use WoTLK-compatible delayed execution
        local hookTimer = CreateFrame("Frame")
        hookTimer:SetScript("OnUpdate", function(self, delta)
            self.elapsed = (self.elapsed or 0) + delta
            if self.elapsed >= 0.1 then
                ApplyChatPositioning()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end)
end



local chatToggleButton
do
	chatToggleButton = CreateFrame('CheckButton', 'chattoggle', UIParent)
	chatToggleButton:SetSize(10, 14)
	chatToggleButton:SetPoint("LEFT", chatAnchor, "TOPLEFT", 2, 17)
	chatToggleButton:SetAlpha(0.3)
	chatToggleButton:SetNormalTexture''
	chatToggleButton:SetPushedTexture''
	chatToggleButton:SetHighlightTexture''
	chatToggleButton:RegisterForClicks('LeftButtonUp')

	local normal = chatToggleButton:GetNormalTexture()
	normal:set_atlas('bag-arrow-2x')

	local pushed = chatToggleButton:GetPushedTexture()
	pushed:set_atlas('bag-arrow-2x')

	local highlight = chatToggleButton:GetHighlightTexture()
	highlight:set_atlas('bag-arrow-2x')
	highlight:SetAlpha(.4)
	highlight:SetBlendMode('ADD')
	
	chatToggleButton:SetScript('OnClick',function(self)
		local checked = self:GetChecked();
		if checked then
			normal:set_atlas('bag-arrow-invert-2x')
			pushed:set_atlas('bag-arrow-invert-2x')
			highlight:set_atlas('bag-arrow-invert-2x')
			ChatFrame1:Hide()
            ChatFrame1EditBox:Hide()
			if _G.UnifiedInfoFrame then
            _G.UnifiedInfoFrame:Hide()
            end
		else
			normal:set_atlas('bag-arrow-2x')
			pushed:set_atlas('bag-arrow-2x')
			highlight:set_atlas('bag-arrow-2x')
			ChatFrame1:Show()
            -- ChatFrame1EditBox:Show()
			if _G.UnifiedInfoFrame then
            _G.UnifiedInfoFrame:Show()
            end
		end
		chat_state = checked and 1 or 0
		-- print("chat_state saved as:", chat_state) -- Debug line
	end)
	
	-- Add mouseover effects to match other toggle button
	chatToggleButton:SetScript("OnEnter", function(self)
		self:SetAlpha(1.0)
	end)
	chatToggleButton:SetScript("OnLeave", function(self)
		self:SetAlpha(0.3)
	end)
	
	-- Use a timer to run after the main event handler
	local initTimer = CreateFrame("Frame")
	initTimer:SetScript("OnUpdate", function(self, delta)
		self.elapsed = (self.elapsed or 0) + delta
		if self.elapsed >= 0.1 then -- Run after main event handler
			self:SetScript("OnUpdate", nil)
			if not chat_state then chat_state = 0 end
			if chat_state == 1 then
				ChatFrame1:Hide()
				ChatFrame1EditBox:Hide()
				if _G.UnifiedInfoFrame then
				_G.UnifiedInfoFrame:Hide()
				end
				normal:set_atlas('bag-arrow-invert-2x')
				pushed:set_atlas('bag-arrow-invert-2x')
				highlight:set_atlas('bag-arrow-invert-2x')
				chatToggleButton:SetChecked(1)
			else
				ChatFrame1:Show()
				-- ChatFrame1EditBox:Show()
				if _G.UnifiedInfoFrame then
				_G.UnifiedInfoFrame:Show()
				end
				normal:set_atlas('bag-arrow-2x')
				pushed:set_atlas('bag-arrow-2x')
				highlight:set_atlas('bag-arrow-2x')
				chatToggleButton:SetChecked(nil)
			end
		end
	end)
end