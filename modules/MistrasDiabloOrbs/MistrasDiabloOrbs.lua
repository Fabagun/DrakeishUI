-- Author      : John Rubin - "Mistra50"
-- Create Date : 8/8/2012 9:03:35 PM
-- Mistra's D3Orbs - rewrite of the previous oUF_D3Orbs_LightWeight
-- The orbs originally appeared in the RothUI by "Zork" and permissive use of all assets and code was given by the original author. 
-- The code in this addon has small chunks of the original still within, but the majority has been rewritten to be free of any external API by John Rubin, aka "Mistra"

--Copyright (C) 2012 John Rubin

--Standard DBAD License.  A mix of MIT and please get my permission before you copy this code license.

--Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--The above copyright holder is notified of the intent of redistribution prior to the release of said redistribution.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



--register the addon message prefix
-- RegisterAddonMessagePrefix("D32")

--variable setup
D32localizedDisplayName, D32className, D32classNumber = UnitClass("player")
local charClassNumber = 0
local playerInVehicle --bool for detecting whether or not a player is in a vehicle
local defaultOrbSize = 150
local orbFillingTexture = "MDO_orb_filling8.tga"
local fillRotationTexture = "orb_fillRotation"
local images = "Interface\\AddOns\\DrakeishUI\\modules\\MistrasDiabloOrbs\\images\\"
local fonts = "Interface\\AddOns\\DrakeishUI\\modules\\MistrasDiabloOrbs\\fonts\\"
healthOrb = nil 
manaOrb = nil
local vehicleInUse

--smooth animation variables
local lastHealthValue, newHealthValue

--color preset definitions per class and assignment


local orbClassColors = {
	[0] = {health = {r = 0.78, g = 0.61, b = 0.43, a= 1}, mana = {r = 0.8, g = 0, b = 0, a= 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Warrior"}, --warrior preset

	[1] = {health = {r = 0.96, b = 0.55, b = 0.73, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Paladin"}, --paladin preset

	[2] = {health = {r = 0.67, g = 0.83, b = 0.45, a = 1},mana = {r = 1.1, g = 0.5, b = 0.25, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Hunter"}, --hunter preset

	[3] = {health = {r = 1.00, g = 0.96, b = 0.41, a = 1},mana = {r = 1.00, g = 0.96, b = 0.41, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Rogue"}, --rogue preset

	[4] = {health = {r = 1.00, g = 1.00, b = 1.00, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Priest"}, --priest preset

	[5] = {health = {r = 0.77, g = 0.12, b = 0.23, a = 1},mana = {r = 0.35, g = 0.9, b = 0.9, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Death Knight"}, --death knight preset

	[6] = {health = {r = 0.0, g = 0.44, b = 0.87, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1}, animation = "SPELLS\\WhiteRadiationFog.m2", name = "Shaman"}, -- shaman preset

	[7] = {health = {r = 0.41, g = 0.80, b = 0.94, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Mage"}, --mage preset

	[8] = {health = {r = 0.58, g = 0.51, b = 0.79, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Warlock"}, --warlock preset

	[9] = {health = {r = 0.33, g = 0.54, b = 0.52, a = 1},mana = {r = 1.00, g = 1.00, b = 1.00, a = 1},  animation = "SPELLS\\GreenRadiationFog.m2", name = "Monk"}, --monk preset

	[10] = {health = {r = 1.00, g = 0.49, b = 0.04, a = 1},mana = {r = 0.0, g = 0.44, b = 0.87, a = 1},  animation = "SPELLS\\WhiteRadiationFog.m2", name = "Druid"} --druid preset
}

local fontChoices = {
	[0] = "Interface\\AddOns\\DrakeishUI\\modules\\MistrasDiabloOrbs\\fonts\\Of Wildflowers and Wings.ttf",
	[1] = "FONTS\\FRIZQT__.ttf"  
}



local function getClassColor()
	if D32classNumber then
		D32className = D32localizedDisplayName
		return D32classNumber - 1
	else
		local num = table.getn(orbClassColors)
		for i=0,num,1 do
		if orbClassColors[i].name == UnitClass("player") then
			D32className = UnitClass("player")
			return i 
		end
	end
	return 0
	end
end
charClassNumber = getClassColor()

--load preset D32CharacterData default in the event existing data cannot be recovered
local Hr,Hg,Hb,Ha = orbClassColors[charClassNumber].health.r, orbClassColors[charClassNumber].health.g, orbClassColors[charClassNumber].health.b, orbClassColors[charClassNumber].health.a
local Mr,Mg,Mb,Ma = orbClassColors[charClassNumber].mana.r, orbClassColors[charClassNumber].mana.g, orbClassColors[charClassNumber].mana.b, orbClassColors[charClassNumber].mana.a

local defaultsTable = {
	--health orb vars - always red
	-- font1 = percentage, font2 = value
	-- Default: show value (font2), hide percentage (font1)
	healthOrb = {scale = 1,textures = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"}, orbColor = {r = 1.0, g = 0, b = 0, a= 1}, galaxy = {r = 1.0, g = 0, b = 0, a= 1}, font1 = {r=1,g=1,b=1,a=1,show = false}, font2 = {r=1,g=1,b=1,a=1,show = true}},

	--mana orb vars - uses class colors
	-- font1 = percentage, font2 = value
	-- Default: show value (font2), hide percentage (font1)
	manaOrb = {scale = 1, textures = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"}, orbColor = {r = Mr, g = Mg, b = Mb, a = Ma},galaxy = {r = Mr, g = Mg, b = Mb, a = Ma}, font1 = {r=1,g=1,b=1,a=1,show = false}, font2 = {r=1,g=1,b=1,a=1,show = true}},
	
	--pet orb vars
	-- Default: show value, hide percentage
	petOrb = {scale = 1, enabled = true, showValue = true, showPercentage = false, healthOrb = {r=Hr,g=Hg,b=Hb,a=Ha}, manaOrb={r=Mr,g=Mg,b=Mb,a=Ma}},
	
	--orb fonts
	font = fontChoices[1],
	
	values = {formatted=true},
	
	artwork = {show = false},
	
	powerFrame = {show = true},

	combat = {enabled = true, orbColor = {r = 0.8, g = 0, b = 0, a = 1}, galaxy = {r = 0.8, g = 0, b = 0, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},

	druidColors = {
		cat = {orbColor = {r = 1.00, g = 0.96, b = 0.41, a = 1}, galaxy = {r = 1.00, g = 0.96, b = 0.41, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},
		bear = {orbColor = {r = 0.8, g = 0, b = 0, a= 1}, galaxy = {r = 0.8, g = 0, b = 0, a= 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}},
		moonkin = {orbColor = {r = 0.0, g = 0.44, b = 0.87, a = 1}, galaxy = {r = 0.0, g = 0.44, b = 0.87, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}}, 
		tree = {orbColor = {r = 0.0, g = 0.44, b = 0.87, a = 1}, galaxy = {r = 0.0, g = 0.44, b = 0.87, a = 1}, font1 = {r=1,g=1,b=1,a=1}, font2 = {r=1,g=1,b=1,a=1}}
	},

	defaultPlayerFrame = {show = false}
}

local defaultTextures = {
	healthOrb = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"},
	manaOrb = {fill = "MDO_orb_filling2.tga", rotation = "orb_rotation_bubbles"}
}

D32FillTextureChoices = {
	[0] = images.. "MDO_orb_filling1.tga",
	[1] = images.. "MDO_orb_filling2.tga",
	[2] = images.. "MDO_orb_filling3.tga",
	[3] = images.. "MDO_orb_filling4.tga",
	[4] = images.. "MDO_orb_filling5.tga",
	[5] = images.. "MDO_orb_filling6.tga",
	[6] = images.. "MDO_orb_filling7.tga",
}

D32RotationTextureChoices = {
	[0] = images.. "orb_rotation_galaxy",
	[1] = images.. "orb_rotation_bubbles",
	[2] = images.. "orb_rotation_iris"
}

----------------------------------------------------------Main Data Table for each character -----------------------------------------------------------------
D32CharacterData = defaultsTable
D32Textures = defaultTextures
---------------------------------------------------------------------------------------------------------------------------------------------------------------

function handlePlayerFrame(show)
	if show then
		PlayerFrame:SetScript("OnEvent",PlayerFrame_OnEvent)
		PlayerFrame:Show()
	else
		PlayerFrame:SetScript("OnEvent",nil)
		PlayerFrame:Hide()
	end
end

--hide the player frame by default... we have a pet orb now, so people shouldn't be asking for it anymore.... maybe
--handlePlayerFrame(D32CharacterData.defaultPlayerFrame.show)


--function to make any frame object movable
local function makeFrameMovable(frame,button)
	local btnString = "LeftButton"
	if button then
		btnString = button
	end

	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag(btnString)
	frame:SetScript("OnDragStart", function(self) 
		if IsShiftKeyDown() then
			self:StartMoving()
		end
	 end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
end

local function valueFormat(val,petOverride)
	local newVal = val
	if D32CharacterData.values.formatted == true then
		if val > 1000000 then
			newVal = (floor((val/1000000)*10)/10) .."m"
		elseif val > 99999 then
			newVal = (floor((val/1000)*10)/10) .."k"
		end
	end
	if petOverride then
		if val > 10000 then
			newVal = (floor((val/1000)*10)/10).."k"
		end
	end
	return newVal
end

local previousHealthValue = UnitHealth("player")
function monitorHealth(orb)
	local unitHealthString = "player"
	if vehicleInUse == 1 then
		unitHealthString = "vehicle"
	end
	local maxHealth = UnitHealthMax(unitHealthString)
	if not tonumber(maxHealth) or maxHealth == 0 then maxHealth = 1 end
	local currentHealth = UnitHealth(unitHealthString)
	if not tonumber(currentHealth) then currentHealth = 1 end
	local healthPercentage = currentHealth/maxHealth
	local inverseHealthPercentage = math.abs(healthPercentage - 1)

	local step = 0
	local onePercentHealth = maxHealth / 100

	local newValue = previousHealthValue
	if previousHealthValue < currentHealth then
		step = 1
		if previousHealthValue + (onePercentHealth * step) > currentHealth then
			newValue = currentHealth
		else
			newValue = previousHealthValue + (onePercentHealth * step)
		end
	elseif previousHealthValue > currentHealth then
		step = -1
		if previousHealthValue + (onePercentHealth * step) < currentHealth then
			newValue = currentHealth
		else
			newValue = previousHealthValue + (onePercentHealth * step)
		end
	end
	previousHealthValue = newValue

	local targetTexHeight = (previousHealthValue/maxHealth * orb.filling:GetWidth())
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousHealthValue/maxHealth
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 1
		targetTexHeight = orb.filling:GetWidth()
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	
	-- Only show text when player is selected (targeted)
	if UnitIsUnit("player", "target") then
		-- Show fonts based on saved settings (monitorHealth is always called with healthOrb)
		if D32CharacterData and D32CharacterData.healthOrb then
			if D32CharacterData.healthOrb.font1.show then orb.font1:Show() else orb.font1:Hide() end
			if D32CharacterData.healthOrb.font2.show then orb.font2:Show() else orb.font2:Hide() end
		else
			orb.font1:Show()
			orb.font2:Show()
		end
		orb.font1:SetText(string1)
		local string = valueFormat(currentHealth)
		orb.font2:SetText(string)
		if UnitIsDead(unitHealthString) then
			orb.font2:SetText("DEAD :'(")
		end
	else
		orb.font1:Hide()
		orb.font2:Hide()
		orb.font1:SetText("")
		orb.font2:SetText("")
	end

	orb.filling:SetHeight(targetTexHeight)
	orb.filling:SetTexCoord(0,1,math.abs(newDisplayPercentage - 1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage)
	orb.galaxy2:SetAlpha(newDisplayPercentage)
	orb.galaxy3:SetAlpha(newDisplayPercentage)
end

local previousPowerValue = UnitPower("player")
function monitorPower(orb)
	local unitPowerString = "player"
	if vehicleInUse == 1 then
		unitPowerString = "vehicle"
	end
	local maxPower = UnitPowerMax(unitPowerString)
	if not tonumber(maxPower) or maxPower == 0 then maxPower = 1 end
	local currentPower = UnitPower(unitPowerString)
	if not tonumber(currentPower) then currentPower = 1 end
	local powerPercentage = currentPower/maxPower
	local inversePowerPercentage = math.abs(powerPercentage - 1)

	local step = 0
	local fillPercentage = 100
	local onePercentPower = maxPower / fillPercentage

	local newValue = previousPowerValue
	if previousPowerValue < currentPower then
		step = 1
		if previousPowerValue + (onePercentPower * step) > currentPower then
			newValue = currentPower
		else
			newValue = previousPowerValue + (onePercentPower * step)
		end
	elseif previousPowerValue > currentPower then
		step = -1
		if previousPowerValue + (onePercentPower * step) < currentPower then
			newValue = currentPower
		else
			newValue = previousPowerValue + (onePercentPower * step)
		end
	end
	previousPowerValue = newValue

	local targetTexHeight = (previousPowerValue/maxPower * orb.filling:GetWidth())
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPowerValue / maxPower
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 1
		targetTexHeight = orb.filling:GetWidth()
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	
	-- Only show text when player is selected (targeted)
	if UnitIsUnit("player", "target") then
		-- Show fonts based on saved settings (monitorPower is always called with manaOrb)
		if D32CharacterData and D32CharacterData.manaOrb then
			if D32CharacterData.manaOrb.font1.show then orb.font1:Show() else orb.font1:Hide() end
			if D32CharacterData.manaOrb.font2.show then orb.font2:Show() else orb.font2:Hide() end
		else
			orb.font1:Show()
			orb.font2:Show()
		end
		orb.font1:SetText(string1)
		local string = valueFormat(currentPower)
		orb.font2:SetText(string)
		if UnitIsDead(unitPowerString) then
			orb.font2:SetText("DEAD :'(")
		end
	else
		orb.font1:Hide()
		orb.font2:Hide()
		orb.font1:SetText("")
		orb.font2:SetText("")
	end

	orb.filling:SetHeight(targetTexHeight)
	orb.filling:SetTexCoord(0,1,math.abs(newDisplayPercentage-1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage)
	orb.galaxy2:SetAlpha(newDisplayPercentage)
	orb.galaxy3:SetAlpha(newDisplayPercentage)
end

local previousPetHealth = UnitHealth("pet")
local function PetHealthUpdate(orb)
	local unitHealthString = "pet"
	local maxHealth = UnitHealthMax(unitHealthString)
	if not tonumber(maxHealth) or maxHealth == 0 then maxHealth = 1 end
	local currentHealth = UnitHealth(unitHealthString)
	if not tonumber(currentHealth) then currentHealth = 0 end
	local healthPercentage = currentHealth/maxHealth
	local inverseHealthPercentage = math.abs(healthPercentage - 1)

	local step = 0
	local onePercentHealth = maxHealth / 100

	local newValue = previousPetHealth
	if previousPetHealth < currentHealth then
		step = 1
		if previousPetHealth + (onePercentHealth * step) > currentHealth then
			newValue = currentHealth
		else
			newValue = previousPetHealth + (onePercentHealth * step)
		end
	elseif previousPetHealth > currentHealth then
		step = -1
		if previousPetHealth + (onePercentHealth * step) < currentHealth then
			newValue = currentHealth
		else
			newValue = previousPetHealth + (onePercentHealth * step)
		end
	end
	previousPetHealth = newValue

	-- Calculate height based on available space (width minus the 2px bottom offset adjustment)
	-- The texture is positioned at BOTTOMLEFT(4,3), so max height is the width
	local maxHeight = orb.filling1:GetWidth()  -- size - 6
	local targetTexHeight = (previousPetHealth/maxHealth * maxHeight)
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPetHealth/maxHealth
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 1
		targetTexHeight = maxHeight
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	
	-- Only show text when pet is selected (targeted)
	if UnitIsUnit("pet", "target") then
		orb.font1:SetText(string1)
		local string = valueFormat(currentHealth,true)
		orb.font3:SetText(string)
	else
		orb.font1:SetText("")
		orb.font3:SetText("")
	end

	-- Ensure position is maintained before setting height
	orb.filling1:SetPoint("BOTTOMLEFT",4,3)
	orb.filling1:SetHeight(targetTexHeight)
	orb.filling1:SetTexCoord(0,1,math.abs(newDisplayPercentage - 1),1)
	orb.galaxy1:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy2:SetAlpha(newDisplayPercentage * 0.2)
	orb.galaxy3:SetAlpha(newDisplayPercentage * 0.2)
end

-- Function to update pet orb power color based on pet's power type
local function UpdatePetOrbPowerColor(orb)
	if not orb or not orb.filling2 then return end
	
	-- Check if pet exists
	if not UnitExists("pet") then return end
	
	local powerType = UnitPowerType("pet")
	
	-- Use Blizzard's PowerBarColor table for standard power colors (same as target frame)
	-- This ensures consistency with the game's UI
	local color = PowerBarColor[powerType] or PowerBarColor["MANA"]
	
	if powerType == 0 then
		-- Mana: use mana orb color for consistency with player mana orb
		if manaOrb and manaOrb.filling then
			orb.filling2:SetVertexColor(manaOrb.filling:GetVertexColor())
		else
			-- Fallback to standard mana color
			orb.filling2:SetVertexColor(color.r, color.g, color.b, 1.0)
		end
	else
		-- For all other power types (Focus, Energy, Rage, etc.), use Blizzard's standard color
		orb.filling2:SetVertexColor(color.r, color.g, color.b, 1.0)
	end
end

local previousPetPower = UnitPower("pet")
local function PetPowerUpdate(orb)
	local unitPowerString = "pet"
	local maxPower = UnitPowerMax(unitPowerString)
	if not tonumber(maxPower) or maxPower == 0 then maxPower = 1 end
	local currentPower = UnitPower(unitPowerString)
	if not tonumber(currentPower) then currentPower = 0 end
	local powerPercentage = currentPower/maxPower
	local inversePowerPercentage = math.abs(powerPercentage - 1)
	
	-- Update pet orb power color based on power type
	UpdatePetOrbPowerColor(orb)

	local step = 0
	local fillPercentage = 100
	local onePercentPower = maxPower / fillPercentage

	local newValue = previousPetPower
	if previousPetPower < currentPower then
		step = 1
		if previousPetPower + (onePercentPower * step) > currentPower then
			newValue = currentPower
		else
			newValue = previousPetPower + (onePercentPower * step)
		end
	elseif previousPetPower > currentPower then
		step = -1
		if previousPetPower + (onePercentPower * step) < currentPower then
			newValue = currentPower
		else
			newValue = previousPetPower + (onePercentPower * step)
		end
	end
	previousPetPower = newValue

	local targetTexHeight = (previousPetPower/maxPower * (85 * orb:GetScale()))
	if targetTexHeight < 1 then targetTexHeight = 1 end
	local newDisplayPercentage = previousPetPower / maxPower
	if newDisplayPercentage > 1 then
		newDisplayPercentage = 0
		targetTexHeight = 1
	end
	local string1 = math.floor(newDisplayPercentage*100)
	if tonumber(string1) == nil then string1 = 0 end
	
	-- Only show text when pet is selected (targeted)
	if UnitIsUnit("pet", "target") then
		orb.font2:SetText(string1)
		local string = valueFormat(currentPower,true)
		orb.font4:SetText(string)
	else
		orb.font2:SetText("")
		orb.font4:SetText("")
	end

	orb.filling2:SetHeight(targetTexHeight)
	orb.filling2:SetTexCoord(0,1,math.abs(newDisplayPercentage-1),1)
end

local function updatePetValues(orb)
	PetHealthUpdate(orb)
	-- Only update health, not power
	-- PetPowerUpdate(orb)
end

local function CreateGalaxy(orb, file, duration,size,x,y)
	local galaxy = CreateFrame("Frame",nil,orb)
	galaxy:SetHeight(size)
	galaxy:SetWidth(size)
	galaxy:SetPoint("Center",x,y)
	galaxy:SetFrameLevel(4)

	local galTex = galaxy:CreateTexture()
	galTex:SetAllPoints(galaxy)
	galTex:SetTexture(file)
	galTex:SetBlendMode("ADD")
	galTex:SetAlpha(1)
	galaxy.texture = galTex
	
	local animGroup = galaxy:CreateAnimationGroup()
	galaxy.animGroup = animGroup

	local anim1 = galaxy.animGroup:CreateAnimation("Rotation")
	anim1:SetDegrees(360)
	anim1:SetDuration(duration)
	galaxy.animGroup.anim1 = anim1

	animGroup:Play()
	animGroup:SetLooping("REPEAT")
	
	return galaxy
end 

local function CreateGlow(orb)
	local glow = CreateFrame("PlayerModel",nil, orb)
	glow:SetFrameStrata("BACKGROUND")
	glow:SetFrameLevel(5)
	glow:SetAllPoints(orb)
	glow:SetModel(orbClassColors[charClassNumber].animation)
	glow:SetAlpha(1)
	glow:SetScript("OnShow",function()
		glow:SetModel(orbClassColors[charClassNumber].animation)
		glow:SetModelScale(1)
		glow:SetPosition(0,0,0)
	end)
	orb.glow = glow
end

local function menu()
	ToggleDropDownMenu(1, nil,"PlayerFrameDropDown", "cursor", 0, 0)
end

--orb creation experiment
local function CreateOrb(parent,name,size,fillTexture,galaxyTexture,offsetX,offsetY,relativePoint,monitorFunc)
	local orb
	orb = CreateFrame("Button",name,UIParent,"SecureActionButtonTemplate")
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("BACKGROUND")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling:SetTexture(images..fillTexture)
	orb.filling:SetPoint("BOTTOMLEFT",3,3)
	orb.filling:SetWidth(defaultOrbSize - 6)
	orb.filling:SetHeight(defaultOrbSize - 6)
	orb.filling:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)
	local orbBorderHolder = CreateFrame("Frame",nil,orb)
	orbBorderHolder:SetAllPoints(orb)
	orbBorderHolder:SetFrameStrata("MEDIUM")
	orbBorderHolder:SetFrameLevel(1)
	orb.border = orbBorderHolder:CreateTexture(nil,"OVERLAY")
	orb.border:SetTexture(images .. "orb_border.tga")
	orb.border:SetAllPoints(orbBorderHolder)
	-- Mirror border horizontally for mana orb
	if name == "D32_ManaOrb" then
		orb.border:SetTexCoord(1, 0, 0, 1)
	end
	local newRand = math.random(20,50)
	orb.galaxy1 = CreateGalaxy(orb, images..galaxyTexture.."1.tga",newRand,defaultOrbSize-5,0,0)
	newRand = math.random(30,70)
	orb.galaxy2 = CreateGalaxy(orb,images..galaxyTexture.."2.tga", newRand,defaultOrbSize-5,0,0)
	newRand = math.random(18,27)
	orb.galaxy3 = CreateGalaxy(orb,images..galaxyTexture.."3.tga", newRand,defaultOrbSize-5,0,0)
	CreateGlow(orb)
	orb:SetScript("OnUpdate",monitorFunc)
	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetFrameLevel(2)
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
	orb.font1:SetPoint("CENTER",0,35)
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
	orb.font2:SetPoint("CENTER",0,15)
	
	--position defaults
	orb:ClearAllPoints()
	orb:SetPoint(relativePoint,nil,relativePoint,offsetX,offsetY)
	
	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling:SetVertexColor(1,1,1,1)

	--setup mouseover/click/rightclick events
	orb.menu = function(orb) ToggleDropDownMenu(1, 1, PlayerFrameDropDown, "cursor", 0 ,0) end
	orb:RegisterForClicks("AnyUp")
	orb:SetAttribute("type1","target")
	orb:SetAttribute("type2","menu")
	orb:SetAttribute("unit","player")
	orb.tooltip = CreateFrame("GameTooltip","PlayerTooltip",nil,"GameToolTipTemplate")
	orb:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
		GameTooltip:SetUnit("player")
		GameTooltip:Show()
	end)
	orb:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)


	--place setup the appropriate character events on the health orb
	return orb
end

local function CreatePetOrb(parent,name,size,offsetX,offsetY,relativePoint,monitorFunc)
	local orb
	-- Use UIParent if parent is nil (like main orbs), otherwise use the provided parent
	orb = CreateFrame("Button",name,parent or UIParent,"SecureActionButtonTemplate")
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("BACKGROUND")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling1 = orb:CreateTexture(nil,"BACKGROUND")
	-- Use the same texture as the player health orb
	orb.filling1:SetTexture(images..defaultTextures.healthOrb.fill)
	-- Position: 1px right from standard (4 instead of 3), but keep bottom at 3 to fill to border
	orb.filling1:SetPoint("BOTTOMLEFT",4,3)  -- 1px right (4), standard bottom (3)
	orb.filling1:SetWidth(size - 6)  -- Full width with 3px margin on each side
	orb.filling1:SetHeight(size - 6)  -- Full height to match width (square texture)
	orb.filling1:SetAlpha(1)
	-- Hide power filling - we only show health
	orb.filling2 = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling2:SetTexture(images.."petFilling_power.tga")
	orb.filling2:SetPoint("BOTTOMRIGHT",-3,0)
	orb.filling2:SetWidth(size / 2 - 3)
	orb.filling2:SetHeight(size - 6)
	orb.filling2:SetAlpha(0)  -- Hide power filling
	orb.filling2:Hide()
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)
	
	local orbBorderHolder = CreateFrame("Frame",nil,orb)
	orbBorderHolder:SetAllPoints(orb)
	orbBorderHolder:SetFrameStrata("MEDIUM")
	orbBorderHolder:SetFrameLevel(1)
	orb.border = orbBorderHolder:CreateTexture(nil,"OVERLAY")
	orb.border:SetTexture(images .. "orb_border_pet.tga")
	orb.border:SetAllPoints(orbBorderHolder)
	
	-- Hide divider - we only show health, no need to divide the orb
	orb.divider = CreateFrame("Frame",nil,orb)
	orb.divider.texture = orb.divider:CreateTexture(nil,"OVERLAY")
	orb.divider.texture:SetTexture(images.."middleBar.tga")
	orb.divider:SetAllPoints(true)
	orb.divider.texture:SetAllPoints(true)
	orb.divider:Hide()  -- Hide divider since we only show health
	orb.galaxy1 = CreateGalaxy(orb, D32RotationTextureChoices[1].."1.tga",36,size-8,0,0)
	orb.galaxy2 = CreateGalaxy(orb, D32RotationTextureChoices[1].."2.tga", 22,size-8,0,0)
	orb.galaxy3 = CreateGalaxy(orb, D32RotationTextureChoices[1].."3.tga", 29,size-8,0,0)
	orb.galaxy1:SetAlpha(0.3)
	orb.galaxy2:SetAlpha(0.3)
	orb.galaxy3:SetAlpha(0.3)
	CreateGlow(orb)
	
	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetFrameLevel(2)
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font1:SetPoint("CENTER",0,5)  -- Center it since we only show health
	orb.font1:SetText("100")
	-- Hide power-related fonts (font2 and font4) - we only show health
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,14,"THINOUTLINE")
	orb.font2:SetPoint("CENTER",20,5)
	orb.font2:SetText("100")
	orb.font2:Hide()  -- Hide power percentage font
	orb.font3 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font3:SetPoint("CENTER",0,-8)  -- Center it since we only show health
	orb.font3:SetText("100")
	orb.font4 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font4:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	orb.font4:SetPoint("CENTER",20,-8)
	orb.font4:SetText("100")
	orb.font4:Hide()  -- Hide power value font
	
	orb:SetScript("OnUpdate",updatePetValues)
	
	--position defaults
	orb:ClearAllPoints()
	-- Use relativePoint if provided (like main orbs), otherwise use CENTER (for backward compatibility)
	if relativePoint then
		orb:SetPoint(relativePoint,nil,relativePoint,offsetX,offsetY)
	elseif parent then
		orb:SetPoint("CENTER",parent,offsetX,offsetY)
	else
		-- Fallback if no parent and no relativePoint
		orb:SetPoint("CENTER",UIParent,offsetX,offsetY)
	end
	
	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	-- Make pet orb red brighter than player orb (multiply RGB by 1.2)
	local r, g, b, a = healthOrb.filling:GetVertexColor()
	orb.filling1:SetVertexColor(math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, b * 1.2), a)
	-- No need to update power color since we only show health
	
	orb.menu = function(orb) ToggleDropDownMenu(1, 1, PetFrameDropDown, "cursor", 0 ,0) end
	orb:RegisterForClicks("AnyUp")
	orb:SetAttribute("type1","target")
	orb:SetAttribute("type2","menu")
	orb:SetAttribute("unit","pet")
	orb.tooltip = CreateFrame("GameTooltip","PetToolTip",nil,"GameToolTipTemplate")
	orb:SetScript("OnEnter", function()
		GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
		GameTooltip:SetUnit("pet")
		GameTooltip:Show()
	end)
	orb:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)
	
	RegisterUnitWatch(orb)

	--place setup the appropriate character events on the health orb
	return orb
end

local function CreateXMLOrb(parent,name,size,fillTexture,galaxyTexture)
	local orb
	orb = CreateFrame("Button",name,parent,nil)
	orb:SetHeight(size)
	orb:SetWidth(size)
	orb:SetFrameStrata("HIGH")
	orb.bg = orb:CreateTexture(nil,"OVERLAY")
	orb.bg:SetTexture(images .. "orb_gloss3.tga")
	orb.bg:SetAllPoints(orb)
	orb.filling = orb:CreateTexture(nil,"BACKGROUND")
	orb.filling:SetTexture(images..fillTexture)
	orb.filling:SetPoint("BOTTOMLEFT",3,3)
	orb.filling:SetWidth(size - 6)
	orb.filling:SetHeight(size-6)
	orb.filling:SetAlpha(1)
	local orbGlossHolder = CreateFrame("Frame",nil,orb)
	orbGlossHolder:SetAllPoints(orb)
	orbGlossHolder:SetFrameStrata("LOW")
	local orbGlossOverlay = orbGlossHolder:CreateTexture(nil,"BACKGROUND")
	orbGlossOverlay:SetTexture(images .. "orb_gloss3.tga")
	orbGlossOverlay:SetAllPoints(orbGlossHolder)
	local newRand = math.random(20,50)
	orb.galaxy1 = CreateGalaxy(orb, images..galaxyTexture.."1.tga",newRand,size-3,0,0)
	newRand = math.random(30,70)
	orb.galaxy2 = CreateGalaxy(orb,images..galaxyTexture.."2.tga", newRand,size-3,0,0)
	newRand = math.random(18,27)
	orb.galaxy3 = CreateGalaxy(orb,images..galaxyTexture.."3.tga", newRand,size-3,0,0)
	
	CreateGlow(orb)
	orb.fontHolder = CreateFrame("FRAME",nil,orb)
	orb.fontHolder:SetFrameStrata("MEDIUM")
	orb.fontHolder:SetFrameLevel(2)
	orb.fontHolder:SetAllPoints(orb)
	orb.font1 = orb.fontHolder:CreateFontString(nil, "OVERLAY")
	orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
	orb.font1:SetText("100")
	orb.font1:SetPoint("CENTER",0,35)
	orb.font2 = orb.fontHolder:CreateFontString(nil,"OVERLAY")
	orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
	orb.font2:SetText("100000")
	orb.font2:SetPoint("CENTER",0,15)
	
	--position defaults
	orb:ClearAllPoints()
	orb:SetAllPoints(xmlOrbDisplayFrame2)
	
	--show the orb
	orb:Show()

	--fill the orb with colors! WOO!
	orb.filling:SetVertexColor(1,1,1,1)
	return orb
end

local function addArtwork(file,orb,name,offsetX,offsetY,height,width)
	local art = CreateFrame("Frame","D32"..name,orb)
	art:SetPoint("CENTER",offsetX,offsetY)
	art:SetHeight(height)
	art:SetWidth(width)
	art:SetFrameStrata("MEDIUM")
	art:SetFrameLevel(3)
	art.texture = art:CreateTexture(nil,"OVERLAY")
	art.texture:SetTexture(file)
	art.texture:SetAllPoints(art)
	return art
end

function D32SetGlobalScale(val)
	val = val/100
	healthOrb:SetScale(val)
	D32CharacterData.healthOrb.scale = val
	manaOrb:SetScale(val)
	D32CharacterData.manaOrb.scale = val
end

function D32MonitorPowers(frame)
	local powerType
	powerFrame.text:SetPoint("CENTER",-1,0)
	if D32className == "Warlock" then
		local maxResource = 0
		local usable, nomana = IsUsableSpell("Metamorphosis")
		if usable or (not usable and nomana) then
			powerType = 15
			maxResource = 1000
		end
		usable, nomana = IsUsableSpell("Chaos Bolt")
		if usable or (not usable and nomana) then
			powerType = 14
			maxResource = 3
		end
		usable, nomana = IsUsableSpell("Soulburn")
		if usable or (not usable and nomana) then
			powerType = 7
			maxResource = 3
		end
		local numShards = UnitPower("player",powerType)
		if powerType == 14 then
			numShards = (UnitPower("player",powerType,true)/10)
		end
		if numShards > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		if numShards > 999 then
			powerFrame.text:SetFont(D32CharacterData.font,15,"THINOUTLINE")
		elseif numShards > 99 then
			powerFrame.text:SetFont(D32CharacterData.font,18,"THINOUTLINE")
		elseif numShards > 9 then
			powerFrame.text:SetFont(D32CharacterData.font,24,"THINOUTLINE")
		else
			powerFrame.text:SetFont(D32CharacterData.font,26,"THINOUTLINE")
		end
		frame.text:SetText(numShards)
		if numShards > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		else
			powerFrame.text:SetPoint("CENTER",0,0)
		end
		if numShards >= maxResource then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Paladin" then
		powerType = 9
		local numHolyPower = UnitPower("player",powerType)
		if numHolyPower > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(numHolyPower)
		if numHolyPower > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if numHolyPower >=3 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Monk" then
		powerType = 12
		local numHolyPower = UnitPower("player",powerType)
		if numHolyPower > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(numHolyPower)
		if numHolyPower > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if numHolyPower >=4 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Priest" then
		powerType = 13
		local numHolyPower = UnitPower("player",powerType)
		if numHolyPower > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(numHolyPower)
		if numHolyPower > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if numHolyPower >=3 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Rogue" or D32className == "Druid" then
		local comboPoints = GetComboPoints("player","target")
		if comboPoints > 0 then
			if not frame.backDrop:IsVisible() then
				frame.backDrop:Show()
				frame.text:Show()
			end
		else
			if frame.backDrop:IsVisible() then
				frame.backDrop:Hide()
				frame.text:Hide()
			end
		end
		frame.text:SetText(comboPoints)
		if comboPoints > 1 then
			powerFrame.text:SetPoint("CENTER",1,0)
		end
		if comboPoints >=5 then
			powerFrame.fontHolder.animGroup:Play()
		else
			powerFrame.fontHolder.animGroup:Stop()
		end
	elseif D32className == "Mage" then
		--turns out there is no way to track the ice shards for Mage.  Stubbed for now.
	end

end

local function createPowerFrame(file,orb,name,offsetX,offsetY,height,width)
	local powerFrame = CreateFrame("Frame","D32"..name,orb)
	powerFrame:SetFrameStrata("BACKGROUND")
	powerFrame:SetPoint("CENTER",offsetX,offsetY)
	powerFrame:SetHeight(height)
	powerFrame:SetWidth(width)
	
	--gradient backdrop
	powerFrame.backDrop = CreateFrame("Frame","D32"..name.."Backdrop",powerFrame)
	powerFrame.backDrop:SetAllPoints(true)
	powerFrame.backDrop.backTexture = powerFrame.backDrop:CreateTexture(nil,"BACKGROUND")
	powerFrame.backDrop.backTexture:SetTexture(images.."d32_powerFrame_backdrop.tga")
	powerFrame.backDrop.backTexture:SetAllPoints(powerFrame)
	
	--shadowed frame, colorizable
	powerFrame.texture = powerFrame.backDrop:CreateTexture(nil,"OVERLAY")
	powerFrame.texture:SetTexture(file)
	powerFrame.texture:SetVertexColor(D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a)
	powerFrame.texture:SetAllPoints(true)
	
	--fontholder frame for animations
	powerFrame.fontHolder = CreateFrame("Frame",nil,powerFrame)
	powerFrame.fontHolder:SetFrameStrata("LOW")
	powerFrame.fontHolder:SetAllPoints(true)
	
	--text
	powerFrame.text = powerFrame.fontHolder:CreateFontString(nil,"OVERLAY")
	powerFrame.text:SetFont(D32CharacterData.font,29,"THINOUTLINE")
	powerFrame.text:SetPoint("CENTER",0,1)
	powerFrame.text:SetTextColor(D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a)
	powerFrame.text:SetText("1")
	
	local animGroup = powerFrame.fontHolder:CreateAnimationGroup()
	powerFrame.fontHolder.animGroup = animGroup
	
	local anim1 = powerFrame.fontHolder.animGroup:CreateAnimation("Alpha")
	anim1:SetChange(-1)
	anim1:SetOrder(1)
	anim1:SetDuration(.7)
	powerFrame.fontHolder.anim1 = anim1
	
	local anim2 = powerFrame.fontHolder.animGroup:CreateAnimation("Alpha")
	anim2:SetChange(1)
	anim2:SetOrder(2)
	anim2:SetDuration(.7)
	powerFrame.fontHolder.anim2 = anim2
	
	animGroup:SetLooping("REPEAT")
	
	
	--updates and wh
	powerFrame:SetScript("OnUpdate",D32MonitorPowers)
	powerFrame:Show()
	
	return powerFrame
end


function checkPetFontPlacement()
	-- Only show health fonts (font1 and font3), hide power fonts (font2 and font4)
	-- Center fonts since we only show health
	if D32CharacterData.petOrb.showValue and D32CharacterData.petOrb.showPercentage then
		petOrb.font3:Show()
		petOrb.font4:Hide()  -- Hide power value
		petOrb.font1:Show()
		petOrb.font2:Hide()  -- Hide power percentage
		petOrb.font3:SetPoint("CENTER",0,7)  -- Center health value
		petOrb.font1:SetPoint("CENTER",0,20)  -- Center health percentage
		petOrb.font3:SetFont(D32CharacterData.font,9,"THINOUTLINE")
	elseif D32CharacterData.petOrb.showValue and not D32CharacterData.petOrb.showPercentage then
		petOrb.font3:Show()
		petOrb.font4:Hide()  -- Hide power value
		petOrb.font1:Hide()
		petOrb.font2:Hide()  -- Hide power percentage
		petOrb.font3:SetPoint("CENTER",0,0)  -- Center health value
		petOrb.font3:SetFont(D32CharacterData.font,11 * petOrb:GetScale(),"THINOUTLINE")
	elseif not D32CharacterData.petOrb.showValue and D32CharacterData.petOrb.showPercentage then
		petOrb.font1:Show()
		petOrb.font2:Hide()  -- Hide power percentage
		petOrb.font3:Hide()
		petOrb.font4:Hide()  -- Hide power value
		petOrb.font1:SetPoint("CENTER",0,0)  -- Center health percentage
	else
		petOrb.font1:Hide()
		petOrb.font2:Hide()
		petOrb.font3:Hide()
		petOrb.font4:Hide()
	end
end

function setOrbFontPlacement(orb,orbData)
	-- Hide fonts by default - they will be shown when player is selected (in monitorHealth/monitorPower)
	orb.font1:Hide()
	orb.font2:Hide()
	if orbData.font1.show and orbData.font2.show then
		orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
		orb.font1:SetPoint("CENTER",0,35)
		orb.font2:SetPoint("CENTER",0,15)
	elseif orbData.font1.show and not orbData.font2.show then
		orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		orb.font1:SetPoint("CENTER",0,20)
		orb.font2:Hide()
	elseif orbData.font2.show and not orbData.font1.show then
		orb.font2:SetFont(D32CharacterData.font,25,"THINOUTLINE")
		orb.font2:SetPoint("CENTER",0,20)
		orb.font1:Hide()
	else
		orb.font1:Hide()
		orb.font2:Hide()
	end
end

function checkXMLOrbFontPlacement()
	xmlOrbDisplayFrame2.orb.font1:Show()
	xmlOrbDisplayFrame2.orb.font2:Show()
	if D32OrbPercentageCheckBox:GetChecked() and D32OrbValueCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font1:SetFont(D32CharacterData.font,28,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font2:SetFont(D32CharacterData.font,16,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font1:SetPoint("CENTER",0,35)
		xmlOrbDisplayFrame2.orb.font2:SetPoint("CENTER",0,15)
	elseif D32OrbPercentageCheckBox:GetChecked() and not D32OrbValueCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font1:SetFont(D32CharacterData.font,32,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font1:SetPoint("CENTER",0,20)
		xmlOrbDisplayFrame2.orb.font2:Hide()
	elseif D32OrbValueCheckBox:GetChecked() and not D32OrbPercentageCheckBox:GetChecked() then
		xmlOrbDisplayFrame2.orb.font2:SetFont(D32CharacterData.font,32,"THINOUTLINE")
		xmlOrbDisplayFrame2.orb.font2:SetPoint("CENTER",0,20)
		xmlOrbDisplayFrame2.orb.font1:Hide()
	else
		xmlOrbDisplayFrame2.orb.font1:Hide()
		xmlOrbDisplayFrame2.orb.font2:Hide()
	end
end

function resetXMLTextBoxes()
	D32OrbPercentageCheckBox:SetChecked(CommitButton.orbData.font1.show)
	D32OrbValueCheckBox:SetChecked(CommitButton.orbData.font2.show)
end

function checkDefaultsFromMemory()
	if not D32CharacterData.healthOrb then D32CharacterData.healthOrb = defaultsTable.healthOrb end
	if not D32CharacterData.healthOrb.textures then D32CharacterData.healthOrb.textures = defaultTextures.healthOrb end
	-- Force health orb to always be red
	if not D32CharacterData.healthOrb.orbColor then D32CharacterData.healthOrb.orbColor = {r = 1.0, g = 0, b = 0, a = 1} end
	if not D32CharacterData.healthOrb.galaxy then D32CharacterData.healthOrb.galaxy = {r = 1.0, g = 0, b = 0, a = 1} end
	D32CharacterData.healthOrb.orbColor.r = 1.0
	D32CharacterData.healthOrb.orbColor.g = 0
	D32CharacterData.healthOrb.orbColor.b = 0
	D32CharacterData.healthOrb.galaxy.r = 1.0
	D32CharacterData.healthOrb.galaxy.g = 0
	D32CharacterData.healthOrb.galaxy.b = 0
	if D32CharacterData.healthOrb.font1.show == nil then D32CharacterData.healthOrb.font1.show = defaultsTable.healthOrb.font1.show end
	if D32CharacterData.healthOrb.font2.show == nil then D32CharacterData.healthOrb.font2.show = defaultsTable.healthOrb.font2.show end
	if not D32CharacterData.manaOrb then D32CharacterData.manaOrb = defaultsTable.manaOrb end
	if not D32CharacterData.manaOrb.textures then D32CharacterData.manaOrb.textures = defaultTextures.manaOrb end
	-- Ensure mana orb uses class colors
	if not D32CharacterData.manaOrb.orbColor then D32CharacterData.manaOrb.orbColor = {r = Mr, g = Mg, b = Mb, a = Ma} end
	if not D32CharacterData.manaOrb.galaxy then D32CharacterData.manaOrb.galaxy = {r = Mr, g = Mg, b = Mb, a = Ma} end
	-- Update mana orb colors to current class colors
	D32CharacterData.manaOrb.orbColor.r = Mr
	D32CharacterData.manaOrb.orbColor.g = Mg
	D32CharacterData.manaOrb.orbColor.b = Mb
	D32CharacterData.manaOrb.galaxy.r = Mr
	D32CharacterData.manaOrb.galaxy.g = Mg
	D32CharacterData.manaOrb.galaxy.b = Mb
	if D32CharacterData.manaOrb.font1.show == nil then D32CharacterData.manaOrb.font1.show = defaultsTable.manaOrb.font1.show end
	if D32CharacterData.manaOrb.font2.show == nil then D32CharacterData.manaOrb.font2.show = defaultsTable.manaOrb.font2.show end
	if not D32CharacterData.druidColors then D32CharacterData.druidColors = defaultsTable.druidColors end
	if not D32CharacterData.combat then D32CharacterData.combat = defaultsTable.combat end
	if not D32CharacterData.combat.galaxy then D32CharacterData.combat.galaxy = defaultsTable.combat.galaxy end
	if not D32CharacterData.values then D32CharacterData.values = defaultsTable.values  end
	if not D32CharacterData.artwork then D32CharacterData.artwork = defaultsTable.artwork end
	if not D32CharacterData.font then D32CharacterData.font = defaultsTable.font end
	if not D32CharacterData.petOrb then D32CharacterData.petOrb = defaultsTable.petOrb end
	if not D32CharacterData.petOrb.scale then D32CharacterData.petOrb.scale = defaultsTable.petOrb.scale end
	if not D32CharacterData.powerFrame then D32CharacterData.powerFrame = defaultsTable.powerFrame end
	if not D32CharacterData.defaultPlayerFrame then D32CharacterData.defaultPlayerFrame = defaultsTable.defaultPlayerFrame end
	
	
	TruncatedValuesCheckButton:SetChecked(D32CharacterData.values.formatted)
	UsePetOrbCheckButton:SetChecked(D32CharacterData.petOrb.enabled)
	TrackCombatCheckButton:SetChecked(D32CharacterData.combat.enabled)
	ShowPetOrbPercentagesCheckButton:SetChecked(D32CharacterData.petOrb.showPercentage)
	ShowPetOrbValuesCheckButton:SetChecked(D32CharacterData.petOrb.showValue)
	ShowMainOrbsPercentagesCheckButton:SetChecked(D32CharacterData.healthOrb.font1.show)
	ShowMainOrbsValuesCheckButton:SetChecked(D32CharacterData.healthOrb.font2.show)
	UsePowerTrackerCheckButton:SetChecked(D32CharacterData.powerFrame.show)
		
	if not D32CharacterData.petOrb.showValue then
		petOrb.font3:Hide()
		petOrb.font4:Hide()
	end
	if not D32CharacterData.petOrb.showPercentage then
		petOrb.font1:Hide()
		petOrb.font2:Hide()
	end
	checkPetFontPlacement()
	
	if not D32CharacterData.petOrb.enabled then
	 UnregisterUnitWatch(petOrb) 
	 petOrb:Hide()
	end
	if not D32CharacterData.artwork.show then
		angelFrame:Hide()
		demonFrame:Hide()
	end
	
	if powerFrame then
		if not D32CharacterData.powerFrame.show then
			powerFrame:SetScript("OnUpdate",nil)
			powerFrame:Hide()
		end
	end
end

function updateColorsFromMemory()
	--health orb fill, galaxy and font colors
	local r,g,b,a = D32CharacterData.healthOrb.orbColor.r,D32CharacterData.healthOrb.orbColor.g,D32CharacterData.healthOrb.orbColor.b,D32CharacterData.healthOrb.orbColor.a 
	healthOrb.filling:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.galaxy.r,D32CharacterData.healthOrb.galaxy.g,D32CharacterData.healthOrb.galaxy.b,D32CharacterData.healthOrb.galaxy.a
	healthOrb.galaxy1.texture:SetVertexColor(r,g,b,a)
	healthOrb.galaxy2.texture:SetVertexColor(r,g,b,a)
	healthOrb.galaxy3.texture:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.font1.r,D32CharacterData.healthOrb.font1.g,D32CharacterData.healthOrb.font1.b,D32CharacterData.healthOrb.font1.a
	healthOrb.font1:SetTextColor(r,g,b,a)
	r,g,b,a = D32CharacterData.healthOrb.font2.r,D32CharacterData.healthOrb.font2.g,D32CharacterData.healthOrb.font2.b,D32CharacterData.healthOrb.font2.a
	healthOrb.font2:SetTextColor(r,g,b,a)
	healthOrb:SetScale(D32CharacterData.healthOrb.scale)

	--mana orb fill, galaxy and font colors
	r,g,b,a = D32CharacterData.manaOrb.orbColor.r,D32CharacterData.manaOrb.orbColor.g,D32CharacterData.manaOrb.orbColor.b,D32CharacterData.manaOrb.orbColor.a
	manaOrb.filling:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.galaxy.r,D32CharacterData.manaOrb.galaxy.g,D32CharacterData.manaOrb.galaxy.b,D32CharacterData.manaOrb.galaxy.a
	manaOrb.galaxy1.texture:SetVertexColor(r,g,b,a)
	manaOrb.galaxy2.texture:SetVertexColor(r,g,b,a)
	manaOrb.galaxy3.texture:SetVertexColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.font1.r,D32CharacterData.manaOrb.font1.g,D32CharacterData.manaOrb.font1.b,D32CharacterData.manaOrb.font1.a
	manaOrb.font1:SetTextColor(r,g,b,a)
	r,g,b,a = D32CharacterData.manaOrb.font2.r,D32CharacterData.manaOrb.font2.g,D32CharacterData.manaOrb.font2.b,D32CharacterData.manaOrb.font2.a
	manaOrb.font2:SetTextColor(r,g,b,a)
	manaOrb:SetScale(D32CharacterData.manaOrb.scale)
	
	-- Make pet orb red brighter than player orb (multiply RGB by 1.2)
	local r, g, b, a = healthOrb.filling:GetVertexColor()
	petOrb.filling1:SetVertexColor(math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, b * 1.2), a)
	-- No need to update power color since we only show health
	petOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	petOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	petOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	petOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())
	
	D32ScaleSlider:SetValue((D32CharacterData.healthOrb.scale) * 100)

	setOrbFontPlacement(healthOrb,D32CharacterData.healthOrb)
	setOrbFontPlacement(manaOrb,D32CharacterData.manaOrb)
end

function D32UpdateOrbColor(orb,orbColor,galaxyColor,font1Color,font2Color)
	orb.filling:SetVertexColor(orbColor.r,orbColor.g,orbColor.b,orbColor.a)
	orb.galaxy1.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.galaxy2.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.galaxy3.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	orb.font1:SetTextColor(font1Color.r,font1Color.g,font1Color.b,font1Color.a)
	orb.font2:SetTextColor(font2Color.r,font2Color.g,font2Color.b,font2Color.a)
end 

local function TryNewColors(restore)
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()

	if restore then
		r,g,b,a = unpack(restore)
	end

	if ColorPickerFrame.elementToChange == "Filling" then
		xmlOrbDisplayFrame2.orb.filling:SetVertexColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Swirl" then
		xmlOrbDisplayFrame2.orb.galaxy1.texture:SetVertexColor(r,g,b,a)
		xmlOrbDisplayFrame2.orb.galaxy2.texture:SetVertexColor(r,g,b,a)
		xmlOrbDisplayFrame2.orb.galaxy3.texture:SetVertexColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Font1" then
		xmlOrbDisplayFrame2.orb.font1:SetTextColor(r,g,b,a)
	elseif ColorPickerFrame.elementToChange == "Font2" then
		xmlOrbDisplayFrame2.orb.font2:SetTextColor(r,g,b,a) 
	end
end

function TryNewTextures(fillTexture,swirlTexture)
	xmlOrbDisplayFrame2.orb.filling:SetTexture(fillTexture)
	if swirlTexture then
		xmlOrbDisplayFrame2.orb.galaxy1.texture:SetTexture(swirlTexture.."1.tga")
		xmlOrbDisplayFrame2.orb.galaxy2.texture:SetTexture(swirlTexture.."2.tga")
		xmlOrbDisplayFrame2.orb.galaxy3.texture:SetTexture(swirlTexture.."3.tga")
	end
end

local function checkShapeShiftInfo()
		local form = GetShapeshiftForm()
		local druidFormTable = D32CharacterData.manaOrb
		local changeOcurred = true
		if form == 1 then
			druidFormTable = D32CharacterData.druidColors.bear
			previousPowerValue = UnitPower("player","RAGE")
		elseif form == 3 then
			druidFormTable = D32CharacterData.druidColors.cat
			previousPowerValue = UnitPower("player","ENERGY")
		elseif form == 5 then
			changeOcurred = false
		elseif form == 0 then
			druidFormTable = D32CharacterData.manaOrb
			previousPowerValue = UnitPower("player","MANA")
		end
		D32UpdateOrbColor(manaOrb,druidFormTable.orbColor,druidFormTable.galaxy,druidFormTable.font1,druidFormTable.font2)
end

local function UpdateOrbTextures()
	healthOrb.filling:SetTexture(images..D32CharacterData.healthOrb.textures.fill)
	healthOrb.galaxy1.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."1.tga")
	healthOrb.galaxy2.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."2.tga")
	healthOrb.galaxy3.texture:SetTexture(images..D32CharacterData.healthOrb.textures.rotation.."3.tga")
	
	manaOrb.filling:SetTexture(images..D32CharacterData.manaOrb.textures.fill)
	manaOrb.galaxy1.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."1.tga")
	manaOrb.galaxy2.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."2.tga")
	manaOrb.galaxy3.texture:SetTexture(images..D32CharacterData.manaOrb.textures.rotation.."3.tga")
end

function D32ApplyChanges()
	local activeElement = CommitButton.activeElement
	local r,g,b,a = xmlOrbDisplayFrame2.orb.filling:GetVertexColor()
	local fillColors = {r=0,g=0,b=0,a=0}
	fillColors.r, fillColors.g, fillColors.b, fillColors.a = r,g,b,a
	activeElement.orbColor.r, activeElement.orbColor.g, activeElement.orbColor.b, activeElement.orbColor.a = r,g,b,a

	local galaxyColors = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.galaxy1.texture:GetVertexColor()
	galaxyColors.r, galaxyColors.g, galaxyColors.b, galaxyColors.a = r,g,b,a
	activeElement.galaxy.r, activeElement.galaxy.g, activeElement.galaxy.b, activeElement.galaxy.a = r,g,b,a
	
	local font1Color = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.font1:GetTextColor()
	font1Color.r,font1Color.g,font1Color.b,font1Color.a = r,g,b,a
	activeElement.font1.r, activeElement.font1.g, activeElement.font1.b, activeElement.font1.a = r,g,b,a
	
	local font2Color = {r=0,g=0,b=0,a=0}
	r,g,b,a = xmlOrbDisplayFrame2.orb.font2:GetTextColor()
	font2Color.r,font2Color.g,font2Color.b,font2Color.a = r,g,b,a
	activeElement.font2.r, activeElement.font2.g, activeElement.font2.b, activeElement.font2.a = r,g,b,a
		
	D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy,D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)
	
	local hPrefix = strmatch(xmlOrbDisplayFrame2.orb.filling:GetTexture(),"(MDO_orb_filling%d+)")
	CommitButton.textureElement.fill = hPrefix
	local mPrefix,mNum = strmatch(xmlOrbDisplayFrame2.orb.galaxy1.texture:GetTexture(),"(orb_rotation_%a+)(%d)")
	CommitButton.textureElement.rotation = mPrefix
	UpdateOrbTextures()

	if D32OrbPercentageCheckBox:GetChecked() then
		CommitButton.orbData.font1.show = true
	else
		CommitButton.orbData.font1.show = false
	end

	if D32OrbValueCheckBox:GetChecked() then
		CommitButton.orbData.font2.show = true
	else
		CommitButton.orbData.font2.show = false
	end

	setOrbFontPlacement(CommitButton.orb,CommitButton.orbData)
	
	
	if D32className == "Druid" then
		checkShapeShiftInfo()		
	else
		D32UpdateOrbColor(manaOrb,D32CharacterData.manaOrb.orbColor,D32CharacterData.manaOrb.galaxy,D32CharacterData.manaOrb.font1,D32CharacterData.manaOrb.font2)
	end
	
	--set pet fill colors to that of the fill colors of the health/mana orbs
	-- Make pet orb red brighter than player orb (multiply RGB by 1.2)
	local r, g, b, a = healthOrb.filling:GetVertexColor()
	petOrb.filling1:SetVertexColor(math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, b * 1.2), a)
	-- No need to update power color since we only show health
	petOrb.font1:SetTextColor(healthOrb.font1:GetTextColor())
	petOrb.font2:SetTextColor(manaOrb.font1:GetTextColor())
	petOrb.font3:SetTextColor(healthOrb.font2:GetTextColor())
	petOrb.font4:SetTextColor(manaOrb.font2:GetTextColor())
end

function D32ColorPicker(xmlElement)
	local r,g,b,a
	if xmlElement == "Filling" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.filling:GetVertexColor()
	elseif xmlElement == "Swirl" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.galaxy1.texture:GetVertexColor()
	elseif xmlElement == "Font1" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.font1:GetTextColor()
	elseif xmlElement == "Font2" then
		r,g,b,a = xmlOrbDisplayFrame2.orb.font2:GetTextColor()
	end
	
	ColorPickerFrame.elementToChange = xmlElement
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = TryNewColors,TryNewColors,TryNewColors
	ColorPickerFrame:SetColorRGB(r,g,b,a)
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
	ColorPickerFrame.previousValues = {r,g,b,a}
	makeFrameMovable(ColorPickerFrame,"RightButton")
	ColorPickerFrame:EnableKeyboard(false)
	ColorPickerFrame:Show()
end

function UpdateXMLTextures(orb)
	xmlOrbDisplayFrame2.orb.filling:SetTexture(orb.filling:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy1.texture:SetTexture(orb.galaxy1.texture:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy2.texture:SetTexture(orb.galaxy2.texture:GetTexture())
	xmlOrbDisplayFrame2.orb.galaxy3.texture:SetTexture(orb.galaxy3.texture:GetTexture())
	
	--we'll come back to this one later...
	--local num = table.getn(D32FillTextureChoices)
	--for i=0,num,1 do
	--	local fillPrefix = strmatch(D32FillTextureChoices[i],"(MDO_orb_filling%d+)")
	--	if tostring(CommitButton.textureElement.fill) == fillPrefix then	
			
	--	end
	--endd
	
	--num = table.getn(D32RotationTextureChoices)
	--for i=0,num,1 do
	--	local rotationPrefix = strmatch(D32RotationTextureChoices[i],"(orb_rotation_%a+)")
	--	if tostring(CommitButton.textureElement.rotation) == rotationPrefix then
			
	--	end
	--end
	
	UIDropDownMenu_SetText(FillTexturesDropDown,"Choose one...")
	UIDropDownMenu_SetText(RotationTexturesDropDown,"Choose one...")
end

function UpdateXMLColors(orbColor,galaxyColor,font1,font2)
	xmlOrbDisplayFrame2.orb.filling:SetVertexColor(orbColor.r,orbColor.g,orbColor.b,orbColor.a)
	xmlOrbDisplayFrame2.orb.galaxy1.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.galaxy2.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.galaxy3.texture:SetVertexColor(galaxyColor.r,galaxyColor.g,galaxyColor.b,galaxyColor.a)
	xmlOrbDisplayFrame2.orb.font1:SetTextColor(font1.r,font1.g,font1.b,font1.a)
	xmlOrbDisplayFrame2.orb.font2:SetTextColor(font2.r,font2.g,font2.b,font2.a)
end

function UpdateXMLText(orb)
	xmlOrbDisplayFrame2.orb.font1:SetText(orb.font1:GetText())
	xmlOrbDisplayFrame2.orb.font2:SetText(orb.font2:GetText())
end

function FillXMLTemplate(frame)
	frame.orb = CreateXMLOrb(xmlOrbDisplayFrame2,"D32_XMLOrb",150,defaultTextures.healthOrb.fill,defaultTextures.healthOrb.rotation)
	frame.orb.galaxy1.texture:SetAlpha(0.5)
	frame.orb.galaxy2.texture:SetAlpha(0.5)
	frame.orb.galaxy3.texture:SetAlpha(0.5)
	frame:SetScale(1.5)
end

--alloc the orbs and assign them to the health/mana orb variables, make them both movable from the get-go for testing
healthOrb = CreateOrb(nil,"D32_HealthOrb",defaultOrbSize,defaultTextures.healthOrb.fill,defaultTextures.healthOrb.rotation,-340,0,"BOTTOM",monitorHealth)
manaOrb = CreateOrb(nil,"D32_ManaOrb",defaultOrbSize,defaultTextures.manaOrb.fill,defaultTextures.manaOrb.rotation,340,0,"BOTTOM",monitorPower)
-- Pet orb positioned at bottom like main orbs: healthOrb is at -340, pet orb was at -95 relative to healthOrb center
-- So absolute X position is approximately -340 + (-95) = -435
petOrb = CreatePetOrb(nil,"D32_PetOrb",87,-465,0,"BOTTOM",nil)
-- Set initial pet orb power color based on pet's power type
if petOrb then
	UpdatePetOrbPowerColor(petOrb)
end
powerFrame = nil
if D32className == "Paladin" or D32className == "Warlock" or D32className == "Rogue" or D32className == "Druid" or D32className == "Monk" or D32className == "Priest" then powerFrame =  createPowerFrame(images.."d32_powerFrame.tga",manaOrb,"PowerFrame",95,50,50,50) end
if powerFrame then makeFrameMovable(powerFrame) end
angelFrame = addArtwork(images.."d3_angel3test.tga",manaOrb,"AngelFrame",-64,5,160,160)
demonFrame = addArtwork(images.."d3_demon3test.tga",healthOrb,"DemonFrame",44,5,160,160)
-- Hide angel and demon by default
angelFrame:Hide()
demonFrame:Hide()
makeFrameMovable(healthOrb)
makeFrameMovable(manaOrb)
makeFrameMovable(petOrb)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_PET")
if D32className == "Druid" then
	eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
end

local flagHide_PetFrame = false
function eventFrame:OnEvent(event,arg1)
	if event == "ADDON_LOADED" then
		-- Only initialize on our own ADDON_LOADED, not for other addons
		-- This prevents updateColorsFromMemory from running when orbs are hidden by other addons
		if arg1 == "MistrasDiabloOrbs" or arg1 == "DrakeishUI" then
		checkDefaultsFromMemory()
		-- Check Diablo orbs state - if orbs are inactive (or state not set), show player frame
		-- Default to showing player frame if state is not set (orbs inactive by default)
		local orbsActive = false
		if _G.diablo_orbs_state == 1 then
			orbsActive = true
		-- If state is not set (nil) or is 0, orbs are inactive, so show player frame
		-- Only check if orbs are shown if state is explicitly 1
		end
		-- Only hide player frame if orbs are active AND defaultPlayerFrame.show is false
		-- If orbs are inactive (state is 0 or nil), always show player frame
		if orbsActive and not D32CharacterData.defaultPlayerFrame.show then
			handlePlayerFrame(false)
		else
			-- Show player frame if orbs are inactive OR if defaultPlayerFrame.show is true
			handlePlayerFrame(true)
		end
			-- Only call updateColorsFromMemory if orbs are visible (or should be visible)
			-- This prevents fonts from being initialized while parent is hidden
			if healthOrb:IsShown() and manaOrb:IsShown() then
		updateColorsFromMemory()
		UpdateOrbTextures()
		D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy,D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)
		local colorTable
		if D32className == "Druid" then
			checkShapeShiftInfo()
		else
			D32UpdateOrbColor(manaOrb,D32CharacterData.manaOrb.orbColor,D32CharacterData.manaOrb.galaxy,D32CharacterData.manaOrb.font1,D32CharacterData.manaOrb.font2)
				end
		end
		D32GUI:Hide()
		end
		
		-- Initialize pet orb if pet already exists on login
		if petOrb and UnitExists("pet") then
			-- Reset previous values to trigger fill animation
			previousPetHealth = 0
			previousPetPower = 0
			-- Update pet orb power color
			UpdatePetOrbPowerColor(petOrb)
			-- Set update script if not already set
			if not petOrb:GetScript("OnUpdate") then
				petOrb:SetScript("OnUpdate", updatePetValues)
			end
		end
	elseif event == "VARIABLES_LOADED" then
		D32MiniMapButtonPosition_LoadFromDefaults()
	elseif event == "UNIT_ENTERED_VEHICLE" then
		if arg1 == "player" then
			vehicleInUse = 1
			previousPowerValue = 0
			previousHealthValue = 0
		end
	elseif event == "UNIT_EXITED_VEHICLE" then
		if arg1 == "player" then
			vehicleInUse = 0
			previousHealthValue = 0
			previousPowerValue = 0
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		if D32CharacterData.combat.enabled then
			D32UpdateOrbColor(healthOrb,D32CharacterData.combat.orbColor,D32CharacterData.combat.galaxy,D32CharacterData.combat.font1,D32CharacterData.combat.font2)
			-- Make pet orb red brighter in combat (multiply RGB by 1.2)
			local r, g, b, a = D32CharacterData.combat.orbColor.r, D32CharacterData.combat.orbColor.g, D32CharacterData.combat.orbColor.b, D32CharacterData.combat.orbColor.a
			petOrb.filling1:SetVertexColor(math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, b * 1.2), a)
		-- Update pet orb power color based on pet's power type
		UpdatePetOrbPowerColor(petOrb)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if D32CharacterData.combat.enabled then
			D32UpdateOrbColor(healthOrb,D32CharacterData.healthOrb.orbColor,D32CharacterData.healthOrb.galaxy, D32CharacterData.healthOrb.font1,D32CharacterData.healthOrb.font2)
			-- Make pet orb red brighter (multiply RGB by 1.2)
			local r, g, b, a = D32CharacterData.healthOrb.orbColor.r, D32CharacterData.healthOrb.orbColor.g, D32CharacterData.healthOrb.orbColor.b, D32CharacterData.healthOrb.orbColor.a
			petOrb.filling1:SetVertexColor(math.min(1, r * 1.2), math.min(1, g * 1.2), math.min(1, b * 1.2), a)
		end
	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		checkShapeShiftInfo()
	elseif event == "UNIT_PET" then
		local name,realm = UnitName("pet")
		if not name then
			petOrb:SetScript("OnUpdate",nil)
		else
			petOrb:SetScript("OnUpdate",updatePetValues)
			-- Initialize previous values to 0 to trigger fill animation on login
			previousPetHealth = 0
			previousPetPower = 0
			-- Update pet orb power color when pet appears/changes
			if petOrb then
				UpdatePetOrbPowerColor(petOrb)
			end
		end
	end
end

eventFrame:SetScript("OnEvent",eventFrame.OnEvent)

--slash command method	
local function CommandFunc(cmd)
	if cmd == "disable" then
		healthOrb:SetScript("OnUpdate",nil)
		manaOrb:SetScript("OnUpdate",nil)
		healthOrb:Hide()
		manaOrb:Hide()
	elseif cmd == "enable" then
		healthOrb:SetScript("OnUpdate",monitorHealth)
		manaOrb:SetScript("OnUpdate",monitorPower)
		healthOrb:Show()
		manaOrb:Show()
	elseif cmd == "help" then
		
	else
		Handle_D32GUI()
	end
end

--setup the slash command stuff, hide the GUI
SlashCmdList["MDO"] = CommandFunc;
SLASH_MDO1 = "/mdo";
