--[[
    DrakeishUI Chat Copy Module
    Allows copying chat history by double-clicking chat frame tabs
    Based on BasicChatMods implementation, adapted for DrakeishUI
]]--

local addon = select(2,...);
local config = addon.config;
local pairs = pairs;
local format = string.format;
local UIParent = UIParent;
local _G = _G;

-- Chat copy functionality
local lines = {}
local chatCopyFrame = nil

-- Create the copy frame
local function CreateChatCopyFrame()
    if chatCopyFrame then return end
    
    -- Main frame
    chatCopyFrame = CreateFrame("Frame", "DrakeishUI_ChatCopyFrame", UIParent)
    chatCopyFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = {left = 3, right = 3, top = 5, bottom = 3}
    })
    chatCopyFrame:SetBackdropColor(0, 0, 0, 0.9)
    chatCopyFrame:SetWidth(600)
    chatCopyFrame:SetHeight(500)
    chatCopyFrame:SetPoint("CENTER", UIParent, "CENTER")
    chatCopyFrame:Hide()
    chatCopyFrame:SetFrameStrata("DIALOG")
    
    -- Global Esc key handler
    chatCopyFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            chatCopyFrame:Hide()
            _G["DrakeishUI_ChatCopyBox"]:SetText("")
        end
    end)
    -- Don't enable keyboard initially - will be enabled when editbox is clicked
    chatCopyFrame:EnableKeyboard(false)
    
    -- Title bar (non-movable)
    local titleBar = CreateFrame("Frame", nil, chatCopyFrame)
    titleBar:SetHeight(25)
    titleBar:SetPoint("TOPLEFT", chatCopyFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", chatCopyFrame, "TOPRIGHT", 0, 0)
    
    -- Title text
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("Chat History Copy")
    
    -- Scroll area
    local scrollArea = CreateFrame("ScrollFrame", "DrakeishUI_ChatCopyScroll", chatCopyFrame, "UIPanelScrollFrameTemplate")
    scrollArea:SetPoint("TOPLEFT", chatCopyFrame, "TOPLEFT", 8, -35)
    scrollArea:SetPoint("BOTTOMRIGHT", chatCopyFrame, "BOTTOMRIGHT", -30, 45)
    
    -- Edit box
    local editBox = CreateFrame("EditBox", "DrakeishUI_ChatCopyBox", chatCopyFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(99999)
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(550)
    editBox:SetHeight(400)
    editBox:SetScript("OnEscapePressed", function(self) 
        chatCopyFrame:Hide() 
        editBox:SetText("") 
    end)
    
    -- Make editbox truly read-only
    editBox.originalText = ""
    editBox:SetScript("OnTextChanged", function(self)
        -- Restore original text if it was modified
        if self:GetText() ~= self.originalText then
            self:SetText(self.originalText)
        end
    end)
    
    -- Block all character input
    editBox:SetScript("OnChar", function(self, char)
        return true -- Block all character input
    end)
    
    -- Block all key input except navigation and copy
    editBox:SetScript("OnKeyDown", function(self, key)
        -- Allow only navigation keys
        local navigationKeys = {
            ["LEFT"] = true, ["RIGHT"] = true, ["UP"] = true, ["DOWN"] = true,
            ["HOME"] = true, ["END"] = true, ["PAGEUP"] = true, ["PAGEDOWN"] = true,
            ["TAB"] = true, ["ESCAPE"] = true
        }
        
        -- Allow Ctrl+A for select all
        if IsControlKeyDown() and key == "A" then
            return false -- Allow default behavior
        end
        
        -- Allow Ctrl+C for copy
        if IsControlKeyDown() and key == "C" then
            return false -- Allow default behavior
        end
        
        -- Block everything else
        if not navigationKeys[key] then
            return true
        end
    end)
    
    -- Block mouse input that could modify text (but allow selection)
    editBox:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Allow selection but prevent text modification
            chatCopyFrame:EnableKeyboard(true)
            self:SetFocus()
            return false -- Allow default selection behavior
        end
        return true -- Block other mouse buttons
    end)
    
    -- Disable keyboard input when editbox loses focus
    editBox:SetScript("OnEditFocusLost", function(self)
        chatCopyFrame:EnableKeyboard(false)
    end)
    
    scrollArea:SetScrollChild(editBox)
    
    -- Close button
    local closeButton = CreateFrame("Button", "DrakeishUI_ChatCopyClose", chatCopyFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", chatCopyFrame, "TOPRIGHT", 2, 2)
    closeButton:SetScript("OnClick", function() 
        chatCopyFrame:Hide() 
        editBox:SetText("") 
    end)
    
    -- Copy button
    local copyButton = CreateFrame("Button", "DrakeishUI_ChatCopyButton", chatCopyFrame, "UIPanelButtonTemplate")
    copyButton:SetSize(100, 25)
    copyButton:SetPoint("BOTTOMLEFT", chatCopyFrame, "BOTTOMLEFT", 10, 10)
    copyButton:SetText("Copy All")
    copyButton:SetScript("OnClick", function()
        editBox:HighlightText(0)
        -- Don't automatically set focus - let user click in editbox to enable keyboard
    end)
    
    -- Clear button
    local clearButton = CreateFrame("Button", "DrakeishUI_ChatClearButton", chatCopyFrame, "UIPanelButtonTemplate")
    clearButton:SetSize(100, 25)
    clearButton:SetPoint("BOTTOMLEFT", copyButton, "BOTTOMRIGHT", 10, 0)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        editBox:SetText("")
        editBox.originalText = ""
    end)
    
    -- Instruction text
    local instructionText = clearButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instructionText:SetPoint("LEFT", clearButton, "RIGHT", 15, 0)
    instructionText:SetText("Ctrl+C to copy selected text (read-only)")
    instructionText:SetTextColor(1, 1, 0) -- Yellow color
end

-- Copy chat function
local function CopyChatHistory(frame)
    local chatFrame = _G[format("%s%d", "ChatFrame", frame:GetID())]
    if not chatFrame then return end
    
    -- Temporarily reduce font size to get all text
    local _, fontSize = chatFrame:GetFont()
    FCF_SetChatWindowFontSize(chatFrame, chatFrame, 0.01)
    
    -- Collect all text lines
    local lineCount = 1
    for i = select("#", chatFrame:GetRegions()), 1, -1 do
        local region = select(i, chatFrame:GetRegions())
        if region:GetObjectType() == "FontString" then
            lines[lineCount] = tostring(region:GetText())
            lineCount = lineCount + 1
        end
    end
    
    -- Restore font size
    FCF_SetChatWindowFontSize(chatFrame, chatFrame, fontSize)
    
    -- Combine all lines
    local totalLines = lineCount - 1
    local chatText = table.concat(lines, "\n", 1, totalLines)
    
    -- Show copy frame
    CreateChatCopyFrame()
    chatCopyFrame:Show()
    _G["DrakeishUI_ChatCopyBox"]:SetText(chatText)
    
    -- Store the original text for read-only protection
    local editBox = _G["DrakeishUI_ChatCopyBox"]
    if editBox then
        editBox.originalText = chatText
    end
    
    -- Clear lines table
    wipe(lines)
end

-- Tooltip function
local function ShowChatCopyTooltip(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
    GameTooltip:AddLine("Chat Copy", 1, 1, 1)
    GameTooltip:AddLine("Double-click to copy chat history", 1, 0.7, 0)
    GameTooltip:Show()
end

-- Initialize chat copy functionality
local function InitializeChatCopy()
    -- Hook all chat frame tabs
    for i = 1, 10 do
        local tab = _G[format("%s%d%s", "ChatFrame", i, "Tab")]
        if tab then
            tab:SetScript("OnDoubleClick", CopyChatHistory)
            tab:SetScript("OnEnter", ShowChatCopyTooltip)
        end
    end
    
    -- Add copy buttons to chat frames
    for i = 1, 10 do
        local chatFrame = _G[format("%s%d", "ChatFrame", i)]
        if chatFrame then
            -- Create copy button for this chat frame
            local copyButton = CreateFrame("Button", format("DrakeishUI_ChatCopyButton_%d", i), chatFrame)
            copyButton:SetSize(16, 16)
            copyButton:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 20, -86)
            copyButton:SetFrameStrata("HIGH")
            copyButton:SetFrameLevel(chatFrame:GetFrameLevel() + 10)
			
            
            -- Button states with custom DrakeishUI copy icon
            copyButton:SetNormalTexture("Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUICopy.blp")
            copyButton:SetPushedTexture("Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUICopy.blp")
            copyButton:SetHighlightTexture("Interface\\AddOns\\DrakeishUI\\assets\\DrakeishUICopy.blp")
            
            -- Set alpha on the normal texture (the main visible texture)
            local normalTexture = copyButton:GetNormalTexture()
            normalTexture:SetAlpha(0.3)
            
            -- Also set alpha on the button itself as backup
            copyButton:SetAlpha(0.3)
            
            -- Make highlight slightly brighter
            local highlight = copyButton:GetHighlightTexture()
            highlight:SetBlendMode("ADD")
            highlight:SetAlpha(0.3)
            
            -- Click functionality
            copyButton:SetScript("OnClick", function()
                CopyChatHistory(chatFrame)
            end)
            
            -- Tooltip and mouseover alpha
            copyButton:SetScript("OnEnter", function(self)
                -- Set alpha to full when hovering
                self:SetAlpha(1.0)
                local normalTexture = self:GetNormalTexture()
                if normalTexture then
                    normalTexture:SetAlpha(1.0)
                end
                
                -- Show tooltip
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine("Copy Chat History", 1, 1, 1)
                GameTooltip:AddLine("Click to copy this chat frame's history", 1, 0.7, 0)
                GameTooltip:Show()
            end)
            copyButton:SetScript("OnLeave", function(self)
                -- Restore alpha to 0.5 when not hovering
                self:SetAlpha(0.5)
                local normalTexture = self:GetNormalTexture()
                if normalTexture then
                    normalTexture:SetAlpha(0.5)
                end
                
                -- Hide tooltip
                GameTooltip:Hide()
            end)
            
            -- Hide button if chat frame is hidden
            local function UpdateButtonVisibility()
                if chatFrame:IsShown() then
                    copyButton:Show()
                else
                    copyButton:Hide()
                end
            end
            
            -- Hook into chat frame show/hide events
            chatFrame:HookScript("OnShow", UpdateButtonVisibility)
            chatFrame:HookScript("OnHide", UpdateButtonVisibility)
            
            -- Initial visibility check
            UpdateButtonVisibility()
        end
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" then
        InitializeChatCopy()
    elseif event == "ADDON_LOADED" and addonName == "DrakeishUI" then
        -- Initialize after DrakeishUI is loaded
        InitializeChatCopy()
    end
end)

-- Slash command for manual copy
SLASH_DRAKEISHCHATCOPY1 = "/chatcopy"
SLASH_DRAKEISHCHATCOPY2 = "/ccopy"
SlashCmdList["DRAKEISHCHATCOPY"] = function(msg)
    local chatFrame = ChatFrame1 -- Default to main chat frame
    if msg and msg ~= "" then
        local frameNum = tonumber(msg)
        if frameNum and frameNum >= 1 and frameNum <= 10 then
            chatFrame = _G["ChatFrame" .. frameNum]
        end
    end
    
    if chatFrame then
        CopyChatHistory(chatFrame)
    end
end