-- DragonflightUI Party Combat Glow
-- This applies combat glow effects to party frames

-- Configuration: Set to true to enable party glows, false to disable
local ENABLE_PARTY_GLOWS = true

local ATLAS_TEXTURE = 'Interface\\Addons\\DrakeishUI\\modules\\DragonflightUI\\Textures\\uiunitframe'
local COMBAT_TEX_COORDS = {0.3095703125, 0.4208984375, 0.3125, 0.404296875}

-- Party frame glow storage
local partyGlows = {}

-- Configure Party Attack Mode Texture (Party Member Attacking)
local function ConfigurePartyAttackMode(frame, unit)
    if not ENABLE_PARTY_GLOWS then return end
    
    local glowName = "PartyGlow_Attack_" .. frame:GetName()
    local glow = partyGlows[glowName]
    
    if not glow then
        -- Create glow on the existing overlay frame to ensure it's above the border
        local overlayFrame = frame.overlayFrame
        if not overlayFrame then
            -- Create overlay frame if it doesn't exist
            overlayFrame = CreateFrame("Frame", nil, frame)
            overlayFrame:SetAllPoints(frame)
            overlayFrame:SetSize(150, 70)  -- Larger than glow size to prevent clipping
            overlayFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
            overlayFrame:EnableMouse(false)
            frame.overlayFrame = overlayFrame
        end
        
        glow = overlayFrame:CreateTexture(glowName, "OVERLAY")
        glow:SetTexture(ATLAS_TEXTURE)
        glow:SetTexCoord(unpack(COMBAT_TEX_COORDS))
        glow:SetVertexColor(1.0, 0.0, 0.0, 0.5)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.0)
        glow:SetDrawLayer("OVERLAY", 15)
        glow:ClearAllPoints()
        glow:SetPoint('CENTER', frame, 'CENTER', -6, 0)
        glow:SetSize(135, 55)
        glow:Hide()
        partyGlows[glowName] = glow
    end
    
    return glow
end

-- Configure Party Threat Glow (Party Member Being Attacked)
local function ConfigurePartyThreatGlow(frame, unit)
    if not ENABLE_PARTY_GLOWS then return end
    
    local glowName = "PartyGlow_Threat_" .. frame:GetName()
    local glow = partyGlows[glowName]
    
    if not glow then
        -- Create glow on the existing overlay frame to ensure it's above the border
        local overlayFrame = frame.overlayFrame
        if not overlayFrame then
            -- Create overlay frame if it doesn't exist
            overlayFrame = CreateFrame("Frame", nil, frame)
            overlayFrame:SetAllPoints(frame)
            overlayFrame:SetSize(150, 70)  -- Larger than glow size to prevent clipping
            overlayFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
            overlayFrame:EnableMouse(false)
            frame.overlayFrame = overlayFrame
        end
        
        glow = overlayFrame:CreateTexture(glowName, "OVERLAY")
        glow:SetTexture(ATLAS_TEXTURE)
        glow:SetTexCoord(unpack(COMBAT_TEX_COORDS))
        glow:SetVertexColor(1.0, 0.0, 0.0, 1.0)
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.5)
        glow:SetDrawLayer("OVERLAY", 20)
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", frame, "CENTER", -6, 0)
        glow:SetSize(135, 55)
        glow:Hide()
        partyGlows[glowName] = glow
    end
    
    return glow
end

-- Update party frame combat status
local function UpdatePartyCombatStatus(frame, unit)
    if not ENABLE_PARTY_GLOWS or not UnitExists(unit) then return end
    
    local attackGlow = ConfigurePartyAttackMode(frame, unit)
    local threatGlow = ConfigurePartyThreatGlow(frame, unit)
    
    -- Check if party member is attacking
    if UnitAffectingCombat(unit) then
        attackGlow:Show()
    else
        attackGlow:Hide()
    end
    
    -- Check if party member is being attacked (has threat)
    if UnitThreatSituation(unit) and UnitThreatSituation(unit) > 0 then
        threatGlow:Show()
    else
        threatGlow:Hide()
    end
end

-- Hide all party glows
local function HideAllPartyGlows()
    for glowName, glow in pairs(partyGlows) do
        if glow then
            glow:Hide()
        end
    end
end

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if not ENABLE_PARTY_GLOWS then return end
    
    local arg1 = ...
    
    -- Update all party frames when group changes
    if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD") and party_state ~= 1 then
        for i = 1, 4 do
            local partyFrame = _G["CustomPartyFrame" .. i]
            if partyFrame then
                UpdatePartyCombatStatus(partyFrame, "party" .. i)
            end
        end
    end
    
    -- Update specific party frame when their status changes
    if event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        if arg1 and string.match(arg1, "^party%d$") then
            local partyFrame = _G["CustomPartyFrame" .. string.sub(arg1, 6)]
            if partyFrame then
                UpdatePartyCombatStatus(partyFrame, arg1)
            end
        end
    end
end)

-- Hook into party frame updates
local function HookPartyFrameUpdates()
    for i = 1, 4 do
        local partyFrame = _G["CustomPartyFrame" .. i]
        if partyFrame then
            -- Hook the party frame's update function if it exists
            if partyFrame.UpdatePartyFrame then
                local originalUpdate = partyFrame.UpdatePartyFrame
                partyFrame.UpdatePartyFrame = function(self, unit)
                    originalUpdate(self, unit)
                    UpdatePartyCombatStatus(self, unit)
                end
            end
        end
    end
end

-- Initialize when addon loads
local function InitializePartyGlows()
    if not ENABLE_PARTY_GLOWS then return end
    
    -- Wait for party frames to be created
    C_Timer.After(1, function()
        HookPartyFrameUpdates()
        
        -- Update all existing party frames
        for i = 1, 4 do
            local partyFrame = _G["CustomPartyFrame" .. i]
            if partyFrame then
                UpdatePartyCombatStatus(partyFrame, "party" .. i)
            end
        end
    end)
end

-- Initialize on login
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializePartyGlows()
    else
        -- Handle other events
        if not ENABLE_PARTY_GLOWS then return end
        
        local arg1 = ...
        
        -- Update all party frames when group changes
        if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD") and party_state ~= 1 then
            for i = 1, 4 do
                local partyFrame = _G["CustomPartyFrame" .. i]
                if partyFrame then
                    UpdatePartyCombatStatus(partyFrame, "party" .. i)
                end
            end
        end
        
        -- Update specific party frame when their status changes
        if event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
            if arg1 and string.match(arg1, "^party%d$") then
                local partyFrame = _G["CustomPartyFrame" .. string.sub(arg1, 6)]
                if partyFrame then
                    UpdatePartyCombatStatus(partyFrame, arg1)
                end
            end
        end
    end
end)

-- Slash command to toggle party glows
SLASH_PARTYGLOW1 = "/partyglow"
SlashCmdList["PARTYGLOW"] = function(msg)
    if msg == "on" or msg == "enable" then
        ENABLE_PARTY_GLOWS = true
        print("Party glows enabled")
        -- Update all party frames
        for i = 1, 4 do
            local partyFrame = _G["CustomPartyFrame" .. i]
            if partyFrame then
                UpdatePartyCombatStatus(partyFrame, "party" .. i)
            end
        end
    elseif msg == "off" or msg == "disable" then
        ENABLE_PARTY_GLOWS = false
        HideAllPartyGlows()
        print("Party glows disabled")
    else
        print("Party Glow Commands:")
        print("/partyglow on - Enable party glows")
        print("/partyglow off - Disable party glows")
        print("Current status:", ENABLE_PARTY_GLOWS and "Enabled" or "Disabled")
    end
end
