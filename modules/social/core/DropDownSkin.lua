-- DrakeishUI_SocialNE/core/DropDownSkin.lua — Character Skills/Reputation filter chrome.
--
-- Reference: CP.CreateFilterDropdown (characterpanel/listpane.lua):
--   * full-size hit target
--   * selection text + ChatFrameExpandArrow as a CreateTexture OVERLAY (NOT SetNormalTexture)
--   * displayMode "MENU" so DropDownList uses tooltip MenuBackdrop
--
-- Using SetNormalTexture/SetPushedTexture on UIDropDownMenuTemplate's Button is what made the
-- triangle jump on first click: the stock button offsets its NormalTexture when pushed, and the
-- XML PushedTexture (ScrollDown-Down) is a different glyph.

local NE = DrakeishUI_SocialNE
if not NE then return end

NE.dropdown = NE.dropdown or {}

local ARROW = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local ARROW_SIZE = 10

local function clearStockButtonArt(btn, ddName)
  if not btn then return end
  -- Named XML textures on UIDropDownMenuTemplate ($parentButtonNormalTexture, …).
  if ddName then
    for _, suffix in ipairs({ "NormalTexture", "PushedTexture", "DisabledTexture", "HighlightTexture" }) do
      local t = _G[ddName .. "Button" .. suffix]
      if t then
        t:SetTexture("")
        t:Hide()
        t:SetAlpha(0)
        if t.SetSize then t:SetSize(1, 1) end
      end
    end
  end
  -- Also clear via API so a later SetNormalTexture("") from Blizzard stays empty.
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if btn.SetPushedTexture then btn:SetPushedTexture("") end
  if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
  -- Kill the default push-offset that slides button art down on MouseDown.
  if btn.SetPushedTextOffset then btn:SetPushedTextOffset(0, 0) end
end

local function placeArrowPair(arrow, hl, text, btn)
  if arrow then
    arrow:SetTexture(ARROW)
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:ClearAllPoints()
    if text then
      arrow:SetPoint("LEFT", text, "RIGHT", 2, 0)
    else
      arrow:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    end
    arrow:Show()
  end
  if hl then
    hl:SetTexture(ARROW)
    hl:SetSize(ARROW_SIZE, ARROW_SIZE)
    hl:ClearAllPoints()
    if text then
      hl:SetPoint("LEFT", text, "RIGHT", 2, 0)
    else
      hl:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    end
    hl:SetBlendMode("ADD")
    hl:SetAlpha(0.35)
  end
end

-- Attach the Character-style expand arrow to any Button (Friends Available, Who field, …).
-- opts.relativeTo — region the arrow sits to the right of (default: first FontString / .label).
function NE.dropdown.AttachArrow(btn, opts)
  if not btn then return end
  opts = opts or {}
  local rel = opts.relativeTo or btn.label or btn.Label
  if not rel and btn.GetRegions then
    -- Prefer an existing FontString on the button.
    local regions = { btn:GetRegions() }
    for i = 1, #regions do
      local r = regions[i]
      if r and r.GetObjectType and r:GetObjectType() == "FontString" then
        rel = r
        break
      end
    end
  end

  if not btn._neFilterArrow then
    btn._neFilterArrow = btn:CreateTexture(nil, "OVERLAY")
    btn._neFilterArrowHL = btn:CreateTexture(nil, "HIGHLIGHT")
  end
  placeArrowPair(btn._neFilterArrow, btn._neFilterArrowHL, rel, btn)
  return btn._neFilterArrow
end

-- opts.width / opts.textWidth — defaults match Friends (~110 / 90).
function NE.dropdown.SkinFilter(dd, opts)
  if not dd then return end
  opts = opts or {}
  local width = opts.width or 110
  local textWidth = opts.textWidth or math.max(40, width - ARROW_SIZE - 10)
  dd._neFilterOpts = opts

  -- Always refresh MENU mode (Blizzard may re-init without it).
  dd.displayMode = "MENU"

  local name = dd.GetName and dd:GetName()
  if name and not dd._neFilterParchmentBuried then
    dd._neFilterParchmentBuried = true
    for _, piece in ipairs({ "Left", "Middle", "Right" }) do
      local t = _G[name .. piece]
      if t and t.Hide then
        t:Hide()
        t.Show = t.Hide
      end
    end
  end

  dd:SetSize(width, 20)
  dd:EnableMouse(false) -- clicks go to the full-size Button child

  local btn = (name and _G[name .. "Button"]) or dd.Button
  local text = (name and _G[name .. "Text"]) or dd.Text or dd.text

  if text then
    text:ClearAllPoints()
    text:SetFontObject(GameFontHighlightSmall)
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", dd, "LEFT", 4, 0)
    text:SetWidth(textWidth)
    if text.SetDrawLayer then text:SetDrawLayer("OVERLAY", 1) end
  end

  if btn then
    btn:ClearAllPoints()
    btn:SetAllPoints(dd)
    if btn.SetHitRectInsets then btn:SetHitRectInsets(0, 0, 0, 0) end
    if btn.SetFrameLevel and dd.GetFrameLevel then
      btn:SetFrameLevel((dd:GetFrameLevel() or 1) + 2)
    end

    clearStockButtonArt(btn, name)

    -- Stable OVERLAY arrow — same construction as CP.CreateFilterDropdown (no push jump).
    if not btn._neFilterArrow then
      btn._neFilterArrow = btn:CreateTexture(nil, "OVERLAY")
      btn._neFilterArrowHL = btn:CreateTexture(nil, "HIGHLIGHT")
    end
    placeArrowPair(btn._neFilterArrow, btn._neFilterArrowHL, text, btn)

    if not btn._neFilterClickHooked then
      btn._neFilterClickHooked = true
      -- Blizzard may restore ScrollDown art on open; re-assert ours after each press.
      btn:HookScript("OnMouseUp", function()
        clearStockButtonArt(btn, name)
        placeArrowPair(btn._neFilterArrow, btn._neFilterArrowHL, text, btn)
      end)
      btn:HookScript("OnClick", function()
        clearStockButtonArt(btn, name)
        placeArrowPair(btn._neFilterArrow, btn._neFilterArrowHL, text, btn)
      end)
    end
  end

  local mo = name and _G[name .. "MouseOver"]
  if mo then
    mo:Hide()
    if mo.Show then mo.Show = mo.Hide end
  end
end

-- Re-apply after UIDropDownMenu_Initialize / SetWidth (those re-anchor the stock button).
if not NE.dropdown._initHooked and hooksecurefunc then
  NE.dropdown._initHooked = true
  hooksecurefunc("UIDropDownMenu_Initialize", function(frame)
    if frame and frame._neFilterOpts then
      NE.dropdown.SkinFilter(frame, frame._neFilterOpts)
    end
  end)
  if UIDropDownMenu_SetWidth then
    hooksecurefunc("UIDropDownMenu_SetWidth", function(frame)
      if frame and frame._neFilterOpts then
        NE.dropdown.SkinFilter(frame, frame._neFilterOpts)
      end
    end)
  end
end
