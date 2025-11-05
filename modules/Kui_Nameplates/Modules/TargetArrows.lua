--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
-- Backported by: Kader at https://github.com/bkader
]]
local addon = LibStub("AceAddon-3.0"):GetAddon("KuiNameplates")
local mod = addon:NewModule("TargetArrows", "AceEvent-3.0")

local arrowSize

-- messages ####################################################################
function mod:PostCreate(msg, f)
	local ta = CreateFrame("Frame", nil, f)
	ta:SetFrameLevel(1) -- same as castbar/healthbar

	ta.left = ta:CreateTexture(nil, "ARTWORK", nil, -1)
	ta.left:SetTexture("Interface\\AddOns\\DrakeishUI\\modules\\Kui_Nameplates\\Media\\target-arrow3")
	ta.left:SetPoint("RIGHT", f.overlay, "RIGHT", 22, 0)
	ta.left:SetSize(arrowSize-8, arrowSize-8)

	ta.right = ta:CreateTexture(nil, "ARTWORK", nil, -1)
	ta.right:SetTexture("Interface\\AddOns\\DrakeishUI\\modules\\Kui_Nameplates\\Media\\target-arrow3")
	ta.right:SetPoint("LEFT", f.overlay, "LEFT", -22, 0)
	ta.right:SetTexCoord(1, 0, 0, 1)
	ta.right:SetSize(arrowSize-8, arrowSize-8)

	ta.left:SetVertexColor(unpack(addon.db.profile.general.targetglowcolour))
	ta.right:SetVertexColor(unpack(addon.db.profile.general.targetglowcolour))

	ta:Hide()
	f.targetArrows = ta
end
function mod:PostHide(msg, f)
	f.targetArrows:Hide()
end
function mod:PostTarget(msg, f, is_target)
	if not f.targetArrows then
		return
	end
	if is_target then
		f.targetArrows:Show()
	else
		f.targetArrows:Hide()
	end
end
-- register ####################################################################
function mod:OnInitialize()
	self:SetEnabledState(addon.db.profile.general.targetarrows)
end
function mod:OnEnable()
	arrowSize = floor(addon.sizes.tex.targetArrow)

	self:RegisterMessage("KuiNameplates_PostCreate", "PostCreate")
	self:RegisterMessage("KuiNameplates_PostTarget", "PostTarget")
	self:RegisterMessage("KuiNameplates_PostHide", "PostHide")
end