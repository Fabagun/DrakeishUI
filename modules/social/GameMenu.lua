-- Game Menu (MainMenuMicroButton / ESC). Stock GameMenuFrame is a classic
-- UI-DialogBox. Retexture it with the same rock body and metal frame the other
-- windows use. No portrait: this is a short button list. Buttons stay put.

local NE = DrakeishUI_SocialNE
local PC = NE.panelchrome

local function hideStockChrome(f)
  if f.SetBackdrop then f:SetBackdrop(nil) end
  if GameMenuFrameHeader and GameMenuFrameHeader.Hide then
    GameMenuFrameHeader:Hide()
    if not GameMenuFrameHeader._neGameMenuLocked then
      GameMenuFrameHeader._neGameMenuLocked = true
      GameMenuFrameHeader.Show = function() end
    end
  end
  local regions = { f:GetRegions() }
  for i = 1, #regions do
    local r = regions[i]
    if r and r.IsObjectType and r:IsObjectType("FontString") and r ~= f.Title and r ~= f._neTitle then
      r:Hide()
    end
  end
end

-- The metal nineslice sits one level above the frame, which would paint over the
-- button ends. Keep every menu button above that chrome.
local function raiseButtons(f)
  local level = ((f.NineSlice and f.NineSlice.GetFrameLevel and f.NineSlice:GetFrameLevel()) or f:GetFrameLevel() or 1) + 5
  local kids = { f:GetChildren() }
  for i = 1, #kids do
    local c = kids[i]
    if c and c ~= f.NineSlice and c ~= f._neTitleBand and c.IsObjectType and c:IsObjectType("Button") then
      c:SetFrameLevel(level)
    end
  end
end

-- The metal cap's solid bar runs from just under the frame top to about 24px down.
-- The title font was anchored under the band as well as the band itself, so the
-- line sat on the lower lip and hung out of the bar. Pin it to the bar's center.
local function centerTitle(f)
  local fs = f._neTitle or f.Title
  if not fs then return end
  fs:ClearAllPoints()
  fs:SetPoint("TOP", f, "TOP", 0, -5)
  fs:SetJustifyH("CENTER")
end

-- Same stack as the PvP window: light grey rock inside the metal outer frame,
-- then a thin inner border with the darker fill inside it. The rock margin
-- between those two borders is 5px on the sides and bottom.
local WELL_L, WELL_R, WELL_T, WELL_B = 15, 10, 26, 11

local function fitBackground(f)
  if f.Bg then
    f.Bg:SetVertexColor(1, 1, 1)
    f.Bg:SetDrawLayer("BACKGROUND")
    f.Bg:ClearAllPoints()
    -- Meet the left metal stroke. 2px sat outside it; 10px left a gap inside it.
    f.Bg:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -20)
    f.Bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  end

  local well = f._neGameMenuWell
  if not well then
    well = CreateFrame("Frame", nil, f)
    well:EnableMouse(false)
    local bg = well:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.06, 0.06, 0.07, 0.75)
    bg:SetAllPoints(well)
    well.Bg = bg
    if NE.nineslice and NE.nineslice.AttachInset then
      well.InsetBorder = NE.nineslice.AttachInset(well, 0, 0, 0, 0)
    end
    f._neGameMenuWell = well
  end
  well:ClearAllPoints()
  well:SetPoint("TOPLEFT", f, "TOPLEFT", WELL_L, -WELL_T)
  well:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -WELL_R, WELL_B)
  local base = f:GetFrameLevel() or 1
  well:SetFrameLevel(base + 2)
  if well.InsetBorder then well.InsetBorder:SetFrameLevel(base + 3) end
  well:Show()
end

-- Keep the stock stack and its original vertical offset. Only slide the column
-- sideways onto the dark well, which is inset more on the left than the right.
local function centerButtons(f)
  local btn = _G.GameMenuButtonOptions
  if not btn then return end
  if not btn._neMenuAnchored then
    local point, _, relPoint, _, y = btn:GetPoint(1)
    btn._neMenuPoint = point or "CENTER"
    btn._neMenuRelPoint = relPoint or "TOP"
    btn._neMenuY = y or -37
    btn._neMenuAnchored = true
  end
  btn:ClearAllPoints()
  btn:SetPoint(btn._neMenuPoint, f, btn._neMenuRelPoint, (WELL_L - WELL_R) / 2, btn._neMenuY)
end

local function skinGameMenu()
  local f = GameMenuFrame
  if not f or not PC or not PC.Apply then return end
  hideStockChrome(f)
  if not f._neGameMenuSkinned then
    PC.Apply(f, {
      layout = "ButtonFrameTemplateNoPortrait",
      noPortrait = true,
      noCloseButton = true,
      title = MAIN_MENU,
    })
    centerTitle(f)
    fitBackground(f)
    f._neGameMenuSkinned = true
  end
  centerButtons(f)
  raiseButtons(f)
end

if GameMenuFrame then
  GameMenuFrame:HookScript("OnShow", skinGameMenu)
  if GameMenuFrame:IsShown() then skinGameMenu() end
end
