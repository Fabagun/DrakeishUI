-- DragonflightUI Pet Combat Textures
-- This replaces the pet combat textures with DragonflightUI custom textures

local ATLAS_TEXTURE = 'Interface\\Addons\\DrakeishUI\\modules\\DragonflightUI\\Textures\\uiunitframe'
local COMBAT_TEX_COORDS = {0.3095703125, 0.4208984375, 0.3125, 0.404296875}

-- Configure Pet Attack Mode Texture (Pet Attacking)
local function ConfigurePetAttackMode()
    local texture = _G.PetAttackModeTexture
    if not texture then return end
    
    -- Set custom DragonflightUI texture
    texture:SetTexture(ATLAS_TEXTURE)
    texture:SetTexCoord(unpack(COMBAT_TEX_COORDS))
    texture:SetVertexColor(1.0, 0.0, 0.0, 1.0)
    texture:SetBlendMode("ADD")
    texture:SetAlpha(0.6)
    texture:SetDrawLayer("OVERLAY", 9)
    texture:ClearAllPoints()
    texture:SetPoint('CENTER', PetFrame, 'CENTER', -4, 1)
    texture:SetSize(116, 49)
    
    -- Override the SetVertexColor function to always use red
    texture.SetVertexColor = function(self, r, g, b, a)
        -- Always force red color
        getmetatable(self).__index.SetVertexColor(self, 1.0, 0.0, 0.0, a or 1.0)
    end
end

-- Configure Pet Threat Glow (Pet Being Attacked)
local function ConfigurePetThreatGlow()
    local threatFlash = _G.PetFrameFlash
    if not threatFlash then return end
    
    -- Set custom DragonflightUI texture
    threatFlash:SetTexture(ATLAS_TEXTURE)
    threatFlash:SetTexCoord(unpack(COMBAT_TEX_COORDS))
	threatFlash:SetVertexColor(1.0, 0.0, 0.0, 1)
    threatFlash:SetBlendMode("ADD")
    threatFlash:SetAlpha(1)
    threatFlash:SetDrawLayer("OVERLAY", 15)
    threatFlash:ClearAllPoints()
    threatFlash:SetPoint("CENTER", PetFrame, "CENTER", -4, 1)
    threatFlash:SetSize(116, 49)
end

-- Hide original Blizzard combat textures
local function HideOriginalCombatTextures()
    -- Hide PetCombatGlow (main pet combat glow frame)
    if PetCombatGlow then
        PetCombatGlow:Hide()
        PetCombatGlow:SetAlpha(0)
        PetCombatGlow.Show = function() end
    end
    
    -- Hide any other pet combat related textures
    if PetFlash then
        PetFlash:Hide()
        PetFlash:SetAlpha(0)
        PetFlash.Show = function() end
    end
end

-- Create a frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PET_ATTACK_START")
frame:RegisterEvent("PET_ATTACK_STOP")
frame:RegisterEvent("UNIT_PET")

frame:SetScript("OnEvent", function(self, event, ...)
    -- Hide original Blizzard textures
    HideOriginalCombatTextures()
    
    -- Configure custom DragonflightUI textures
    ConfigurePetAttackMode()
    ConfigurePetThreatGlow()
end)

-- Initial setup when addon loads
HideOriginalCombatTextures()
ConfigurePetAttackMode()
ConfigurePetThreatGlow()

-- Hook into pet frame updates to maintain custom textures
hooksecurefunc("PetFrame_Update", function()
    HideOriginalCombatTextures()
    ConfigurePetAttackMode()
    ConfigurePetThreatGlow()
end)

-- Hook for pet combat state changes
hooksecurefunc("PetFrame_UpdateCombat", function()
    HideOriginalCombatTextures()
    ConfigurePetAttackMode()
    ConfigurePetThreatGlow()
end)

-- Hook PetAttackModeTexture Show to apply custom texture
if PetAttackModeTexture then
    hooksecurefunc(PetAttackModeTexture, "Show", function()
        ConfigurePetAttackMode()
    end)
    
    -- Hook SetVertexColor to prevent the game from changing it back to white
    hooksecurefunc(PetAttackModeTexture, "SetVertexColor", function(self, r, g, b, a)
        -- Only allow our red color, prevent white/other colors
        if r ~= 1.0 or g ~= 0.0 or b ~= 0.0 then
            self:SetVertexColor(1.0, 0.0, 0.0, a or 1.0)
        end
    end)
end

-- Hook PetFrameFlash Show to apply custom texture
if PetFrameFlash then
    hooksecurefunc(PetFrameFlash, "Show", function()
        ConfigurePetThreatGlow()
    end)
end
